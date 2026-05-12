import 'package:flutter/material.dart';

class ConversationModel {
  final String id;
  final String userId;
  final String moduleType;
  final String entityType;
  final String entityId;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final String? accentColor;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final Map<String, dynamic> metadata;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.moduleType,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.accentColor,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.metadata = const {},
  });

  factory ConversationModel.fromApi(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      moduleType: json['moduleType']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conversation',
      subtitle: json['subtitle']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      accentColor: json['accentColor']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(json['lastMessageAt'].toString()),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  Color get accent {
    final hex = (accentColor ?? '#6C63FF').replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16) ?? 0xFF6C63FF;
    return Color(value);
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderRole;
  final String? senderLabel;
  final String body;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.body,
    this.senderLabel,
    this.createdAt,
    this.metadata = const {},
  });

  factory ChatMessageModel.fromApi(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'SYSTEM',
      senderLabel: json['senderLabel']?.toString(),
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  bool get isMine => senderRole == 'USER';
}
