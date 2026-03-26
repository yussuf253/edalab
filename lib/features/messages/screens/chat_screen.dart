import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  ConversationModel? _conversation;
  List<ChatMessageModel> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final response = await ApiClient.get(
        '/messages/conversations/${widget.conversationId}',
        forceRefresh: true,
      );
      final data = Map<String, dynamic>.from(response as Map);
      if (!mounted) return;
      setState(() {
        _conversation = ConversationModel.fromApi(data);
        _messages = (data['messages'] as List? ?? const [])
            .map(
              (entry) => ChatMessageModel.fromApi(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
        _isLoading = false;
      });
      await ApiClient.patch(
        '/messages/conversations/${widget.conversationId}/read',
        {},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final auth = context.read<AuthProvider>();
    final text = _messageController.text.trim();
    if (text.isEmpty || auth.user == null) return;

    setState(() => _isSending = true);
    try {
      await ApiClient.post(
        '/messages/conversations/${widget.conversationId}/messages',
        {
          'senderRole': 'USER',
          'senderLabel': auth.user!.fullName,
          'body': text,
        },
      );
      _messageController.clear();
      await _loadConversation();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(conversation?.title ?? 'Chat')),
      body: _isLoading
          ? const SimpleListShimmer(itemCount: 6)
          : Column(
              children: [
                if (conversation != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: conversation.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconForEntity(conversation.entityType),
                            color: conversation.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conversation.title,
                                style: AppTextStyles.labelLarge,
                              ),
                              Text(
                                conversation.subtitle ?? 'Conversation',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.isMine;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isMine ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: isMine ? null : AppSpacing.shadowSm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMine &&
                                  (message.senderLabel ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    message.senderLabel!,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color:
                                          conversation?.accent ??
                                          AppColors.primary,
                                    ),
                                  ),
                                ),
                              Text(
                                message.body,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isMine
                                      ? AppColors.white
                                      : AppColors.dark,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(message.createdAt),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.mediumGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    return DateFormat.Hm().format(value);
  }
}
