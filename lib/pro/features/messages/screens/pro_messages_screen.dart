import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_shimmer.dart';
import 'package:provider/provider.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/utils/pro_module_helper.dart';

class ProMessagesScreen extends StatefulWidget {
  final ProProfile profile;

  const ProMessagesScreen({super.key, required this.profile});

  @override
  State<ProMessagesScreen> createState() => _ProMessagesScreenState();
}

class _ProMessagesScreenState extends State<ProMessagesScreen> {
  List<ConversationModel> _conversations = const [];
  bool _isLoading = true;

  bool get _supportsLiveInbox =>
      widget.profile.type == ProProfileType.shop ||
      widget.profile.type == ProProfileType.provider ||
      widget.profile.type == ProProfileType.doctor ||
      widget.profile.type == ProProfileType.delivery ||
      widget.profile.type == ProProfileType.rider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  void didUpdateWidget(covariant ProMessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.userId != widget.profile.userId ||
        oldWidget.profile.type != widget.profile.type) {
      setState(() => _isLoading = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
    }
  }

  Future<void> _loadConversations() async {
    if (!_supportsLiveInbox) {
      context.read<ProAuthProvider>().updateUnreadInboxCount(0);
      if (!mounted) return;
      setState(() {
        _conversations = const [];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get(
        '/messages/pro/${widget.profile.userId}',
        forceRefresh: true,
      );
      final items = (response as List)
          .map(
            (entry) => ConversationModel.fromApi(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
      final unreadTotal = items.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadCount,
      );
      if (mounted) {
        context.read<ProAuthProvider>().updateUnreadInboxCount(unreadTotal);
      }
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        context.read<ProAuthProvider>().refreshInboxSummary(forceRefresh: true);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ProModuleHelper.getProfileColor(widget.profile.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inbox'),
        elevation: 0,
        backgroundColor: accent,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const SimpleListShimmer(itemCount: 6)
          : !_supportsLiveInbox
          ? _ProMessagesPlaceholder(
              title: 'Inbox is coming next for this profile',
              subtitle:
                  'Two-way customer chat is now live for doctor, provider, delivery, and rider roles. Store messaging can plug into the same flow next.',
              icon: Icons.forum_outlined,
              color: accent,
            )
          : _conversations.isEmpty
          ? _ProMessagesPlaceholder(
              title: 'No active conversations yet',
              subtitle:
                  'Customer messages from assigned deliveries and rides will appear here as soon as they start a chat.',
              icon: Icons.chat_bubble_outline_rounded,
              color: accent,
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
                    onTap: () async {
                      await context.push(
                        '/pro/messages/chat/${conversation.id}',
                      );
                      if (!mounted) return;
                      await _loadConversations();
                    },
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
                                Text(
                                  conversation.title,
                                  style: AppTextStyles.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conversation.subtitle ?? 'Customer message',
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  conversation.lastMessage ??
                                      'Open the conversation',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
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
      case 'SHOP':
        return Icons.storefront_rounded;
      case 'DOCTOR':
        return Icons.local_hospital_rounded;
      case 'HOME_SERVICE_PROVIDER':
        return Icons.home_repair_service_rounded;
      case 'DELIVERY':
        return Icons.local_shipping_rounded;
      case 'RIDE':
        return Icons.directions_car_rounded;
      default:
        return Icons.chat_rounded;
    }
  }
}

class _ProMessagesPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ProMessagesPlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 18),
            Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
