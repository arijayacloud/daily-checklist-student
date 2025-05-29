import 'dart:async';
import 'package:flutter/material.dart';
import '../models/follow_up_suggestion_model.dart';
import '../services/follow_up_service.dart';

class FollowUpProvider with ChangeNotifier {
  final FollowUpService _followUpService = FollowUpService();

  List<FollowUpSuggestionModel> _suggestions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<FollowUpSuggestionModel> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Stream subscription untuk suggestions
  StreamSubscription<List<FollowUpSuggestionModel>>? _suggestionsSubscription;

  // Load saran follow-up untuk anak tertentu
  void loadFollowUpSuggestions(String childId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _suggestionsSubscription?.cancel();

    // Subscribe ke stream suggestions
    _suggestionsSubscription = _followUpService
        .getFollowUpSuggestions(childId)
        .listen(
          (suggestions) {
            _suggestions = suggestions;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat saran follow-up: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Periksa follow-up saat aktivitas selesai
  Future<void> checkForFollowUps(
    String childId,
    String completedActivityId,
  ) async {
    try {
      await _followUpService.checkForFollowUps(childId, completedActivityId);
    } catch (e) {
      _errorMessage = 'Gagal memeriksa follow-up: $e';
      notifyListeners();
    }
  }

  // Terima saran follow-up
  Future<String?> acceptFollowUpSuggestion(
    String followUpId,
    String assignedChecklistItemId,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _followUpService.acceptFollowUpSuggestion(
        followUpId,
        assignedChecklistItemId,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Gagal menerima saran follow-up: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Tolak saran follow-up
  Future<bool> rejectFollowUpSuggestion(String followUpId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _followUpService.rejectFollowUpSuggestion(followUpId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menolak saran follow-up: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Buat saran follow-up baru (manual)
  Future<bool> createFollowUpSuggestion({
    required String childId,
    required String completedActivityId,
    required String suggestedActivityId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _followUpService.createFollowUpSuggestion(
        childId: childId,
        completedActivityId: completedActivityId,
        suggestedActivityId: suggestedActivityId,
        autoAssigned: false,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat saran follow-up: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dispose
  @override
  void dispose() {
    _suggestionsSubscription?.cancel();
    super.dispose();
  }
}
