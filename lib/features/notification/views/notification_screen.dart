import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/features/notification/viewmodels/notification_viewmodel.dart';
import 'package:zoneer_mobile/features/notification/widgets/notification_tile.dart';
import 'package:zoneer_mobile/features/user/views/auth/auth_required_screen.dart';

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
              ],
      ),
      body: notificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

                            return NotificationRow(
                              notification: notification,
                              isSelected: isSelected,
                              onTap: () {
                                if (isSelectionMode) {
                                  _toggleSelection(notification.id!);
                                } else {
                                  if (!notification.isRead) {
                                    ref
                                        .read(
                                          notificationsViewModelProvider
                                              .notifier,
                                        )
                                        .markNotificationAsRead(
                                          notification.id!,
                                        );
                                  }
                                }
                              },
                              onLongPress: () {
                                _toggleSelection(notification.id!);
                              },
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
              'You’re all caught up.',
              style: TextStyle(color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
