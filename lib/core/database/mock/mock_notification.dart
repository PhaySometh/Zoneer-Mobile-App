import 'package:zoneer_mobile/data/models/notification/notification_model.dart';
import 'package:zoneer_mobile/data/models/notification/enums/notification_type.dart';

/// Mock notification data for development/testing
final List<NotificationModel> mockNotifications = [
  NotificationModel(
    id: '1',
    userId: 'u1',
    title: 'Property Approved',
    message: 'Your property listing has been approved.',
    type: NotificationType.propertyVerification,
    isRead: false,
    createdAt: DateTime.now().toIso8601String(),
  ),
  NotificationModel(
    id: '2',
    userId: 'u1',
    title: 'New Inquiry',
    message: 'A tenant sent you a message.',
    type: NotificationType.inquiryResponse,
    isRead: true,
    createdAt: DateTime.now()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
  ),
  NotificationModel(
    id: '3',
    userId: 'u1',
    title: 'Payment Received',
    message: 'You received a payment of \$1,200 for your property.',
    type: NotificationType.transaction,
    isRead: false,
    createdAt: DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
  ),
  NotificationModel(
    id: '4',
    userId: 'u1',
    title: 'Maintenance Request',
    message: 'A tenant has submitted a maintenance request.',
    type: NotificationType.inquiryResponse,
    isRead: false,
    createdAt: DateTime.now()
        .subtract(const Duration(days: 2))
        .toIso8601String(),
  ),
];
