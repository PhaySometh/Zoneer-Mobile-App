class MediaModel {
  final String id;
  final String url;
  final String propertyId;

  const MediaModel({
    required this.id,
    required this.url,
    required this.propertyId,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      url: json['url'] as String,
      propertyId: json['property_id'] as String,
    );
  }
}
