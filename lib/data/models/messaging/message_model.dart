class MessageModel {
  final String? id;
  final String conversationId;
  final String senderId;
  final String body;
  final String? createdAt;
  final String? readAt;
  final bool isDeleted;
  final bool isSystem;

  const MessageModel({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.createdAt,
    this.readAt,
    this.isDeleted = false,
    this.isSystem = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String?,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String?,
      readAt: json['read_at'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'read_at': readAt
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }
}
