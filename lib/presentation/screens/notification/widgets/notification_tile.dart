import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/notification/enums/notification_type.dart';
import 'package:zoneer_mobile/data/models/notification/notification_model.dart';

class NotificationRow extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;

  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.check_circle : _iconForType(notification.type),
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : isUnread
                  ? AppColors.primary
                  : Colors.black45,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            /// Unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(String? iso) {
  if (iso == null) return '';
  final time = DateTime.parse(iso);
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

IconData _iconForType(NotificationType type) {
  switch (type) {
    case NotificationType.propertyVerification:
      return Icons.home_work_outlined;
    case NotificationType.tenantVerification:
    case NotificationType.landlordVerification:
      return Icons.verified_user_outlined;
    case NotificationType.transaction:
      return Icons.payments_outlined;
    case NotificationType.inquiryResponse:
      return Icons.chat_bubble_outline;
    case NotificationType.reminder:
      return Icons.notifications_active_outlined;
    case NotificationType.system:
      return Icons.info_outline;
  }
}
