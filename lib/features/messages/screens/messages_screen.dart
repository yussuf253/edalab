import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/common_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationModel> _conversations = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  Future<void> _loadConversations() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user == null) {
      if (!mounted) return;
      setState(() {
        _conversations = const [];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get(
        '/messages/user/${auth.user!.id}',
        forceRefresh: true,
      );
      final items = (response as List)
          .map(
            (entry) => ConversationModel.fromApi(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn && auth.user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: _isLoading
          ? const SimpleListShimmer(itemCount: 6)
          : !isLoggedIn
          ? EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Login to access messages',
              subtitle:
                  'Your conversations with doctors, providers, and rides will appear here.',
              buttonText: 'Login',
              onButtonPressed: () => context.push('/login'),
            )
          : _conversations.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No conversations yet',
              subtitle:
                  'Start a chat from a doctor, home service provider, or an active ride.',
            )
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _conversations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return GestureDetector(
                    onTap: () =>
                        context.push('/messages/chat/${conversation.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: conversation.accent.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconForEntity(conversation.entityType),
                              color: conversation.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conversation.title,
                                        style: AppTextStyles.labelLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(conversation.lastMessageAt),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conversation.subtitle ??
                                      _subtitleFor(conversation),
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conversation.lastMessage ??
                                            'Start the conversation',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (conversation.unreadCount > 0) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: conversation.accent,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${conversation.unreadCount}',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(color: AppColors.white),
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
                },
              ),
            ),
    );
  }

  IconData _iconForEntity(String entityType) {
    switch (entityType) {
      case 'DOCTOR':
        return Icons.local_hospital_rounded;
      case 'HOME_SERVICE_PROVIDER':
        return Icons.home_repair_service_rounded;
      case 'RIDE':
        return Icons.directions_car_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  String _subtitleFor(ConversationModel conversation) {
    switch (conversation.entityType) {
      case 'DOCTOR':
        return 'Doctor conversation';
      case 'HOME_SERVICE_PROVIDER':
        return 'Home service conversation';
      case 'RIDE':
        return 'Ride conversation';
      default:
        return 'Conversation';
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    final sameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    return sameDay
        ? DateFormat.Hm().format(value)
        : DateFormat.MMMd().format(value);
  }
}
