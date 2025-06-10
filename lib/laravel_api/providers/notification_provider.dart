import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'api_provider.dart';

class NotificationProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  UserModel? _user;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;
  int get unreadCount => unreadNotifications.length;

  NotificationProvider(this._apiProvider);

  void update(UserModel? user) {
    _user = user;
    if (user != null) {
      fetchNotifications();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> fetchNotifications({String? childId}) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = 'notifications';
      if (childId != null) {
        endpoint += '?child_id=$childId';
      }
      
      final data = await _apiProvider.get(endpoint);
      
      if (data != null) {
        _notifications = (data as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _error = 'Failed to load notifications. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NotificationModel?> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
    String? childId,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      _error = 'Only teachers can create notifications';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('notifications', {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        if (relatedId != null) 'related_id': relatedId,
        if (childId != null) 'child_id': childId,
      });
      
      if (data != null) {
        final notification = NotificationModel.fromJson(data);
        _notifications.add(notification);
        notifyListeners();
        return notification;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      _error = 'Failed to create notification. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> markAsRead(String id) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.put('notifications/$id', {
        'is_read': true,
      });
      
      if (data != null) {
        final index = _notifications.indexWhere((notification) => notification.id == id);
        if (index != -1) {
          _notifications[index] = NotificationModel.fromJson(data);
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      _error = 'Failed to update notification. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.put('notifications/read-all', {});
      
      if (data != null) {
        // Refresh notifications after marking all as read
        await fetchNotifications();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      _error = 'Failed to mark all notifications as read. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.delete('notifications/$id');
      
      if (data != null) {
        _notifications.removeWhere((notification) => notification.id == id);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      _error = 'Failed to delete notification. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
