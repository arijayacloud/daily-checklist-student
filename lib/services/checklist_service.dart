import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_checklist_student/models/models.dart';
import 'package:uuid/uuid.dart';

class ChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'checklist_items';
  final String _logsCollectionName = 'completion_logs';
  final Uuid _uuid = Uuid();

  // Mendapatkan semua checklist item untuk seorang anak
  Stream<List<ChecklistItemModel>> getChildChecklistItems(String childId) {
    return _firestore
        .collection(_collectionName)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChecklistItemModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Mendapatkan checklist item dengan filter (pending, partial, complete)
  Stream<List<ChecklistItemModel>> getFilteredChildChecklistItems(
    String childId,
    String status,
  ) {
    return _firestore
        .collection(_collectionName)
        .where('childId', isEqualTo: childId)
        .where('overallStatus', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChecklistItemModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Membuat checklist item baru
  Future<ChecklistItemModel> createChecklistItem({
    required String childId,
    required String activityId,
    required DateTime dueDate,
  }) async {
    final String id = _uuid.v4();
    final ChecklistItemModel checklistItem = ChecklistItemModel(
      id: id,
      childId: childId,
      activityId: activityId,
      assignedDate: DateTime.now(),
      dueDate: dueDate,
      homeStatus: CompletionStatus(),
      schoolStatus: CompletionStatus(),
      overallStatus: 'pending',
    );

    await _firestore
        .collection(_collectionName)
        .doc(id)
        .set(checklistItem.toMap());

    return checklistItem;
  }

  // Memperbarui status aktivitas (home atau school)
  Future<void> updateCompletionStatus({
    required String checklistItemId,
    required String environment,
    required String userId,
    String? notes,
    String? photoUrl,
  }) async {
    // 1. Mendapatkan dokumen checklist item
    final docSnapshot =
        await _firestore.collection(_collectionName).doc(checklistItemId).get();

    if (!docSnapshot.exists) {
      throw Exception('Checklist item not found');
    }

    final checklistItem = ChecklistItemModel.fromMap(docSnapshot.data()!);

    // 2. Dapatkan activity untuk mendapatkan environment yang diizinkan
    final activitySnapshot =
        await _firestore
            .collection('activities')
            .doc(checklistItem.activityId)
            .get();

    if (!activitySnapshot.exists) {
      throw Exception('Activity not found');
    }

    final activity = ActivityModel.fromMap(activitySnapshot.data()!);

    // 3. Verifikasi apakah environment diizinkan untuk aktivitas ini
    if (activity.environment != 'both' && activity.environment != environment) {
      throw Exception('This activity cannot be completed in this environment');
    }

    // 4. Buat status completion baru
    final CompletionStatus newStatus = CompletionStatus(
      completed: true,
      completedAt: DateTime.now(),
      notes: notes,
      completedBy: userId,
      photoUrl: photoUrl,
    );

    // 5. Update status sesuai environment
    final Map<String, dynamic> updateData = {};
    if (environment == 'home') {
      updateData['homeStatus'] = newStatus.toMap();
    } else {
      updateData['schoolStatus'] = newStatus.toMap();
    }

    // 6. Hitung overall status baru
    final String newOverallStatus = ChecklistItemModel.calculateOverallStatus(
      environment == 'home' ? newStatus : checklistItem.homeStatus,
      environment == 'school' ? newStatus : checklistItem.schoolStatus,
      activity.environment,
    );
    updateData['overallStatus'] = newOverallStatus;

    // 7. Update checklist item
    await _firestore
        .collection(_collectionName)
        .doc(checklistItemId)
        .update(updateData);

    // 8. Tambahkan log completion
    final String logId = _uuid.v4();
    final CompletionLogModel log = CompletionLogModel(
      id: logId,
      checklistItemId: checklistItemId,
      environment: environment,
      completedBy: userId,
      timestamp: DateTime.now(),
      notes: notes,
      photoUrl: photoUrl,
    );

    await _firestore
        .collection(_logsCollectionName)
        .doc(logId)
        .set(log.toMap());
  }

  // Mendapatkan detail checklist item tertentu
  Future<ChecklistItemModel> getChecklistItem(String id) async {
    final docSnapshot =
        await _firestore.collection(_collectionName).doc(id).get();

    if (!docSnapshot.exists) {
      throw Exception('Checklist item not found');
    }

    return ChecklistItemModel.fromMap(docSnapshot.data()!);
  }

  // Mendapatkan semua log untuk checklist item tertentu
  Stream<List<CompletionLogModel>> getChecklistItemLogs(
    String checklistItemId,
  ) {
    return _firestore
        .collection(_logsCollectionName)
        .where('checklistItemId', isEqualTo: checklistItemId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => CompletionLogModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Mendapatkan semua checklist item untuk guru dengan filter anak
  Stream<List<ChecklistItemModel>> getTeacherChecklistItems(
    List<String> childrenIds,
  ) {
    if (childrenIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('childId', whereIn: childrenIds)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChecklistItemModel.fromMap(doc.data()))
                  .toList(),
        );
  }
}
