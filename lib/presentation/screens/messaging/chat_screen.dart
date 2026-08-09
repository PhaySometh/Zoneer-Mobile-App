import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_with_user_model.dart';
import 'package:zoneer_mobile/data/models/messaging/message_model.dart';
import 'package:zoneer_mobile/presentation/screens/messaging/utils/message_date_formatter.dart';
import 'package:zoneer_mobile/presentation/viewmodels/messaging/messaging_viewmodel.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/presentation/screens/user/user_public_profile_screen.dart';
import 'package:zoneer_mobile/shared/widgets/navigation_back_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ConversationWithUserModel conversationData;

  const ChatScreen({super.key, required this.conversationData});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationChannel;
  int _lastRenderedMessageCount = -1;
  bool _didInitialAutoScroll = false;
  late String _liveStatus;

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _scrollToBottomWhenReady({required bool animated, int retries = 6}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      if (_scrollController.hasClients) {
        _scrollToBottom(animated: animated);
        return;
      }

      if (retries > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        _scrollToBottomWhenReady(animated: animated, retries: retries - 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _liveStatus = widget.conversationData.conversation.status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      if (currentUserId.isNotEmpty) {
        ref
            .read(messagingViewModelProvider.notifier)
            .markConversationRead(widget.conversationData.conversation.id!, currentUserId);
      }

      _messagesChannel = Supabase.instance.client
          .channel('messages_${widget.conversationData.conversation.id!}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: widget.conversationData.conversation.id!,
            ),
            callback: (_) async {
              if (!mounted) {
                return;
              }

              if (currentUserId.isNotEmpty) {
                await ref
                    .read(messagingViewModelProvider.notifier)
                    .markConversationRead(widget.conversationData.conversation.id!, currentUserId);
              }

              if (!mounted) {
                return;
              }

              ref.read(
                messagesByConversationProvider(widget.conversationData.conversation.id!).notifier,
              ).refresh();

              _scrollToBottomWhenReady(animated: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: widget.conversationData.conversation.id!,
            ),
            callback: (_) {
              if (!mounted) {
                return;
              }

              ref.read(
                messagesByConversationProvider(widget.conversationData.conversation.id!).notifier,
              ).refresh();
            },
          )
          .subscribe();

      _conversationChannel = Supabase.instance.client
          .channel('conv_status_${widget.conversationData.conversation.id!}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'conversations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: widget.conversationData.conversation.id!,
            ),
            callback: (payload) {
              if (!mounted) return;
              final newStatus = payload.newRecord['status'] as String?;
              if (newStatus != null && newStatus != _liveStatus) {
                setState(() => _liveStatus = newStatus);
                ref.invalidate(
                  messagesByConversationProvider(widget.conversationData.conversation.id!),
                );
              }
            },
          )
          .subscribe();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_messagesChannel != null) {
      Supabase.instance.client.removeChannel(_messagesChannel!);
    }
    if (_conversationChannel != null) {
      Supabase.instance.client.removeChannel(_conversationChannel!);
    }
    super.dispose();
  }

  void _showDeleteOptions(BuildContext context, MessageModel msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMessage(context, msg);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context, MessageModel msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Delete this message? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(messagingViewModelProvider.notifier)
                  .deleteMessage(msg.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmEndConversation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End conversation'),
        content: const Text(
          "End this conversation? Neither party will be able to send new messages.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endConversation();
            },
            child: const Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _endConversation() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (currentUserId.isEmpty) return;

    // Get current user's name for the system message
    String userName = 'Someone';
    try {
      final user = await ref.read(userByIdProvider(currentUserId).future);
      userName = user.fullname;
    } catch (_) {}

    await ref.read(messagingViewModelProvider.notifier).endConversation(
      conversationId: widget.conversationData.conversation.id!,
      endedBy: currentUserId,
      endedByName: userName,
    );
    if (mounted) setState(() => _liveStatus = 'ended');
    // Refresh the chat messages to show system message
    ref.read(messagesByConversationProvider(widget.conversationData.conversation.id!).notifier).refresh();
  }

  Future<void> _sendMessage(String currentUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId.isEmpty) {
      return;
    }

    await ref
        .read(messagingViewModelProvider.notifier)
        .sendMessage(
          MessageModel(
            conversationId: widget.conversationData.conversation.id!,
            senderId: currentUserId,
            body: text,
          ),
        );

    _messageController.clear();
    ref.read(messagesByConversationProvider(widget.conversationData.conversation.id!).notifier).refresh();
    _scrollToBottomWhenReady(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final messagesAsync = ref.watch(
      messagesByConversationProvider(widget.conversationData.conversation.id!),
    );
    final liveStatus = _liveStatus;

    return Scaffold(
      body: SafeArea(
        child: messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (messages) {
          if (messages.isNotEmpty &&
              messages.length != _lastRenderedMessageCount) {
            final isInitialLoad = !_didInitialAutoScroll;
            _lastRenderedMessageCount = messages.length;
            _didInitialAutoScroll = true;
            _scrollToBottomWhenReady(animated: !isInitialLoad);
          }

            final otherUser = widget.conversationData.otherUser;

            return Column(
              children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    NavigationBackButton(),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPublicProfileScreen(userId: otherUser.id),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: (otherUser.profileUrl?.isNotEmpty == true)
                                ? NetworkImage(otherUser.profileUrl!)
                                : null,
                            backgroundColor: const Color(0xFFE9E9E9),
                            child: (otherUser.profileUrl == null || otherUser.profileUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 18, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUser.fullname,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Tap to view profile',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (liveStatus == 'active')
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black54),
                        onSelected: (value) {
                          if (value == 'end') _confirmEndConversation(context);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'end',
                            child: Text('End conversation', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Property summary card
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.conversationData.propertyThumbnail?.isNotEmpty == true)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.conversationData.propertyThumbnail!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.conversationData.propertyName ??
                                widget.conversationData.propertyAddress ??
                                'Property',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.conversationData.propertyPrice != null)
                            Text(
                              '\$${widget.conversationData.propertyPrice!.toStringAsFixed(0)} / mo',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (widget.conversationData.propertyAddress != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    widget.conversationData.propertyAddress!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          const Text(
                            'This user wants to rent this property',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final item = messages[index];
                    final msg = item.message;
                    final previousMessage = index > 0
                        ? messages[index - 1].message
                        : null;
                    final showDayHeader =
                        index == 0 ||
                        MessageDateFormatter.isDifferentDay(
                          msg.createdAt,
                          previousMessage?.createdAt,
                        );
                    final isMe = msg.senderId == currentUserId;

                    return Column(
                      children: [
                        if (showDayHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  MessageDateFormatter.formatDayHeader(
                                    msg.createdAt,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (msg.isSystem)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg.body,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          )
                        else if (msg.isDeleted)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 4,
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                isMe
                                    ? 'You deleted a message'
                                    : '${item.sender.fullname} deleted a message',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onLongPress: (msg.senderId == currentUserId &&
                                    !msg.isDeleted &&
                                    !msg.isSystem)
                                ? () => _showDeleteOptions(context, msg)
                                : null,
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft:
                                            Radius.circular(isMe ? 16 : 0),
                                        bottomRight:
                                            Radius.circular(isMe ? 0 : 16),
                                      ),
                                    ),
                                    child: Text(
                                      msg.body,
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),

                                  /// Time + Read status
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        MessageDateFormatter.formatMessageTime(
                                          msg.createdAt,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 5),
                                        Icon(
                                          msg.readAt != null
                                              ? Icons.done_all
                                              : Icons.check,
                                          size: 14,
                                          color: msg.readAt != null
                                              ? AppColors.primary
                                              : Colors.grey,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              /// Input field
              if (liveStatus == 'ended')
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: const Center(
                    child: Text(
                      'This conversation has ended',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          onPressed: () => _sendMessage(currentUserId),
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
