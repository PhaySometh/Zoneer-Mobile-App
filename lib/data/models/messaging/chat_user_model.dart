class ChatUserModel {
  final String id;
  final String fullname;
  final String? profileUrl;

  const ChatUserModel({
    required this.id,
    required this.fullname,
    this.profileUrl,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'] as String,
      fullname: (json['fullname'] as String?)?.trim().isNotEmpty == true
          ? json['fullname'] as String
          : 'Unknown',
      profileUrl: json['image_profile_url'] as String?,
    );
  }
}
