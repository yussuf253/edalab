import {
  ConversationEntityType,
  MessageSenderRole,
  ModuleType,
} from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';

const router = Router();

const startConversationSchema = z.object({
  userId: z.string().min(1),
  moduleType: z.nativeEnum(ModuleType),
  entityType: z.nativeEnum(ConversationEntityType),
  entityId: z.string().min(1),
  title: z.string().min(1),
  subtitle: z.string().optional(),
  avatarUrl: z.string().optional(),
  accentColor: z.string().optional(),
  metadata: z.record(z.any()).optional(),
});

const sendMessageSchema = z.object({
  senderRole: z.nativeEnum(MessageSenderRole),
  senderLabel: z.string().optional(),
  body: z.string().min(1).max(1500),
  metadata: z.record(z.any()).optional(),
});

function serializeConversation(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findMany>>[number],
) {
  return {
    id: conversation.id,
    userId: conversation.userId,
    moduleType: conversation.moduleType,
    entityType: conversation.entityType,
    entityId: conversation.entityId,
    title: conversation.title,
    subtitle: conversation.subtitle,
    avatarUrl: conversation.avatarUrl,
    accentColor: conversation.accentColor,
    status: conversation.status,
    unreadCount: conversation.unreadCount,
    lastMessage: conversation.lastMessage,
    lastMessageAt: conversation.lastMessageAt,
    metadata: conversation.metadata,
    createdAt: conversation.createdAt,
    updatedAt: conversation.updatedAt,
  };
}

function serializeMessage(
  message: Awaited<ReturnType<typeof prisma.message.findMany>>[number],
) {
  return {
    id: message.id,
    conversationId: message.conversationId,
    senderRole: message.senderRole,
    senderLabel: message.senderLabel,
    body: message.body,
    metadata: message.metadata,
    readAt: message.readAt,
    createdAt: message.createdAt,
  };
}

function buildWelcomeMessage(
  entityType: ConversationEntityType,
  title: string,
): { senderRole: MessageSenderRole; senderLabel: string; body: string } {
  switch (entityType) {
    case ConversationEntityType.DOCTOR:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Hello, how can I help you today?',
      };
    case ConversationEntityType.HOME_SERVICE_PROVIDER:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Hi! Tell us what you need at home and we will guide you.',
      };
    case ConversationEntityType.RIDE:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'I am on the way. Message me here if you need anything.',
      };
  }
}

function buildAutoReply(
  entityType: ConversationEntityType,
  title: string,
): { senderRole: MessageSenderRole; senderLabel: string; body: string } {
  switch (entityType) {
    case ConversationEntityType.DOCTOR:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Thanks for your message. I will review it and reply shortly.',
      };
    case ConversationEntityType.HOME_SERVICE_PROVIDER:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Thanks. We received your request and will confirm the service details soon.',
      };
    case ConversationEntityType.RIDE:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'Got it. I will keep you updated during the ride.',
      };
  }
}

router.get(
  '/user/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const conversations = await prisma.conversation.findMany({
      where: { userId },
      orderBy: [{ lastMessageAt: 'desc' }, { updatedAt: 'desc' }],
    });

    res.json(conversations.map(serializeConversation));
  }),
);

router.get(
  '/conversations/:conversationId',
  asyncHandler(async (req, res) => {
    const conversationId = getParam(
      req.params.conversationId,
      'conversationId',
    );
    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found.' });
    }

    res.json({
      ...serializeConversation(conversation),
      messages: conversation.messages.map(serializeMessage),
    });
  }),
);

router.post(
  '/conversations/start',
  asyncHandler(async (req, res) => {
    const body = startConversationSchema.parse(req.body);
    const existing = await prisma.conversation.findUnique({
      where: {
        userId_entityType_entityId: {
          userId: body.userId,
          entityType: body.entityType,
          entityId: body.entityId,
        },
      },
    });

    if (existing) {
      return res.json(serializeConversation(existing));
    }

    const welcome = buildWelcomeMessage(body.entityType, body.title);
    const created = await prisma.conversation.create({
      data: {
        userId: body.userId,
        moduleType: body.moduleType,
        entityType: body.entityType,
        entityId: body.entityId,
        title: body.title,
        subtitle: body.subtitle ?? null,
        avatarUrl: body.avatarUrl ?? null,
        accentColor: body.accentColor ?? null,
        metadata: body.metadata ?? undefined,
        lastMessage: welcome.body,
        lastMessageAt: new Date(),
        unreadCount: 1,
        messages: {
          create: {
            senderRole: welcome.senderRole,
            senderLabel: welcome.senderLabel,
            body: welcome.body,
          },
        },
      },
    });

    res.status(201).json(serializeConversation(created));
  }),
);

router.post(
  '/conversations/:conversationId/messages',
  asyncHandler(async (req, res) => {
    const conversationId = getParam(
      req.params.conversationId,
      'conversationId',
    );
    const body = sendMessageSchema.parse(req.body);

    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found.' });
    }

    const userMessage = await prisma.message.create({
      data: {
        conversationId,
        senderRole: body.senderRole,
        senderLabel: body.senderLabel ?? null,
        body: body.body.trim(),
        metadata: body.metadata ?? undefined,
      },
    });

    let unreadCount = conversation.unreadCount;
    let lastMessage = userMessage.body;
    let lastMessageAt = userMessage.createdAt;

    if (body.senderRole === MessageSenderRole.USER) {
      const reply = buildAutoReply(conversation.entityType, conversation.title);
      const autoReply = await prisma.message.create({
        data: {
          conversationId,
          senderRole: reply.senderRole,
          senderLabel: reply.senderLabel,
          body: reply.body,
        },
      });
      unreadCount += 1;
      lastMessage = autoReply.body;
      lastMessageAt = autoReply.createdAt;
    }

    await prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessage,
        lastMessageAt,
        unreadCount,
      },
    });

    res.status(201).json({
      sent: serializeMessage(userMessage),
      lastMessage,
      lastMessageAt,
      unreadCount,
    });
  }),
);

router.patch(
  '/conversations/:conversationId/read',
  asyncHandler(async (req, res) => {
    const conversationId = getParam(
      req.params.conversationId,
      'conversationId',
    );

    await prisma.message.updateMany({
      where: {
        conversationId,
        senderRole: {
          not: MessageSenderRole.USER,
        },
        readAt: null,
      },
      data: {
        readAt: new Date(),
      },
    });

    const conversation = await prisma.conversation.update({
      where: { id: conversationId },
      data: { unreadCount: 0 },
    });

    res.json(serializeConversation(conversation));
  }),
);

export default router;
