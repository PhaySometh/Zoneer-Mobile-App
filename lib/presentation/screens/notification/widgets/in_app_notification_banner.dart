import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/notification/enums/notification_type.dart';
import 'package:zoneer_mobile/data/models/notification/notification_model.dart';
import 'package:zoneer_mobile/presentation/screens/notification/providers/in_app_notification_provider.dart';
import 'package:zoneer_mobile/presentation/screens/notification/notification_screen.dart';

/// Listens to [inAppNotificationProvider] and inserts a root OverlayEntry
/// so the banner appears on top of any active route (including upload screen).
class InAppNotificationBanner extends ConsumerStatefulWidget {
  const InAppNotificationBanner({super.key});

  @override
  ConsumerState<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState
    extends ConsumerState<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  OverlayEntry? _overlayEntry;
  NotificationModel? _current;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Rebuild overlay entry on each animation tick so transitions play.
    _ctrl.addListener(() => _overlayEntry?.markNeedsBuild());
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _ctrl.dispose();
    super.dispose();
  }

  void _show(NotificationModel notification) {
    _autoDismiss?.cancel();
    _current = notification;

    // Remove any existing overlay before inserting a new one.
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(builder: _buildOverlay);

    // Insert into the root overlay so it appears above all routes.
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _ctrl.forward(from: 0);
    _autoDismiss = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    _ctrl.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _current = null;
      if (mounted) {
        ref.read(inAppNotificationProvider.notifier).clear();
      }
    });
  }

  void _onTap() {
    _dismiss();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    }
  }

  Widget _buildOverlay(BuildContext ctx) {
    final notification = _current;
    if (notification == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(ctx).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _BannerCard(
            notification: notification,
            onTap: _onTap,
            onDismiss: _dismiss,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationModel?>(inAppNotificationProvider, (_, next) {
      if (next != null) _show(next);
    });
    return const SizedBox.shrink();
  }
}

class _BannerCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon {
    switch (notification.type) {
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dismiss button
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
