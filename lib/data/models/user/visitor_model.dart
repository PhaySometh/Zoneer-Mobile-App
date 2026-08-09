class VisitorModel {
  final String id;
  final String? deviceId;
  final String lastActive;
  final String? createdAt;

  const VisitorModel({
    required this.id,
    this.deviceId,
    required this.lastActive,
    this.createdAt,
  });

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String?,
      lastActive: json['last_active'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}
