enum NotificationType {
  system('system'),
  propertyVerification('property_verification'),
  tenantVerification('tenant_verification'),
  landlordVerification('landlord_verification'),
  transaction('transaction'),
  inquiryResponse('inquiry_response'),
  reminder('reminder');

  final String value;

  const NotificationType(this.value);

  static NotificationType fromValue(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

enum NotificationHelper {
  notification(
    'New Notification',
    'You have a new notification',
  ),
  upload(
    'Property under review',
    'Your property is currently under review',
  );

  final String title;
  final String message;

  const NotificationHelper(this.title, this.message);

  static NotificationHelper fromTitle(String? title) {
    return NotificationHelper.values.firstWhere(
      (e) => e.title == title,
      orElse: () => NotificationHelper.notification,
    );
  }
}