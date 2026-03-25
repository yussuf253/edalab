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
  final response = await ApiClient.post('/messages/conversations/start', {
    'userId': auth.user!.id,
    'moduleType': moduleType,
    'entityType': entityType,
    'entityId': entityId,
    'title': title,
    'subtitle': subtitle,
    'avatarUrl': avatarUrl,
    'accentColor': accentColor,
    'metadata': metadata ?? const <String, dynamic>{},
  });

  if (!context.mounted) return;
  final conversationId = response['id']?.toString();
  if (conversationId == null || conversationId.isEmpty) return;
  context.push('/messages/chat/$conversationId');
}
