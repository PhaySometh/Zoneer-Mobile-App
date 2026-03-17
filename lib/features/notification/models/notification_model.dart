import 'package:zoneer_mobile/features/notification/models/enums/notification_type.dart';

class NotificationModel {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? createdAt;

  const NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.metadata,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.fromValue(json['notification_type']),
      isRead: json['is_read'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': type.value,
      'is_read': isRead,
      'metadata': metadata,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
