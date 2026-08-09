import 'package:zoneer_mobile/data/models/messaging/chat_user_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_model.dart';

class MessageWithSenderModel {
  final MessageModel message;
  final ChatUserModel sender;

  const MessageWithSenderModel({required this.message, required this.sender});

  factory MessageWithSenderModel.fromJoinedJson(Map<String, dynamic> json) {
    final message = MessageModel.fromJson(json);
    final senderJson = json['sender'] as Map<String, dynamic>?;

    final sender = senderJson != null
        ? ChatUserModel.fromJson(senderJson)
        : ChatUserModel(id: message.senderId, fullname: 'Unknown');

    return MessageWithSenderModel(message: message, sender: sender);
  }
}
