import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../network/api_client.dart';
import '../providers/providers.dart';
import 'auth_gate.dart';

Future<void> openConversation(
  BuildContext context, {
  required String moduleType,
  required String entityType,
  required String entityId,
  required String title,
  String? subtitle,
  String? avatarUrl,
  String? accentColor,
  Map<String, dynamic>? metadata,
}) async {
  final allowed = await requireLoggedIn(
    context,
    message: 'Please log in to send messages.',
  );
  if (!context.mounted || !allowed) return;

  final auth = context.read<AuthProvider>();
  final payload = <String, dynamic>{
    'userId': auth.user!.id,
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

  final response = await ApiClient.post('/messages/conversations/start', payload);

  if (!context.mounted) return;
  final conversationId = response['id']?.toString();
  if (conversationId == null || conversationId.isEmpty) return;
  context.push('/messages/chat/$conversationId');
}
