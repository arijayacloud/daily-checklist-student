import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_model.dart';

class PlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plans';

  // Dapatkan semua rencana untuk guru tertentu
  Stream<List<PlanModel>> getTeacherPlans(String teacherId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: teacherId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return PlanModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan semua rencana untuk anak tertentu
  Stream<List<PlanModel>> getChildPlans(String childId) {
    return _firestore
        .collection(_collection)
        .where('childId', isEqualTo: childId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return PlanModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan rencana berdasarkan rentang tanggal
  Stream<List<PlanModel>> getPlansByDateRange(
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Konversi ke Timestamp untuk perbandingan yang akurat
    Timestamp startTimestamp = Timestamp.fromDate(startDate);
    Timestamp endTimestamp = Timestamp.fromDate(endDate);

    return _firestore
        .collection(_collection)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data();
                data['id'] = doc.id;
                return PlanModel.fromMap(data);
              })
              .where((plan) {
                // Filter berdasarkan rentang tanggal
                // Plan dimulai dalam rentang atau berakhir dalam rentang
                DateTime planStartDate = plan.startDate;
                DateTime planEndDate = plan.endDate;

                return (planStartDate.isAfter(startDate) ||
                            planStartDate.isAtSameMomentAs(startDate)) &&
                        (planStartDate.isBefore(endDate) ||
                            planStartDate.isAtSameMomentAs(endDate)) ||
                    (planEndDate.isAfter(startDate) ||
                            planEndDate.isAtSameMomentAs(startDate)) &&
                        (planEndDate.isBefore(endDate) ||
                            planEndDate.isAtSameMomentAs(endDate));
              })
              .toList();
        });
  }

  // Dapatkan semua template rencana
  Stream<List<PlanModel>> getPlanTemplates(String teacherId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: teacherId)
        .where('isTemplate', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return PlanModel.fromMap(data);
          }).toList();
        });
  }

  // Buat rencana baru
  Future<String> createPlan(PlanModel plan) async {
    try {
      Map<String, dynamic> data = plan.toMap();
      data.remove('id');

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      print('Error creating plan: $e');
      rethrow;
    }
  }

  // Buat rencana dari template
  Future<String> createPlanFromTemplate(
    String templateId,
    String childId,
    DateTime startDate,
  ) async {
    try {
      // Dapatkan template
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(templateId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Buat rencana baru dari template
        PlanModel template = PlanModel.fromMap(data);

        // Hitung durasi template untuk menentukan endDate
        int durationDays =
            template.endDate.difference(template.startDate).inDays;

        // Buat rencana baru
        PlanModel newPlan = PlanModel(
          id: const Uuid().v4(),
          title: template.title,
          description: template.description,
          childId: childId,
          createdBy: template.createdBy,
          createdAt: DateTime.now(),
          planType: template.planType,
          startDate: startDate,
          endDate: startDate.add(Duration(days: durationDays)),
          recurrence: template.recurrence,
          recurrenceDays: template.recurrenceDays,
          activities: template.activities,
          notificationsEnabled: template.notificationsEnabled,
          isTemplate: false,
        );

        // Simpan rencana baru
        return await createPlan(newPlan);
      }

      throw Exception('Template tidak ditemukan');
    } catch (e) {
      print('Error creating plan from template: $e');
      rethrow;
    }
  }

  // Update rencana
  Future<void> updatePlan(PlanModel plan) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(plan.id)
          .update(plan.toMap());
    } catch (e) {
      print('Error updating plan: $e');
      rethrow;
    }
  }

  // Perbarui aktivitas dalam rencana
  Future<void> updatePlanActivity(
    String planId,
    String activityId,
    PlanActivityModel updatedActivity,
  ) async {
    try {
      // Dapatkan rencana
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(planId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = planId;

        // Parse rencana
        PlanModel plan = PlanModel.fromMap(data);

        // Temukan aktivitas yang akan diupdate
        int activityIndex = plan.activities.indexWhere(
          (activity) => activity.activityId == activityId,
        );

        if (activityIndex >= 0) {
          // Buat daftar aktivitas baru
          List<PlanActivityModel> updatedActivities = List.from(
            plan.activities,
          );
          updatedActivities[activityIndex] = updatedActivity;

          // Update rencana
          PlanModel updatedPlan = plan.copyWith(activities: updatedActivities);

          await updatePlan(updatedPlan);
        }
      }
    } catch (e) {
      print('Error updating plan activity: $e');
      rethrow;
    }
  }

  // Tandai aktivitas sebagai selesai
  Future<void> markActivityAsCompleted(String planId, String activityId) async {
    try {
      // Dapatkan rencana
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(planId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = planId;

        // Parse rencana
        PlanModel plan = PlanModel.fromMap(data);

        // Temukan aktivitas yang akan ditandai selesai
        int activityIndex = plan.activities.indexWhere(
          (activity) => activity.activityId == activityId,
        );

        if (activityIndex >= 0) {
          // Dapatkan aktivitas saat ini
          PlanActivityModel currentActivity = plan.activities[activityIndex];

          // Buat aktivitas yang diupdate
          PlanActivityModel completedActivity = currentActivity.copyWith(
            completed: true,
            completedAt: DateTime.now(),
          );

          // Update aktivitas dalam rencana
          await updatePlanActivity(planId, activityId, completedActivity);
        }
      }
    } catch (e) {
      print('Error marking activity as completed: $e');
      rethrow;
    }
  }

  // Hapus rencana
  Future<void> deletePlan(String planId) async {
    try {
      await _firestore.collection(_collection).doc(planId).delete();
    } catch (e) {
      print('Error deleting plan: $e');
      rethrow;
    }
  }

  // Toggle notifikasi untuk rencana
  Future<void> togglePlanNotifications(String planId, bool enabled) async {
    try {
      await _firestore.collection(_collection).doc(planId).update({
        'notificationsEnabled': enabled,
      });
    } catch (e) {
      print('Error toggling plan notifications: $e');
      rethrow;
    }
  }
}
