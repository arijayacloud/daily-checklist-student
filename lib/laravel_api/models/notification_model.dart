// Model Notification untuk API Laravel
class NotificationModel {
  final int id;
  final String message;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'message': message, 'created_at': createdAt};
  }
}
