import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

class PlanProvider with ChangeNotifier {
  final PlanService _planService = PlanService();

  List<PlanModel> _plans = [];
  List<PlanModel> _templates = [];
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _selectedDate;
  String _filterPlanType = '';

  // Getters
  List<PlanModel> get plans => _filterPlans();
  List<PlanModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  DateTime? get selectedDate => _selectedDate;
  String get filterPlanType => _filterPlanType;

  // Stream subscription untuk plans
  StreamSubscription<List<PlanModel>>? _teacherPlansSubscription;
  StreamSubscription<List<PlanModel>>? _childPlansSubscription;
  StreamSubscription<List<PlanModel>>? _dateRangePlansSubscription;
  StreamSubscription<List<PlanModel>>? _templatesSubscription;

  // Load rencana untuk guru tertentu
  void loadTeacherPlans(String teacherId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _teacherPlansSubscription?.cancel();

    // Subscribe ke stream plans
    _teacherPlansSubscription = _planService
        .getTeacherPlans(teacherId)
        .listen(
          (plans) {
            _plans = plans;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat rencana guru: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Load rencana untuk anak tertentu
  void loadChildPlans(String childId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _childPlansSubscription?.cancel();

    // Subscribe ke stream plans
    _childPlansSubscription = _planService
        .getChildPlans(childId)
        .listen(
          (plans) {
            _plans = plans;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat rencana anak: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Load rencana berdasarkan rentang tanggal
  void loadPlansByDateRange(
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _dateRangePlansSubscription?.cancel();

    // Subscribe ke stream plans berdasarkan rentang tanggal
    _dateRangePlansSubscription = _planService
        .getPlansByDateRange(childId, startDate, endDate)
        .listen(
          (plans) {
            _plans = plans;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat rencana berdasarkan tanggal: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Load template rencana
  void loadPlanTemplates(String teacherId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _templatesSubscription?.cancel();

    // Subscribe ke stream templates
    _templatesSubscription = _planService
        .getPlanTemplates(teacherId)
        .listen(
          (templates) {
            _templates = templates;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat template rencana: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Filter rencana
  List<PlanModel> _filterPlans() {
    List<PlanModel> filteredList = _plans;

    // Filter berdasarkan tipe rencana
    if (_filterPlanType.isNotEmpty) {
      filteredList =
          filteredList
              .where((plan) => plan.planType == _filterPlanType)
              .toList();
    }

    // Filter berdasarkan tanggal yang dipilih
    if (_selectedDate != null) {
      filteredList =
          filteredList.where((plan) {
            // Rencana berlaku jika tanggal yang dipilih berada di antara tanggal mulai dan selesai
            return (_selectedDate!.isAfter(plan.startDate) ||
                    _selectedDate!.isAtSameMomentAs(plan.startDate)) &&
                (_selectedDate!.isBefore(plan.endDate) ||
                    _selectedDate!.isAtSameMomentAs(plan.endDate));
          }).toList();
    }

    return filteredList;
  }

  // Set tanggal yang dipilih
  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Set filter tipe rencana
  void setFilterPlanType(String planType) {
    _filterPlanType = planType;
    notifyListeners();
  }

  // Reset filter
  void resetFilters() {
    _filterPlanType = '';
    _selectedDate = null;
    notifyListeners();
  }

  // Buat rencana baru
  Future<bool> createPlan({
    required String title,
    required String description,
    required String childId,
    required String createdBy,
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    required String recurrence,
    required List<int> recurrenceDays,
    required List<PlanActivityModel> activities,
    bool notificationsEnabled = true,
    bool isTemplate = false,
    String? templateName,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final plan = PlanModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        childId: childId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        planType: planType,
        startDate: startDate,
        endDate: endDate,
        recurrence: recurrence,
        recurrenceDays: recurrenceDays,
        activities: activities,
        notificationsEnabled: notificationsEnabled,
        isTemplate: isTemplate,
        templateName: templateName,
      );

      await _planService.createPlan(plan);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat rencana: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Buat rencana dari template
  Future<bool> createPlanFromTemplate(
    String templateId,
    String childId,
    DateTime startDate,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.createPlanFromTemplate(templateId, childId, startDate);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat rencana dari template: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update rencana
  Future<bool> updatePlan(PlanModel plan) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.updatePlan(plan);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate rencana: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update aktivitas dalam rencana
  Future<bool> updatePlanActivity(
    String planId,
    String activityId,
    PlanActivityModel updatedActivity,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.updatePlanActivity(
        planId,
        activityId,
        updatedActivity,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate aktivitas dalam rencana: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tandai aktivitas sebagai selesai
  Future<bool> markActivityAsCompleted(String planId, String activityId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.markActivityAsCompleted(planId, activityId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menandai aktivitas sebagai selesai: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hapus rencana
  Future<bool> deletePlan(String planId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.deletePlan(planId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus rencana: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle notifikasi untuk rencana
  Future<bool> togglePlanNotifications(String planId, bool enabled) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _planService.togglePlanNotifications(planId, enabled);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah status notifikasi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dispose
  @override
  void dispose() {
    _teacherPlansSubscription?.cancel();
    _childPlansSubscription?.cancel();
    _dateRangePlansSubscription?.cancel();
    _templatesSubscription?.cancel();
    super.dispose();
  }
}
