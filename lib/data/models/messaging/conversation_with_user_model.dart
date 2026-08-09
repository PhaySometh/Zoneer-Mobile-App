import 'package:zoneer_mobile/data/models/messaging/chat_user_model.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_model.dart';

class ConversationWithUserModel {
  final ConversationModel conversation;
  final ChatUserModel otherUser;
  final bool hasUnread;
  final String? propertyName;
  final String? propertyAddress;
  final String? propertyThumbnail;
  final double? propertyPrice;

  const ConversationWithUserModel({
    required this.conversation,
    required this.otherUser,
    this.hasUnread = false,
    this.propertyName,
    this.propertyAddress,
    this.propertyThumbnail,
    this.propertyPrice,
  });

  factory ConversationWithUserModel.fromJoinedJson(
    Map<String, dynamic> json,
    String currentUserId, {
    bool hasUnread = false,
  }) {
    final conversation = ConversationModel.fromJson(json);

    final tenantJson = json['tenant'] as Map<String, dynamic>?;
    final landlordJson = json['landlord'] as Map<String, dynamic>?;

    final tenant = tenantJson != null
        ? ChatUserModel.fromJson(tenantJson)
        : ChatUserModel(id: conversation.tenantId, fullname: 'Unknown');
    final landlord = landlordJson != null
        ? ChatUserModel.fromJson(landlordJson)
        : ChatUserModel(id: conversation.landlordId, fullname: 'Unknown');

    final otherUser = tenant.id == currentUserId ? landlord : tenant;

    return ConversationWithUserModel(
      conversation: conversation,
      otherUser: otherUser,
      hasUnread: hasUnread,
      propertyName:
          (json['property'] as Map<String, dynamic>?)?['name'] as String?,
      propertyAddress:
          (json['property'] as Map<String, dynamic>?)?['address'] as String?,
      propertyThumbnail:
          (json['property'] as Map<String, dynamic>?)?['thumbnail_url'] as String?,
      propertyPrice:
          ((json['property'] as Map<String, dynamic>?)?['price'] as num?)
              ?.toDouble(),
    );
  }

  ConversationWithUserModel copyWith({
    ConversationModel? conversation,
    ChatUserModel? otherUser,
    bool? hasUnread,
    String? propertyName,
    String? propertyAddress,
    String? propertyThumbnail,
    double? propertyPrice,
  }) {
    return ConversationWithUserModel(
      conversation: conversation ?? this.conversation,
      otherUser: otherUser ?? this.otherUser,
      hasUnread: hasUnread ?? this.hasUnread,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyThumbnail: propertyThumbnail ?? this.propertyThumbnail,
      propertyPrice: propertyPrice ?? this.propertyPrice,
    );
  }
}
