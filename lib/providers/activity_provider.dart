import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  final ActivityService _activityService = ActivityService();

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterEnvironment = '';
  String _filterDifficulty = '';
  RangeValues? _ageRangeFilter;
  bool _showAllActivities = false;

  // Getters
  List<ActivityModel> get activities => _filterActivities();
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filterEnvironment => _filterEnvironment;
  String get filterDifficulty => _filterDifficulty;
  RangeValues? get ageRangeFilter => _ageRangeFilter;
  bool get showAllActivities => _showAllActivities;

  // Stream subscription untuk aktivitas
  StreamSubscription<List<ActivityModel>>? _activitiesSubscription;
  StreamSubscription<List<ActivityModel>>? _ageBasedActivitiesSubscription;

  // Load aktivitas untuk guru tertentu
  void loadActivities(String teacherId, {bool showAllActivities = false}) {
    _isLoading = true;
    _errorMessage = '';
    _showAllActivities = showAllActivities;
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _activitiesSubscription?.cancel();

    // Subscribe ke stream aktivitas
    _activitiesSubscription = _activityService
        .getActivitiesByTeacher(teacherId, getAllActivities: showAllActivities)
        .listen(
          (activities) {
            _activities = activities;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat aktivitas: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Load aktivitas berdasarkan usia anak
  void loadActivitiesByAge(int childAge) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _ageBasedActivitiesSubscription?.cancel();

    // Subscribe ke stream aktivitas berdasarkan usia
    _ageBasedActivitiesSubscription = _activityService
        .getActivitiesByAgeRange(childAge)
        .listen(
          (activities) {
            _activities = activities;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat aktivitas berdasarkan usia: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Dapatkan aktivitas lanjutan
  Future<ActivityModel?> getFollowUpActivity(String activityId) async {
    try {
      return await _activityService.getFollowUpActivity(activityId);
    } catch (e) {
      _errorMessage = 'Gagal mendapatkan aktivitas lanjutan: $e';
      notifyListeners();
      return null;
    }
  }

  // Toggle antara menampilkan semua aktivitas atau hanya aktivitas guru tertentu
  void toggleShowAllActivities(String teacherId) {
    _showAllActivities = !_showAllActivities;
    loadActivities(teacherId, showAllActivities: _showAllActivities);
  }

  // Filter dan cari aktivitas
  List<ActivityModel> _filterActivities() {
    List<ActivityModel> filteredList = _activities;

    // Filter berdasarkan environment jika ada
    if (_filterEnvironment.isNotEmpty) {
      filteredList =
          filteredList
              .where((activity) => activity.environment == _filterEnvironment)
              .toList();
    }

    // Filter berdasarkan difficulty jika ada
    if (_filterDifficulty.isNotEmpty) {
      filteredList =
          filteredList
              .where((activity) => activity.difficulty == _filterDifficulty)
              .toList();
    }

    // Filter berdasarkan rentang usia jika ada
    if (_ageRangeFilter != null) {
      filteredList =
          filteredList.where((activity) {
            return activity.ageRange.max >= _ageRangeFilter!.start.toInt() &&
                activity.ageRange.min <= _ageRangeFilter!.end.toInt();
          }).toList();
    }

    // Filter berdasarkan query pencarian jika ada
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      filteredList =
          filteredList
              .where(
                (activity) =>
                    activity.title.toLowerCase().contains(lowercaseQuery) ||
                    activity.description.toLowerCase().contains(lowercaseQuery),
              )
              .toList();
    }

    return filteredList;
  }

  // Set filter environment
  void setEnvironmentFilter(String environment) {
    _filterEnvironment = environment;
    notifyListeners();
  }

  // Set filter difficulty
  void setDifficultyFilter(String difficulty) {
    _filterDifficulty = difficulty;
    notifyListeners();
  }

  // Set filter rentang usia
  void setAgeRangeFilter(RangeValues values) {
    _ageRangeFilter = values;
    notifyListeners();
  }

  // Reset filter
  void resetFilters() {
    _filterEnvironment = '';
    _filterDifficulty = '';
    _ageRangeFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Tambah aktivitas baru
  Future<bool> addActivity({
    required String title,
    required String description,
    required String environment,
    required String difficulty,
    required String teacherId,
    required AgeRange ageRange,
    String? nextActivityId,
    List<CustomStep>? customSteps,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newActivity = ActivityModel(
        id: const Uuid().v4(), // Temporary ID
        title: title,
        description: description,
        environment: environment,
        difficulty: difficulty,
        teacherId: teacherId,
        createdAt: DateTime.now(),
        ageRange: ageRange,
        nextActivityId: nextActivityId,
        customSteps: customSteps ?? [],
      );

      await _activityService.addActivity(newActivity);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan aktivitas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update aktivitas
  Future<bool> updateActivity(ActivityModel activity) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _activityService.updateActivity(activity);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate aktivitas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tambah custom steps
  Future<bool> addCustomSteps(
    String activityId,
    String teacherId,
    List<String> steps,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _activityService.addCustomSteps(activityId, teacherId, steps);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan custom steps: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hapus aktivitas
  Future<bool> deleteActivity(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _activityService.deleteActivity(id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus aktivitas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dispose
  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    _ageBasedActivitiesSubscription?.cancel();
    super.dispose();
  }
}
