import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/notification/enums/notification_type.dart';
import 'package:zoneer_mobile/presentation/viewmodels/notification/notification_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/notification/widgets/notification_tile.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/screens/user/auth/auth_required_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool showUnreadOnly = false;
  final Set<String> selectedIds = {};

  bool get isSelectionMode => selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null) {
      Future.microtask(() {
        ref
            .read(notificationsViewModelProvider.notifier)
            .loadNotifications(authUser.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      return const AuthRequiredScreen();
    }
    final notificationAsync = ref.watch(notificationsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        title: isSelectionMode
            ? Text('${selectedIds.length} selected')
            : const Text('Notifications'),
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
              ]
            : [
                IconButton(
                  onPressed: () {
                    ref
                        .read(notificationsViewModelProvider.notifier)
                        .markAllNotificationsAsRead(authUser.id);
                  },
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                ),
                PopupMenuButton<_NotifAction>(
                  onSelected: (action) async {
                    if (action == _NotifAction.clearAll) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all notifications?'),
                          content: const Text(
                            'This will permanently delete all your notifications.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Clear all',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref
                            .read(notificationsViewModelProvider.notifier)
                            .deleteAllNotifications(authUser.id);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _NotifAction.clearAll,
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Clear all',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: notificationAsync.when(
        loading: () => const _NotificationSkeleton(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading notifications: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (showUnreadOnly) {
                    ref
                        .read(notificationsViewModelProvider.notifier)
                        .loadUnreadNotifications(authUser.id);
                  } else {
                    ref
                        .read(notificationsViewModelProvider.notifier)
                        .loadNotifications(authUser.id);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          final visibleNotifications = showUnreadOnly
              ? notifications.where((n) => !n.isRead).toList()
              : notifications;

          return Column(
            children: [
              /// Filter toggle
              _FilterBar(
                showUnreadOnly: showUnreadOnly,
                onChanged: (value) {
                  setState(() {
                    showUnreadOnly = value;
                    _clearSelection();
                  });
                },
              ),

              const SizedBox(height: 4),

              Expanded(
                child: visibleNotifications.isEmpty
                    ? const _EmptyNotificationState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(notificationsViewModelProvider.notifier)
                              .loadNotifications(authUser.id);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: visibleNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = visibleNotifications[index];
                            final isSelected = selectedIds.contains(
                              notification.id,
                            );

                            return Dismissible(
                              key: Key(notification.id ?? index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                              onDismissed: (_) {
                                ref
                                    .read(
                                      notificationsViewModelProvider.notifier,
                                    )
                                    .deleteNotification(notification.id!);
                              },
                              child: NotificationRow(
                                notification: notification,
                                isSelected: isSelected,
                                onTap: () {
                                  if (isSelectionMode) {
                                    _toggleSelection(notification.id!);
                                    return;
                                  }
                                  // Mark as read
                                  if (!notification.isRead) {
                                    ref
                                        .read(
                                          notificationsViewModelProvider
                                              .notifier,
                                        )
                                        .markNotificationAsRead(
                                            notification.id!);
                                  }
                                  // Navigate to property detail if applicable
                                  final propertyId = notification
                                      .metadata?['property_id'] as String?;
                                  if (propertyId != null &&
                                      (notification.type ==
                                              NotificationType
                                                  .propertyVerification ||
                                          notification.type ==
                                              NotificationType.system)) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PropertyDetailPage(id: propertyId),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  _toggleSelection(notification.id!);
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedIds.clear();
    });
  }

  void _deleteSelected() async {


    await ref
        .read(notificationsViewModelProvider.notifier)
        .deleteMultipleNotifications(selectedIds.toList());

    setState(() {
      selectedIds.clear();
    });
  }
}

class _FilterBar extends StatelessWidget {
  final bool showUnreadOnly;
  final ValueChanged<bool> onChanged;

  const _FilterBar({required this.showUnreadOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterButton(
            label: 'All',
            isActive: !showUnreadOnly,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 16),
          _FilterButton(
            label: 'Unread',
            isActive: showUnreadOnly,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isActive ? AppColors.primary : Colors.black45,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationSkeleton extends StatefulWidget {
  const _NotificationSkeleton();

  @override
  State<_NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<_NotificationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(160, 14),
                      const SizedBox(height: 6),
                      _box(double.infinity, 12),
                      const SizedBox(height: 4),
                      _box(80, 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_none, size: 56, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              "You're all caught up.",
              style: TextStyle(color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotifAction { clearAll }
