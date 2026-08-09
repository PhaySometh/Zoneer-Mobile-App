import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/services/supabase_service.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_model.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_with_user_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_with_sender_model.dart';

class MessagingRepository {
  final SupabaseService _supabase;

  const MessagingRepository(this._supabase);

  Future<List<ConversationWithUserModel>> getMyConversations(
    String userId,
  ) async {
    final response = await _supabase
        .from('conversations')
        .select('''
          id,
          inquiry_id,
          property_id,
          tenant_id,
          landlord_id,
          created_at,
          last_message_at,
          last_message_preview,
          status,
          ended_by,
          tenant:users!conversations_tenant_id_fkey(
            id,
            fullname,
            image_profile_url
          ),
          landlord:users!conversations_landlord_id_fkey(
            id,
            fullname,
            image_profile_url
          ),
          property:properties!conversations_property_id_fkey(
            id,
            name,
            address,
            thumbnail_url,
            price
          )
        ''')
        .or('tenant_id.eq.$userId,landlord_id.eq.$userId')
        .order('last_message_at', ascending: false);

    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      return const <ConversationWithUserModel>[];
    }

    final unreadResponse = await _supabase.client.rpc(
      'get_unread_conversation_ids',
      params: {'p_user_id': userId},
    );

    final unreadConversationIds = (unreadResponse as List)
        .map(
          (row) => (row as Map<String, dynamic>)['conversation_id'] as String?,
        )
        .whereType<String>()
        .toSet();

    return rows
        .map(
          (row) => ConversationWithUserModel.fromJoinedJson(
            row,
            userId,
            hasUnread: unreadConversationIds.contains(row['id']),
          ),
        )
        .toList();
  }

  Future<List<MessageWithSenderModel>> getMessages(
    String conversationId,
  ) async {
    final response = await _supabase
        .from('messages')
        .select('''
          id,
          conversation_id,
          sender_id,
          body,
          created_at,
          read_at,
          is_deleted,
          is_system,
          sender:users!messages_sender_id_fkey(
            id,
            fullname,
            image_profile_url
          )
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => MessageWithSenderModel.fromJoinedJson(e))
        .toList();
  }

  Future<void> sendMessage(MessageModel message) async {
    await _supabase.from('messages').insert(message.toJson());
  }

  Future<void> endConversation({
    required String conversationId,
    required String endedBy,
    required String endedByName,
  }) async {
    await _supabase
        .from('conversations')
        .update({'status': 'ended', 'ended_by': endedBy})
        .eq('id', conversationId);
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': endedBy,
      'body': '$endedByName has ended this conversation.',
      'is_system': true,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<void> markConversationMessagesRead(
    String conversationId,
    String currentUserId,
  ) async {
    await _supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .filter('read_at', 'is', null);
  }

  Future<ConversationModel> getConversationByInquiryId(String inquiryId) async {
    final response = await _supabase
        .from('conversations')
        .select('''
          id,
          inquiry_id,
          property_id,
          tenant_id,
          landlord_id,
          created_at,
          last_message_at,
          last_message_preview,
          status,
          ended_by
        ''')
        .eq('inquiry_id', inquiryId)
        .single();

    return ConversationModel.fromJson(response);
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return MessagingRepository(supabase);
});
