import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_model.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_with_user_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_with_sender_model.dart';
import 'package:zoneer_mobile/data/repositories/messaging_repository.dart';

class MessagingViewmodel
    extends AsyncNotifier<List<ConversationWithUserModel>> {
  @override
  FutureOr<List<ConversationWithUserModel>> build() async => [];

  Future<List<ConversationWithUserModel>> _fetchConversations(String userId) {
    return ref.read(messagingRepositoryProvider).getMyConversations(userId);
  }

  Future<void> loadMyConversations(String userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return _fetchConversations(userId);
    });
  }

  Future<void> refreshMyConversations(String userId) async {
    try {
      final conversations = await _fetchConversations(userId);
      state = AsyncValue.data(conversations);
    } catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    await ref.read(messagingRepositoryProvider).sendMessage(message);
  }

  Future<void> deleteMessage(String messageId) async {
    await ref.read(messagingRepositoryProvider).deleteMessage(messageId);
  }

  Future<void> markConversationRead(
    String conversationId,
    String currentUserId,
  ) async {
    await ref
        .read(messagingRepositoryProvider)
        .markConversationMessagesRead(conversationId, currentUserId);
  }

  Future<void> endConversation({
    required String conversationId,
    required String endedBy,
    required String endedByName,
  }) async {
    await ref.read(messagingRepositoryProvider).endConversation(
      conversationId: conversationId,
      endedBy: endedBy,
      endedByName: endedByName,
    );
    // Update status in-place so the conversation moves to the Ended
    // filter immediately without wiping the whole list.
    if (state.hasValue) {
      final updated = state.value!.map((c) {
        if (c.conversation.id == conversationId) {
          return c.copyWith(
            conversation: c.conversation.copyWith(
              status: 'ended',
              endedBy: endedBy,
            ),
          );
        }
        return c;
      }).toList();
      state = AsyncValue.data(updated);
    }
  }
}

final messagingViewModelProvider =
    AsyncNotifierProvider<MessagingViewmodel, List<ConversationWithUserModel>>(
      MessagingViewmodel.new,
    );

class MessagesNotifier extends AsyncNotifier<List<MessageWithSenderModel>> {
  final String conversationId;

  MessagesNotifier(this.conversationId);

  @override
  Future<List<MessageWithSenderModel>> build() async {
    return ref.read(messagingRepositoryProvider).getMessages(conversationId);
  }

  /// Re-fetches messages without clearing the previous list, so the ListView
  /// stays visible during the refresh (no blank/loading flash).
  Future<void> refresh() async {
    try {
      final updated = await ref
          .read(messagingRepositoryProvider)
          .getMessages(conversationId);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final messagesByConversationProvider = AsyncNotifierProvider.family<
    MessagesNotifier, List<MessageWithSenderModel>, String>(
  (conversationId) => MessagesNotifier(conversationId),
);

final conversationByInquiryIdProvider =
    FutureProvider.family<ConversationModel, String>((ref, inquiryId) async {
      return ref
          .read(messagingRepositoryProvider)
          .getConversationByInquiryId(inquiryId);
    });

final hasAnyUnreadProvider = Provider<bool>((ref) {
  final conversations = ref.watch(messagingViewModelProvider);
  return conversations.maybeWhen(
    data: (list) => list.any((c) => c.hasUnread),
    orElse: () => false,
  );
});
