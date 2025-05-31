import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/notification_model.dart';
import '/models/user_model.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  UserModel? _user;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void update(UserModel? user) {
    _user = user;
    if (user != null) {
      fetchNotifications();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  // Metode untuk menambahkan notifikasi test
  Future<void> addTestNotification({
    required String title,
    required String message,
    required String type,
    String relatedId = '',
  }) async {
    if (_user == null) return;

    try {
      final notificationId = _uuid.v4();

      // Buat notifikasi di Firestore
      await _firestore.collection('notifications').doc(notificationId).set({
        'userId': _user!.id,
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId.isEmpty ? _uuid.v4() : relatedId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      // Refresh daftar notifikasi
      await fetchNotifications();

      debugPrint('Test notification created: $title');
    } catch (e) {
      debugPrint('Error creating test notification: $e');
      _error = 'Gagal membuat notifikasi test. Silakan coba lagi.';
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _user!.id)
              .orderBy('createdAt', descending: true)
              .get();

      _notifications =
          snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
              .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _error = 'Gagal memuat notifikasi. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_user == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      for (final notification in _notifications.where((n) => !n.isRead)) {
        final ref = _firestore.collection('notifications').doc(notification.id);
        batch.update(ref, {'isRead': true});
      }

      await batch.commit();

      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_user == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _user!.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Metode untuk membuat notifikasi pengingat aktivitas harian
  Future<void> createDailyReminderNotification({
    required List<String> activityTitles,
    required DateTime date,
  }) async {
    if (_user == null) return;

    try {
      // Format pesan notifikasi
      final String message =
          activityTitles.length > 3
              ? 'Anda memiliki ${activityTitles.length} aktivitas hari ini: ${activityTitles.take(3).join(', ')} dan lainnya.'
              : 'Anda memiliki ${activityTitles.length} aktivitas hari ini: ${activityTitles.join(', ')}.';

      // Buat notifikasi pengingat
      final notificationId = _uuid.v4();

      await _firestore.collection('notifications').doc(notificationId).set({
        'userId': _user!.id,
        'title': 'Aktivitas Hari Ini',
        'message': message,
        'type': 'daily_reminder',
        'relatedId': '',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      // Refresh daftar notifikasi
      await fetchNotifications();

      debugPrint('Daily reminder notification created for user ${_user!.id}');
    } catch (e) {
      debugPrint('Error creating daily reminder notification: $e');
    }
  }
}
