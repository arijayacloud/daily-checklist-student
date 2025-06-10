// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rxdart/rxdart.dart';
// import '/models/notification_model.dart';
// import '/models/user_model.dart';
// import 'package:uuid/uuid.dart';

// class NotificationProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _uuid = const Uuid();

//   UserModel? _user;
//   List<NotificationModel> _notifications = [];
//   bool _isLoading = false;
//   String? _error;
//   String? _childId;

//   List<NotificationModel> get notifications => _notifications;
//   int get unreadCount => _notifications.where((n) => !n.isRead).length;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   set childId(String? id) {
//     _childId = id;
//     if (_user != null && !_user!.isTeacher) {
//       fetchNotifications();
//     }
//   }

//   void update(UserModel? user) {
//     _user = user;
//     if (user != null) {
//       if (!user.isTeacher) {
//         _getChildId().then((_) {
//           fetchNotifications();
//         });
//       } else {
//         fetchNotifications();
//       }
//     } else {
//       _notifications = [];
//       notifyListeners();
//     }
//   }

//   Future<void> _getChildId() async {
//     if (_user == null || _user!.isTeacher) return;

//     try {
//       final snapshot =
//           await _firestore
//               .collection('children')
//               .where('parentId', isEqualTo: _user!.id)
//               .limit(1)
//               .get();

//       if (snapshot.docs.isNotEmpty) {
//         _childId = snapshot.docs.first.id;
//         debugPrint('Found childId: $_childId for parentId: ${_user!.id}');
//       } else {
//         _childId = null;
//         debugPrint('No child found for parent: ${_user!.id}');
//       }
//     } catch (e) {
//       debugPrint('Error getting childId: $e');
//       _childId = null;
//     }
//   }

//   // Metode untuk menambahkan notifikasi test
//   Future<void> addTestNotification({
//     required String title,
//     required String message,
//     required String type,
//     String relatedId = '',
//   }) async {
//     if (_user == null) return;

//     try {
//       final notificationId = _uuid.v4();

//       // Buat notifikasi di Firestore
//       await _firestore.collection('notifications').doc(notificationId).set({
//         'userId': _user!.id,
//         'title': title,
//         'message': message,
//         'type': type,
//         'relatedId': relatedId.isEmpty ? _uuid.v4() : relatedId,
//         'childId': _childId,
//         'isRead': false,
//         'createdAt': Timestamp.now(),
//       });

//       // Refresh daftar notifikasi
//       await fetchNotifications();

//       debugPrint('Test notification created: $title');
//     } catch (e) {
//       debugPrint('Error creating test notification: $e');
//       _error = 'Gagal membuat notifikasi test. Silakan coba lagi.';
//       notifyListeners();
//     }
//   }

//   Future<void> fetchNotifications() async {
//     if (_user == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       Query query = _firestore
//           .collection('notifications')
//           .where('userId', isEqualTo: _user!.id);

//       if (!_user!.isTeacher && _childId != null) {
//         final parentNotificationsSnapshot = await query.get();

//         final childNotificationsSnapshot =
//             await _firestore
//                 .collection('notifications')
//                 .where('childId', isEqualTo: _childId)
//                 .get();

//         final allDocs = [
//           ...parentNotificationsSnapshot.docs,
//           ...childNotificationsSnapshot.docs,
//         ];

//         final Map<String, NotificationModel> uniqueNotifications = {};

//         for (final doc in allDocs) {
//           final notification = NotificationModel.fromJson(
//             doc.data() as Map<String, dynamic>,
//             doc.id,
//           );
//           uniqueNotifications[doc.id] = notification;
//         }

//         _notifications =
//             uniqueNotifications.values.toList()
//               ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
//       } else {
//         final snapshot =
//             await query.orderBy('createdAt', descending: true).get();

//         _notifications =
//             snapshot.docs
//                 .map(
//                   (doc) => NotificationModel.fromJson(
//                     doc.data() as Map<String, dynamic>,
//                     doc.id,
//                   ),
//                 )
//                 .toList();
//       }

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error fetching notifications: $e');
//       _error = 'Gagal memuat notifikasi. Silakan coba lagi.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> markAsRead(String notificationId) async {
//     if (_user == null) return;

//     try {
//       await _firestore.collection('notifications').doc(notificationId).update({
//         'isRead': true,
//       });

//       final index = _notifications.indexWhere((n) => n.id == notificationId);
//       if (index != -1) {
//         _notifications[index] = _notifications[index].copyWith(isRead: true);
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint('Error marking notification as read: $e');
//     }
//   }

//   Future<void> markAllAsRead() async {
//     if (_user == null) return;

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final batch = _firestore.batch();

//       for (final notification in _notifications.where((n) => !n.isRead)) {
//         final ref = _firestore.collection('notifications').doc(notification.id);
//         batch.update(ref, {'isRead': true});
//       }

//       await batch.commit();

//       _notifications =
//           _notifications.map((n) => n.copyWith(isRead: true)).toList();

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error marking all notifications as read: $e');
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> deleteNotification(String notificationId) async {
//     if (_user == null) return;

//     try {
//       await _firestore.collection('notifications').doc(notificationId).delete();

//       _notifications.removeWhere((n) => n.id == notificationId);
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error deleting notification: $e');
//     }
//   }

//   Stream<List<NotificationModel>> getNotificationsStream() {
//     if (_user == null) {
//       return Stream.value([]);
//     }

//     // Jika user adalah orangtua dan memiliki childId, ambil notifikasi untuk anak juga
//     if (!_user!.isTeacher && _childId != null) {
//       // Kita perlu menggabungkan dua stream
//       final userStream =
//           _firestore
//               .collection('notifications')
//               .where('userId', isEqualTo: _user!.id)
//               .orderBy('createdAt', descending: true)
//               .snapshots();

//       final childStream =
//           _firestore
//               .collection('notifications')
//               .where('childId', isEqualTo: _childId)
//               .orderBy('createdAt', descending: true)
//               .snapshots();

//       // Gabungkan kedua stream menggunakan rxdart
//       return Rx.combineLatest2(userStream, childStream, (
//         QuerySnapshot userSnapshot,
//         QuerySnapshot childSnapshot,
//       ) {
//         // Gabungkan dokumen dari kedua snapshot
//         final allDocs = [...userSnapshot.docs, ...childSnapshot.docs];

//         // Deduplikasi dengan menggunakan Map
//         final Map<String, NotificationModel> uniqueNotifications = {};

//         for (final doc in allDocs) {
//           final notification = NotificationModel.fromJson(
//             doc.data() as Map<String, dynamic>,
//             doc.id,
//           );
//           uniqueNotifications[doc.id] = notification;
//         }

//         // Konversi map ke list dan sort
//         final notifications =
//             uniqueNotifications.values.toList()
//               ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

//         return notifications;
//       });
//     } else {
//       // Untuk guru atau orangtua tanpa childId
//       return _firestore
//           .collection('notifications')
//           .where('userId', isEqualTo: _user!.id)
//           .orderBy('createdAt', descending: true)
//           .snapshots()
//           .map(
//             (snapshot) =>
//                 snapshot.docs
//                     .map(
//                       (doc) => NotificationModel.fromJson(
//                         doc.data() as Map<String, dynamic>,
//                         doc.id,
//                       ),
//                     )
//                     .toList(),
//           );
//     }
//   }

//   // Metode untuk membuat notifikasi pengingat aktivitas harian
//   Future<void> createDailyReminderNotification({
//     required List<String> activityTitles,
//     required DateTime date,
//     String? childId,
//   }) async {
//     if (_user == null) return;

//     try {
//       // Format pesan notifikasi
//       final String message =
//           activityTitles.length > 3
//               ? 'Anda memiliki ${activityTitles.length} aktivitas hari ini: ${activityTitles.take(3).join(', ')} dan lainnya.'
//               : 'Anda memiliki ${activityTitles.length} aktivitas hari ini: ${activityTitles.join(', ')}.';

//       // Buat notifikasi pengingat
//       final notificationId = _uuid.v4();

//       await _firestore.collection('notifications').doc(notificationId).set({
//         'userId': _user!.id,
//         'title': 'Aktivitas Hari Ini',
//         'message': message,
//         'type': 'daily_reminder',
//         'relatedId': '',
//         'childId': childId,
//         'isRead': false,
//         'createdAt': Timestamp.now(),
//       });

//       // Refresh daftar notifikasi
//       await fetchNotifications();

//       debugPrint('Daily reminder notification created for user ${_user!.id}');
//     } catch (e) {
//       debugPrint('Error creating daily reminder notification: $e');
//     }
//   }

//   Future<void> createNotification({
//     required String title,
//     required String message,
//     required String type,
//     String relatedId = '',
//     required String userId,
//     String? childId,
//   }) async {
//     try {
//       final notificationId = _uuid.v4();

//       await _firestore.collection('notifications').doc(notificationId).set({
//         'userId': userId,
//         'title': title,
//         'message': message,
//         'type': type,
//         'relatedId': relatedId,
//         'childId': childId,
//         'isRead': false,
//         'createdAt': Timestamp.now(),
//       });

//       if (_user != null && userId == _user!.id) {
//         await fetchNotifications();
//       }

//       debugPrint('Notification created: $title for user $userId');
//     } catch (e) {
//       debugPrint('Error creating notification: $e');
//     }
//   }
// }
