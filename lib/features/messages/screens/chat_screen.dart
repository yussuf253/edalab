import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final bool isProView;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.isProView = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ConversationModel? _conversation;
  List<ChatMessageModel> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRefreshingConversation = false;
  bool _hasLoadError = false;
  int _consecutiveFailures = 0;
  Timer? _liveRefreshTimer;
  NotificationProvider? _notificationProvider;
  Set<String> _seenNotificationIds = const <String>{};

  /// Poll cadence backs off when the backend is unreachable so an offline
  /// device doesn't fire a force-refresh every 5 seconds indefinitely.
  static const Duration _basePollInterval = Duration(seconds: 5);
  static const Duration _maxPollInterval = Duration(seconds: 60);

  Duration get _currentPollInterval {
    final backoffFactor = 1 << _consecutiveFailures.clamp(0, 4);
    final scaled = _basePollInterval * backoffFactor;
    return scaled > _maxPollInterval ? _maxPollInterval : scaled;
  }

  String? _actorUserId(BuildContext context) {
    return context.read<AuthProvider>().user?.id;
  }

  String _senderRole(BuildContext context) {
    return 'USER';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversation();
    _startLiveRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotificationProvider>();
    if (identical(_notificationProvider, provider)) {
      return;
    }

    _notificationProvider?.removeListener(_handleNotificationsChanged);
    _notificationProvider = provider;
    _seenNotificationIds = provider.notifications
        .map((item) => item.id)
        .toSet();
    provider.addListener(_handleNotificationsChanged);
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _loadConversation();
      _startLiveRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLiveRefresh();
      _refreshConversationSilently();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _liveRefreshTimer?.cancel();
    }
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    // One-shot timer chain (rather than a periodic timer) so each tick can
    // re-evaluate the backoff cadence after failures or successes.
    _liveRefreshTimer = Timer(_currentPollInterval, () {
      if (!mounted) return;
      _refreshConversationSilently();
      _startLiveRefresh();
    });
  }

  bool _isMessageNotificationForCurrentConversation(
    AppNotificationModel notification,
  ) {
    final conversationId = notification.metadata['conversationId']
        ?.toString()
        .trim();
    if (conversationId == widget.conversationId) {
      return true;
    }

    final route = notification.route?.trim() ?? '';
    return route == '/messages/chat/${widget.conversationId}';
  }

  void _handleNotificationsChanged() {
    final provider = _notificationProvider;
    if (provider == null) return;

    final notifications = provider.notifications;
    final currentIds = notifications.map((item) => item.id).toSet();
    final hasRelevantUpdate = notifications.any(
      (notification) =>
          !_seenNotificationIds.contains(notification.id) &&
          _isMessageNotificationForCurrentConversation(notification),
    );
    _seenNotificationIds = currentIds;

    if (hasRelevantUpdate) {
      _refreshConversationSilently();
    }
  }

  void _refreshConversationSilently() {
    if (!mounted || _isSending) return;
    unawaited(_loadConversation(showLoader: false));
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
      return;
    }
    _scrollController.jumpTo(target);
  }

  Future<void> _loadConversation({bool showLoader = true}) async {
    if (_isRefreshingConversation) return;
    _isRefreshingConversation = true;

    if (showLoader && mounted && _conversation == null) {
      setState(() => _isLoading = true);
    }

    try {
      final actorUserId = _actorUserId(context);
      final response = await ApiClient.get(
        '/messages/conversations/${widget.conversationId}',
        forceRefresh: true,
      );
      final data = Map<String, dynamic>.from(response as Map);
      final nextConversation = ConversationModel.fromApi(data);
      final nextMessages = (data['messages'] as List? ?? const [])
          .map(
            (entry) => ChatMessageModel.fromApi(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
      final previousLastMessageId = _messages.isNotEmpty
          ? _messages.last.id
          : null;
      final nextLastMessageId = nextMessages.isNotEmpty
          ? nextMessages.last.id
          : null;
      final shouldMarkRead =
          actorUserId != null && nextConversation.unreadCount > 0;

      if (!mounted) return;
      setState(() {
        _conversation = nextConversation;
        _messages = nextMessages;
        _isLoading = false;
        _hasLoadError = false;
        _consecutiveFailures = 0;
      });

      if (nextLastMessageId != null &&
          nextLastMessageId != previousLastMessageId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToBottom(animated: previousLastMessageId != null);
        });
      }

      if (shouldMarkRead) {
        await ApiClient.patch(
          '/messages/conversations/${widget.conversationId}/read',
          {'actorUserId': actorUserId},
        );
      }
    } catch (_) {
      _consecutiveFailures += 1;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Only surface a full error state when we have nothing to show;
        // otherwise keep the last good transcript visible.
        if (_conversation == null) {
          _hasLoadError = true;
        }
      });
    } finally {
      _isRefreshingConversation = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final actorUserId = _actorUserId(context);
    if (text.isEmpty || actorUserId == null) return;

    setState(() => _isSending = true);
    try {
      final senderLabel = context.read<AuthProvider>().user?.fullName ?? 'User';
      await ApiClient.post(
        '/messages/conversations/${widget.conversationId}/messages',
        {
          'actorUserId': actorUserId,
          'senderRole': _senderRole(context),
          'senderLabel': senderLabel,
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
    WidgetsBinding.instance.removeObserver(this);
    _liveRefreshTimer?.cancel();
    _notificationProvider?.removeListener(_handleNotificationsChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conversation = _conversation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          conversation?.title ?? l10n.t('messages.chat_fallback_title'),
        ),
      ),
      body: _isLoading
          ? const SimpleListShimmer(itemCount: 6)
          : _hasLoadError && conversation == null
          ? _buildErrorView(l10n)
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
                    controller: _scrollController,
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
                          decoration: InputDecoration(
                            hintText: l10n.t('messages.type_message'),
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
      case 'SHOP':
        return Icons.storefront_rounded;
      case 'DELIVERY':
        return Icons.local_shipping_rounded;
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

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('no_internet.title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadConversation();
              },
              child: Text(l10n.t('tracking.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
