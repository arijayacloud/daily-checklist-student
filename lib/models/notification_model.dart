// import 'package:cloud_firestore/cloud_firestore.dart';

// class NotificationModel {
//   final String id;
//   final String userId;
//   final String title;
//   final String message;
//   final String type; // 'new_plan', 'activity_completed', dll
//   final String relatedId; // planId, activityId, dll
//   final bool isRead;
//   final Timestamp createdAt;

//   NotificationModel({
//     required this.id,
//     required this.userId,
//     required this.title,
//     required this.message,
//     required this.type,
//     required this.relatedId,
//     required this.isRead,
//     required this.createdAt,
//   });

//   factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
//     return NotificationModel(
//       id: id,
//       userId: json['userId'] ?? '',
//       title: json['title'] ?? '',
//       message: json['message'] ?? '',
//       type: json['type'] ?? '',
//       relatedId: json['relatedId'] ?? '',
//       isRead: json['isRead'] ?? false,
//       createdAt: json['createdAt'] ?? Timestamp.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'title': title,
//       'message': message,
//       'type': type,
//       'relatedId': relatedId,
//       'isRead': isRead,
//       'createdAt': createdAt,
//     };
//   }

//   NotificationModel copyWith({
//     String? id,
//     String? userId,
//     String? title,
//     String? message,
//     String? type,
//     String? relatedId,
//     bool? isRead,
//     Timestamp? createdAt,
//   }) {
//     return NotificationModel(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       title: title ?? this.title,
//       message: message ?? this.message,
//       type: type ?? this.type,
//       relatedId: relatedId ?? this.relatedId,
//       isRead: isRead ?? this.isRead,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }
// }
