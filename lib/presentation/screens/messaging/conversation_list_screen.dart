import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/messaging/conversation_with_user_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/messaging/messaging_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/messaging/chat_screen.dart';
import 'package:zoneer_mobile/presentation/screens/messaging/widgets/messaging_auth_state.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

enum ConversationFilter { active, unread, ended, all }

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  RealtimeChannel? _conversationsChannel;
  Timer? _refreshDebounce;
  String? _currentUserId;
  ConversationFilter _selectedFilter = ConversationFilter.active;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      _currentUserId = userId;

      ref.read(messagingViewModelProvider.notifier).loadMyConversations(userId);
      _subscribeConversationUpdates(userId);
    });
  }

  void _queueRefresh() {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 200), () {
      ref
          .read(messagingViewModelProvider.notifier)
          .refreshMyConversations(userId);
    });
  }

  void _subscribeConversationUpdates(String userId) {
    _conversationsChannel = Supabase.instance.client
        .channel('conversation_list_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: userId,
          ),
          callback: (_) {
            _queueRefresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'landlord_id',
            value: userId,
          ),
          callback: (_) {
            _queueRefresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: userId,
          ),
          callback: (_) {
            _queueRefresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'landlord_id',
            value: userId,
          ),
          callback: (_) {
            _queueRefresh();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    if (_conversationsChannel != null) {
      Supabase.instance.client.removeChannel(_conversationsChannel!);
    }
    super.dispose();
  }

  List<ConversationWithUserModel> _applyFilter(
      List<ConversationWithUserModel> all) {
    return switch (_selectedFilter) {
      ConversationFilter.active =>
        all
            .where(
              (c) =>
                  c.conversation.status == 'active' ||
                  (c.conversation.status == 'ended' && c.hasUnread),
            )
            .toList(),
      ConversationFilter.unread => all.where((c) => c.hasUnread).toList(),
      ConversationFilter.ended =>
        all.where((c) => c.conversation.status == 'ended').toList(),
      ConversationFilter.all => all,
    };
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}';
    }
  }

  Widget _buildConversationCard(ConversationWithUserModel conversation) {
    final hasUnread = conversation.hasUnread;
    final profileUrl = conversation.otherUser.profileUrl;
    final hasPhoto = profileUrl != null && profileUrl.isNotEmpty;

    final rawTimestamp = conversation.conversation.lastMessageAt;
    DateTime? parsedTime;
    if (rawTimestamp != null) {
      parsedTime = DateTime.tryParse(rawTimestamp);
    }
    final timestampText = _formatTimestamp(parsedTime);

    final propertyLabel =
        conversation.propertyName ?? conversation.propertyAddress ?? '';
    final lastMessage =
        conversation.conversation.lastMessagePreview ?? 'No messages yet';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationData: conversation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: hasPhoto ? NetworkImage(profileUrl) : null,
              child: !hasPhoto
                  ? const Icon(Icons.person_outline, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conversation.otherUser.fullname,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      if (conversation.conversation.status == 'ended') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ended',
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        timestampText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (propertyLabel.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            propertyLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse properties you like, schedule a tour,\nand your conversation with the owner will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(navigationProvider.notifier).changeTab(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Explore Properties',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToStartSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.info_outline, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'How to start a conversation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'To start a conversation, find a property you like and submit a rental inquiry. The owner will be connected with you here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(navigationProvider.notifier).changeTab(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Browse Properties',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      return const MessagingAuthState();
    }

    final conversationAsync = ref.watch(messagingViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHowToStartSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ConversationFilter.values.map((filter) {
                final label = switch (filter) {
                  ConversationFilter.active => 'Active',
                  ConversationFilter.unread => 'Unread',
                  ConversationFilter.ended => 'Ended',
                  ConversationFilter.all => 'All',
                };
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: conversationAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(error.toString())),
              data: (conversations) {
                final filtered = _applyFilter(conversations);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(messagingViewModelProvider);
                    await ref.read(messagingViewModelProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildConversationCard(filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
