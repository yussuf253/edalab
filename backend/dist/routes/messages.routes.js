"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const router = (0, express_1.Router)();
const startConversationSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    moduleType: zod_1.z.nativeEnum(client_1.ModuleType),
    entityType: zod_1.z.nativeEnum(client_1.ConversationEntityType),
    entityId: zod_1.z.string().min(1),
    title: zod_1.z.string().min(1),
    subtitle: zod_1.z.string().optional(),
    avatarUrl: zod_1.z.string().optional(),
    accentColor: zod_1.z.string().optional(),
    metadata: zod_1.z.record(zod_1.z.any()).optional(),
});
const sendMessageSchema = zod_1.z.object({
    senderRole: zod_1.z.nativeEnum(client_1.MessageSenderRole),
    senderLabel: zod_1.z.string().optional(),
    body: zod_1.z.string().min(1).max(1500),
    metadata: zod_1.z.record(zod_1.z.any()).optional(),
});
function serializeConversation(conversation) {
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
function serializeMessage(message) {
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
function buildWelcomeMessage(entityType, title) {
    switch (entityType) {
        case client_1.ConversationEntityType.DOCTOR:
            return {
                senderRole: client_1.MessageSenderRole.PROVIDER,
                senderLabel: title,
                body: 'Hello, how can I help you today?',
            };
        case client_1.ConversationEntityType.HOME_SERVICE_PROVIDER:
            return {
                senderRole: client_1.MessageSenderRole.PROVIDER,
                senderLabel: title,
                body: 'Hi! Tell us what you need at home and we will guide you.',
            };
        case client_1.ConversationEntityType.RIDE:
            return {
                senderRole: client_1.MessageSenderRole.DRIVER,
                senderLabel: title,
                body: 'I am on the way. Message me here if you need anything.',
            };
    }
}
function buildAutoReply(entityType, title) {
    switch (entityType) {
        case client_1.ConversationEntityType.DOCTOR:
            return {
                senderRole: client_1.MessageSenderRole.PROVIDER,
                senderLabel: title,
                body: 'Thanks for your message. I will review it and reply shortly.',
            };
        case client_1.ConversationEntityType.HOME_SERVICE_PROVIDER:
            return {
                senderRole: client_1.MessageSenderRole.PROVIDER,
                senderLabel: title,
                body: 'Thanks. We received your request and will confirm the service details soon.',
            };
        case client_1.ConversationEntityType.RIDE:
            return {
                senderRole: client_1.MessageSenderRole.DRIVER,
                senderLabel: title,
                body: 'Got it. I will keep you updated during the ride.',
            };
    }
}
router.get('/user/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const conversations = await db_1.prisma.conversation.findMany({
        where: { userId },
        orderBy: [{ lastMessageAt: 'desc' }, { updatedAt: 'desc' }],
    });
    res.json(conversations.map(serializeConversation));
}));
router.get('/conversations/:conversationId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const conversationId = (0, http_1.getParam)(req.params.conversationId, 'conversationId');
    const conversation = await db_1.prisma.conversation.findUnique({
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
}));
router.post('/conversations/start', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = startConversationSchema.parse(req.body);
    const existing = await db_1.prisma.conversation.findUnique({
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
    const created = await db_1.prisma.conversation.create({
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
}));
router.post('/conversations/:conversationId/messages', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const conversationId = (0, http_1.getParam)(req.params.conversationId, 'conversationId');
    const body = sendMessageSchema.parse(req.body);
    const conversation = await db_1.prisma.conversation.findUnique({
        where: { id: conversationId },
    });
    if (!conversation) {
        return res.status(404).json({ error: 'Conversation not found.' });
    }
    const userMessage = await db_1.prisma.message.create({
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
    if (body.senderRole === client_1.MessageSenderRole.USER) {
        const reply = buildAutoReply(conversation.entityType, conversation.title);
        const autoReply = await db_1.prisma.message.create({
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
    await db_1.prisma.conversation.update({
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
}));
router.patch('/conversations/:conversationId/read', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const conversationId = (0, http_1.getParam)(req.params.conversationId, 'conversationId');
    await db_1.prisma.message.updateMany({
        where: {
            conversationId,
            senderRole: {
                not: client_1.MessageSenderRole.USER,
            },
            readAt: null,
        },
        data: {
            readAt: new Date(),
        },
    });
    const conversation = await db_1.prisma.conversation.update({
        where: { id: conversationId },
        data: { unreadCount: 0 },
    });
    res.json(serializeConversation(conversation));
}));
exports.default = router;
