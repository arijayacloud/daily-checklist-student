import 'dart:async';
import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();

  List<AssignmentModel> _assignments = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _filterStatus = '';
  String _filterChildId = '';
  bool _showAllAssignments = false;

  // Getters
  List<AssignmentModel> get assignments => _filterAssignments();
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  String get filterChildId => _filterChildId;
  bool get showAllAssignments => _showAllAssignments;

  // Stream subscription
  StreamSubscription<List<AssignmentModel>>? _assignmentsSubscription;

  // Mendapatkan semua tugas untuk guru tertentu
  void loadAssignmentsForTeacher(
    String teacherId, {
    bool showAllAssignments = false,
  }) {
    _isLoading = true;
    _errorMessage = '';
    _showAllAssignments = showAllAssignments;
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _assignmentsSubscription?.cancel();

    // Subscribe ke stream assignments
    _assignmentsSubscription = _assignmentService
        .getAssignmentsByTeacher(
          teacherId,
          getAllAssignments: showAllAssignments,
        )
        .listen(
          (assignments) {
            _assignments = assignments;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat tugas: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Toggle antara menampilkan semua tugas atau hanya tugas guru tertentu
  void toggleShowAllAssignments(String teacherId) {
    _showAllAssignments = !_showAllAssignments;
    loadAssignmentsForTeacher(
      teacherId,
      showAllAssignments: _showAllAssignments,
    );
  }

  // Mendapatkan semua tugas untuk anak tertentu
  void loadAssignmentsForChild(String childId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _assignmentsSubscription?.cancel();

    // Subscribe ke stream assignments
    _assignmentsSubscription = _assignmentService
        .getAssignmentsByChild(childId)
        .listen(
          (assignments) {
            _assignments = assignments;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat tugas: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Filter tugas berdasarkan status dan childId
  List<AssignmentModel> _filterAssignments() {
    List<AssignmentModel> filteredList = _assignments;

    // Filter berdasarkan status jika ada
    if (_filterStatus.isNotEmpty) {
      filteredList =
          filteredList
              .where((assignment) => assignment.status == _filterStatus)
              .toList();
    }

    // Filter berdasarkan childId jika ada
    if (_filterChildId.isNotEmpty) {
      filteredList =
          filteredList
              .where((assignment) => assignment.childId == _filterChildId)
              .toList();
    }

    return filteredList;
  }

  // Set filter status
  void setStatusFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Set filter child
  void setChildFilter(String childId) {
    _filterChildId = childId;
    notifyListeners();
  }

  // Reset filters
  void resetFilters() {
    _filterStatus = '';
    _filterChildId = '';
    notifyListeners();
  }

  // Tambah tugas tunggal
  Future<bool> addAssignment({
    required String childId,
    required String activityId,
    required String teacherId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _assignmentService.addAssignment(
        childId: childId,
        activityId: activityId,
        teacherId: teacherId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan tugas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tambah tugas massal (bulk assignment)
  Future<bool> bulkAssignActivity({
    required List<String> childIds,
    required String activityId,
    required String teacherId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _assignmentService.bulkAssignActivity(
        childIds: childIds,
        activityId: activityId,
        teacherId: teacherId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan tugas massal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update status tugas
  Future<bool> updateAssignmentStatus({
    required String id,
    required String status,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _assignmentService.updateAssignmentStatus(
        id: id,
        status: status,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate status tugas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hapus tugas
  Future<bool> deleteAssignment(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _assignmentService.deleteAssignment(id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus tugas: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mendapatkan progress untuk anak tertentu
  double getProgressForChild(String childId) {
    final childAssignments =
        _assignments
            .where((assignment) => assignment.childId == childId)
            .toList();

    if (childAssignments.isEmpty) {
      return 0.0;
    }

    final completedAssignments =
        childAssignments
            .where((assignment) => assignment.status == 'done')
            .length;

    return completedAssignments / childAssignments.length;
  }

  // Dispose
  @override
  void dispose() {
    _assignmentsSubscription?.cancel();
    super.dispose();
  }
}
