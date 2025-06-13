import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  UserModel? _user;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;
  int get unreadCount => _unreadCount;

  NotificationProvider(this._apiProvider, this._authProvider) {
    // Initialize with current auth state
    _user = _authProvider.user;
    
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
    
    // Instead of fetching immediately, we'll use a post-frame callback
    // to ensure this doesn't happen during build
    if (_user != null && !_initialized) {
      _initialized = true;
      // Use a microtask to schedule this after the current build frame
      Future.microtask(() {
        fetchNotifications();
        fetchUnreadCount();
      });
    }
  }
  
  void _onAuthChanged() {
    final newUser = _authProvider.user;
    if (newUser != _user) {
      update(newUser);
    }
  }
  
  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void update(UserModel? user) {
    _user = user;
    if (user != null) {
      // Use a microtask to ensure this doesn't run during build
      Future.microtask(() {
        fetchNotifications();
        fetchUnreadCount();
      });
    } else {
      _notifications = [];
      _unreadCount = 0;
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

  Future<void> fetchUnreadCount() async {
    if (_user == null) return;

    try {
      final data = await _apiProvider.get('notifications/unread-count');
      if (data != null && data['unread_count'] != null) {
        _unreadCount = data['unread_count'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
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
        
        // Update unread count
        if (_unreadCount > 0) {
          _unreadCount--;
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

  Future<bool> markAsUnread(String id) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.put('notifications/$id', {
        'is_read': false,
      });
      
      if (data != null) {
        final index = _notifications.indexWhere((notification) => notification.id == id);
        if (index != -1) {
          _notifications[index] = NotificationModel.fromJson(data);
          _unreadCount++;
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking notification as unread: $e');
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
        // Update all notifications in local state to be read
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = NotificationModel(
              id: _notifications[i].id,
              userId: _notifications[i].userId,
              title: _notifications[i].title,
              message: _notifications[i].message,
              type: _notifications[i].type,
              relatedId: _notifications[i].relatedId,
              childId: _notifications[i].childId,
              isRead: true,
              createdAt: _notifications[i].createdAt,
            );
          }
        }
        
        _unreadCount = 0;
        notifyListeners();
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
        // Check if the notification was unread before removing
        bool wasUnread = false;
        final notification = _notifications.firstWhere(
          (notification) => notification.id == id,
          orElse: () => NotificationModel(
            id: '', userId: '', title: '', message: '', type: '', 
            isRead: true, createdAt: DateTime.now()
          ),
        );
        
        wasUnread = !notification.isRead;
        
        _notifications.removeWhere((notification) => notification.id == id);
        
        // Update unread count if necessary
        if (wasUnread && _unreadCount > 0) {
          _unreadCount--;
        }
        
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
  
  Future<bool> registerFirebaseToken(String token, {String? deviceInfo}) async {
    if (_user == null) return false;
    
    try {
      final data = await _apiProvider.post('notifications/register-token', {
        'token': token,
        'device_info': deviceInfo ?? 'Flutter Device',
      });
      
      return data != null;
    } catch (e) {
      debugPrint('Error registering Firebase token: $e');
      return false;
    }
  }
}
