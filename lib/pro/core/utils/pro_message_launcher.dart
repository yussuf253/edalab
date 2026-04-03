import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';

Future<void> openProConversation(
  BuildContext context, {
  required String customerUserId,
  required String participantUserId,
  required String moduleType,
  required String entityType,
  required String entityId,
  required String title,
  String? subtitle,
  String? avatarUrl,
  String? accentColor,
  Map<String, dynamic>? metadata,
}) async {
  final payload = <String, dynamic>{
    'customerUserId': customerUserId,
    'participantUserId': participantUserId,
    'moduleType': moduleType,
    'entityType': entityType,
    'entityId': entityId,
    'title': title,
    'metadata': metadata ?? const <String, dynamic>{},
  };

  if (subtitle != null && subtitle.trim().isNotEmpty) {
    payload['subtitle'] = subtitle.trim();
  }
  if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
    payload['avatarUrl'] = avatarUrl.trim();
  }
  if (accentColor != null && accentColor.trim().isNotEmpty) {
    payload['accentColor'] = accentColor.trim();
  }

  final response = await ApiClient.post(
    '/messages/pro/conversations/start',
    payload,
  );
  if (!context.mounted) return;
  final conversationId = response['id']?.toString();
  if (conversationId == null || conversationId.isEmpty) return;
  context.push('/pro/messages/chat/$conversationId');
}
