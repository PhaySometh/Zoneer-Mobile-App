import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/features/notification/models/notification_model.dart';
import 'package:zoneer_mobile/features/notification/repositories/notification_repository.dart';

class NotificationViewmodel extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async => [];

  Future<void> loadNotifications(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(notificationRepositoryProvider)
          .getNotificationsByUserId(userId);
    });
  }

  Future<void> loadUnreadNotifications(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(notificationRepositoryProvider)
          .getUnreadNotifications(userId);
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);

      final currentState = state;

      if (currentState is AsyncData<List<NotificationModel>>) {
        return currentState.value
            .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
            .toList();
      }

      return currentState.value ?? <NotificationModel>[];
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(notificationRepositoryProvider).markAllAsRead(userId);

      final currentState = state;

      if (currentState is AsyncData<List<NotificationModel>>) {
        return currentState.value.map((n) => n.copyWith(isRead: true)).toList();
      }

      return currentState.value ?? <NotificationModel>[];
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationRepositoryProvider)
          .deleteOneNotification(notificationId);

      final currentState = state;

      if (currentState is AsyncData<List<NotificationModel>>) {
        return currentState.value.where((n) => n.id != notificationId).toList();
      }

      return currentState.value ?? <NotificationModel>[];
    });
  }

  Future<void> deleteAllNotifications(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationRepositoryProvider)
          .deleteAllNotificationsByUserId(userId);

      return <NotificationModel>[];
    });
  }

  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationRepositoryProvider)
          .deleteMultipleNotifications(notificationIds);

      final currentState = state;

      if (currentState is AsyncData<List<NotificationModel>>) {
        return currentState.value
            .where((n) => !notificationIds.contains(n.id))
            .toList();
      }

      return currentState.value ?? <NotificationModel>[];
    });
  }

  Future<void> createNotification(NotificationModel notification) async {
    await ref.read(notificationRepositoryProvider).createNotification(notification);
  }
}

final notificationsViewModelProvider =
    AsyncNotifierProvider<NotificationViewmodel, List<NotificationModel>>(
      NotificationViewmodel.new,
    );
