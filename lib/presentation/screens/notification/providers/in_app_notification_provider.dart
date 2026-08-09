import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/notification/notification_model.dart';

class InAppNotificationNotifier extends Notifier<NotificationModel?> {
  @override
  NotificationModel? build() => null;

  void show(NotificationModel notification) => state = notification;
  void clear() => state = null;
}

final inAppNotificationProvider =
    NotifierProvider<InAppNotificationNotifier, NotificationModel?>(
      InAppNotificationNotifier.new,
    );
