import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:daily_checklist_student/models/models.dart';
import 'package:daily_checklist_student/services/checklist_service.dart';
import 'package:daily_checklist_student/services/activity_service.dart';

class ChecklistProvider with ChangeNotifier {
  final ChecklistService _checklistService = ChecklistService();
  final ActivityService _activityService = ActivityService();

  List<ChecklistItemModel> _checklistItems = [];
  List<ActivityModel> _activities = [];
  List<CompletionLogModel> _logs = [];

  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all'; // 'all', 'pending', 'partial', 'complete'

  // Getters
  List<ChecklistItemModel> get checklistItems => _checklistItems;
  List<ActivityModel> get activities => _activities;
  List<CompletionLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  // Streams subscription
  StreamSubscription<List<ChecklistItemModel>>? _checklistItemsSubscription;
  StreamSubscription<List<CompletionLogModel>>? _logsSubscription;

  // Fetch checklist items for a child
  Future<void> fetchChecklistItems(String childId) async {
    try {
      _setLoading(true);

      // Cancel previous subscription if exists
      _checklistItemsSubscription?.cancel();

      // Subscribe to checklist items stream
      _checklistItemsSubscription = _checklistService
          .getChildChecklistItems(childId)
          .listen(_handleChecklistItemsUpdate, onError: _handleError);
    } catch (e) {
      _handleError(e);
    }
  }

  // Filter methods
  List<ChecklistItemModel> getPendingItems() {
    return _checklistItems
        .where((item) => item.overallStatus == 'pending')
        .toList();
  }

  List<ChecklistItemModel> getCompletedItems() {
    return _checklistItems
        .where((item) => item.overallStatus == 'complete')
        .toList();
  }

  List<ChecklistItemModel> getPartialItems() {
    return _checklistItems
        .where((item) => item.overallStatus == 'partial')
        .toList();
  }

  List<ChecklistItemModel> getOverdueItems() {
    try {
      final now = DateTime.now();
      return _checklistItems
          .where(
            (item) =>
                item.dueDate.isBefore(now) && item.overallStatus != 'complete',
          )
          .toList();
    } catch (e) {
      _handleError('Error getting overdue items: $e');
      return [];
    }
  }

  // Inisialisasi checklist untuk anak
  void initChildChecklist(String childId) {
    _setLoading(true);

    // Batalkan subscription sebelumnya jika ada
    _checklistItemsSubscription?.cancel();

    // Langganan ke stream checklist items
    _checklistItemsSubscription = _checklistService
        .getChildChecklistItems(childId)
        .listen(_handleChecklistItemsUpdate, onError: _handleError);
  }

  // Inisialisasi checklist untuk guru dengan daftar anak
  void initTeacherChecklist(List<String> childrenIds) {
    _setLoading(true);

    // Batalkan subscription sebelumnya jika ada
    _checklistItemsSubscription?.cancel();

    // Langganan ke stream checklist items untuk guru
    _checklistItemsSubscription = _checklistService
        .getTeacherChecklistItems(childrenIds)
        .listen(_handleChecklistItemsUpdate, onError: _handleError);
  }

  // Handler untuk pembaruan checklist items
  void _handleChecklistItemsUpdate(List<ChecklistItemModel> items) async {
    _checklistItems = items;

    // Muat aktivitas untuk setiap checklist item
    final activityIds = items.map((item) => item.activityId).toSet().toList();
    _activities = [];

    for (final activityId in activityIds) {
      try {
        final activity = await _activityService.getActivityById(activityId);
        if (activity != null) {
          _activities.add(activity);
        }
      } catch (e) {
        print('Error loading activity $activityId: $e');
      }
    }

    _setLoading(false);
    notifyListeners();
  }

  // Set filter untuk checklist
  void setFilter(String filter, String childId) {
    if (_currentFilter == filter) return;

    _currentFilter = filter;
    _setLoading(true);

    // Batalkan subscription sebelumnya
    _checklistItemsSubscription?.cancel();

    // Jika 'all', gunakan semua checklist
    if (filter == 'all') {
      _checklistItemsSubscription = _checklistService
          .getChildChecklistItems(childId)
          .listen(_handleChecklistItemsUpdate, onError: _handleError);
    } else {
      // Filter berdasarkan status
      _checklistItemsSubscription = _checklistService
          .getFilteredChildChecklistItems(childId, filter)
          .listen(_handleChecklistItemsUpdate, onError: _handleError);
    }

    notifyListeners();
  }

  // Memperbarui status aktivitas
  Future<void> updateCompletionStatus({
    required String checklistItemId,
    required String environment,
    required String userId,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);

      await _checklistService.updateCompletionStatus(
        checklistItemId: checklistItemId,
        environment: environment,
        userId: userId,
        notes: notes,
        photoUrl: photoUrl,
      );

      // Load logs for this checklist item
      loadChecklistItemLogs(checklistItemId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // Membuat checklist item baru
  Future<void> createChecklistItem({
    required String childId,
    required String activityId,
    required DateTime dueDate,
  }) async {
    try {
      _setLoading(true);

      await _checklistService.createChecklistItem(
        childId: childId,
        activityId: activityId,
        dueDate: dueDate,
      );

      _setLoading(false);
      // Stream akan otomatis memperbarui checklistItems
    } catch (e) {
      _handleError(e);
    }
  }

  // Memuat log untuk checklist item tertentu
  void loadChecklistItemLogs(String checklistItemId) {
    _logsSubscription?.cancel();

    _logsSubscription = _checklistService
        .getChecklistItemLogs(checklistItemId)
        .listen((logs) {
          _logs = logs;
          notifyListeners();
        }, onError: _handleError);
  }

  // Helper untuk set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    notifyListeners();
  }

  // Handler untuk error
  void _handleError(dynamic error) {
    _isLoading = false;
    _error = error is String ? error : error.toString();
    notifyListeners();
    print('Checklist Provider Error: $_error');
  }

  // Mencari activity untuk checklist item
  ActivityModel? findActivityForChecklistItem(String activityId) {
    try {
      return _activities.firstWhere((activity) => activity.id == activityId);
    } catch (e) {
      return null;
    }
  }

  // Bersihkan resources ketika provider di-dispose
  @override
  void dispose() {
    _checklistItemsSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }
}
