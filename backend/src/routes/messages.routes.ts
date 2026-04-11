import {
  AppointmentStatus,
  ConversationEntityType,
  MessageSenderRole,
  ModuleType,
  ProProfileType,
} from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../db';
import { createMessageNotification } from '../utils/notifications';
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

const startProConversationSchema = z.object({
  customerUserId: z.string().min(1),
  participantUserId: z.string().min(1),
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
  actorUserId: z.string().optional(),
  senderRole: z.nativeEnum(MessageSenderRole),
  senderLabel: z.string().optional(),
  body: z.string().min(1).max(1500),
  metadata: z.record(z.any()).optional(),
});

const readConversationSchema = z.object({
  actorUserId: z.string().optional(),
});

type ViewerType = 'user' | 'participant';

function formatFullName(user: {
  firstName?: string | null;
  lastName?: string | null;
}) {
  const fullName = [user.firstName, user.lastName]
    .map((part) => part?.trim() ?? '')
    .filter((part) => part.length > 0)
    .join(' ')
    .trim();
  return fullName.length > 0 ? fullName : 'Customer';
}

function metadataRecord(value: unknown) {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function bindingIds(value: unknown, key: string) {
  const metadata = metadataRecord(value);
  const raw = metadata[key];
  if (!Array.isArray(raw)) return [];
  return raw
    .map((entry) => entry?.toString() ?? '')
    .filter((entry) => entry.length > 0);
}

function normalizedText(value: string) {
  return value.trim().toLowerCase();
}

function moduleLabel(moduleType: ModuleType) {
  switch (moduleType) {
    case ModuleType.FOOD:
      return 'Food';
    case ModuleType.SHOPPING:
      return 'Shopping';
    case ModuleType.PHARMACY:
      return 'Pharmacy';
    case ModuleType.RIDE:
      return 'Ride';
    case ModuleType.HOME_SERVICES:
      return 'Home services';
    case ModuleType.HOUSE_HELP:
      return 'House help';
    case ModuleType.DOCTOR:
      return 'Doctor';
    case ModuleType.LAUNDRY:
      return 'Laundry';
    case ModuleType.GROCERY:
      return 'Grocery';
    case ModuleType.HOTEL:
      return 'Hotel';
  }

  return 'Service';
}

function proConversationSubtitle(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findMany>>[number],
) {
  const metadata = metadataRecord(conversation.metadata);
  switch (conversation.entityType) {
    case ConversationEntityType.DELIVERY:
      return `${moduleLabel(conversation.moduleType)} order #${conversation.entityId.slice(-6).toUpperCase()}`;
    case ConversationEntityType.RIDE: {
      const destination = metadata.destination?.toString().trim();
      return destination != null && destination.length > 0
        ? `Ride to ${destination}`
        : `Ride #${conversation.entityId.slice(-6).toUpperCase()}`;
    }
    case ConversationEntityType.DOCTOR: {
      const specialty = metadata.specialty?.toString().trim();
      return specialty != null && specialty.length > 0
        ? `Consultation • ${specialty}`
        : `Appointment #${conversation.entityId.slice(-6).toUpperCase()}`;
    }
    case ConversationEntityType.HOME_SERVICE_PROVIDER: {
      const categorySlug = metadata.categorySlug?.toString().trim();
      if (categorySlug != null && categorySlug.length > 0) {
        return categorySlug
          .replaceAll('-', ' ')
          .replaceAll('_', ' ')
          .split(' ')
          .filter((part) => part.length > 0)
          .map((part) => part[0].toUpperCase() + part.slice(1))
          .join(' ');
      }
      return `Service request #${conversation.entityId.slice(-6).toUpperCase()}`;
    }
    case ConversationEntityType.SHOP: {
      const merchantName =
        metadata.merchantName?.toString().trim() ?? conversation.title;
      return `${moduleLabel(conversation.moduleType)} • ${merchantName}`;
    }
    default:
      return conversation.subtitle ?? moduleLabel(conversation.moduleType);
  }
}

async function findBoundParticipantProfile(
  type: ProProfileType,
  bindingKey: string,
  entityId: string,
) {
  const profiles = await prisma.proProfile.findMany({
    where: { type },
    select: {
      userId: true,
      businessName: true,
      bindings: true,
    },
  });

  const match = profiles.find((profile) =>
    bindingIds(profile.bindings, bindingKey).includes(entityId),
  );

  return match ?? null;
}

async function findBoundShopProfileByPharmacyBusiness(entityId: string) {
  const profiles = await prisma.proProfile.findMany({
    where: { type: ProProfileType.SHOP },
    select: {
      userId: true,
      businessName: true,
      bindings: true,
    },
  });

  const target = normalizedText(entityId);
  const match = profiles.find((profile) =>
    bindingIds(profile.bindings, 'pharmacyBusinesses').some(
      (entry) => normalizedText(entry) == target,
    ),
  );

  return match ?? null;
}

function serializeConversationForViewer(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findMany>>[number],
  viewer: ViewerType,
) {
  const metadata = metadataRecord(conversation.metadata);
  const participantTitle =
    metadata.customerName?.toString().trim() ?? conversation.title;
  const participantSubtitle = proConversationSubtitle(conversation);

  return {
    id: conversation.id,
    userId: conversation.userId,
    participantUserId: conversation.participantUserId,
    moduleType: conversation.moduleType,
    entityType: conversation.entityType,
    entityId: conversation.entityId,
    title: viewer == 'participant' ? participantTitle : conversation.title,
    subtitle:
      viewer == 'participant'
        ? participantSubtitle
        : conversation.subtitle,
    avatarUrl: conversation.avatarUrl,
    accentColor: conversation.accentColor,
    status: conversation.status,
    unreadCount:
      viewer == 'participant'
        ? conversation.participantUnreadCount
        : conversation.userUnreadCount,
    lastMessage: conversation.lastMessage,
    lastMessageAt: conversation.lastMessageAt,
    metadata,
    createdAt: conversation.createdAt,
    updatedAt: conversation.updatedAt,
  };
}

function serializeConversation(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findMany>>[number],
) {
  return serializeConversationForViewer(conversation, 'user');
}

function serializeMessage(
  message: Awaited<ReturnType<typeof prisma.message.findMany>>[number],
) {
  return {
    id: message.id,
    conversationId: message.conversationId,
    senderUserId: message.senderUserId,
    senderRole: message.senderRole,
    senderLabel: message.senderLabel,
    body: message.body,
    metadata: message.metadata,
    readAt: message.readAt,
    createdAt: message.createdAt,
  };
}

function notificationTitleForParticipant(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findUnique>>,
) {
  if (!conversation) return 'New customer message';
  const metadata = metadataRecord(conversation.metadata);
  const customerName = metadata.customerName?.toString().trim();
  if (customerName != null && customerName.length > 0) {
    return customerName;
  }
  return 'New customer message';
}

function notificationTitleForUser(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findUnique>>,
) {
  if (!conversation) return 'New message';
  const participantName = metadataRecord(conversation.metadata).participantName
    ?.toString()
    .trim();
  if (participantName != null && participantName.length > 0) {
    return participantName;
  }
  return conversation.title;
}

async function resolveConversationParticipant({
  userId,
  entityType,
  entityId,
  moduleType,
  metadata,
}: {
  userId: string;
  entityType: ConversationEntityType;
  entityId: string;
  moduleType: ModuleType;
  metadata?: Record<string, unknown>;
}) {
  switch (entityType) {
    case ConversationEntityType.SHOP: {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          phone: true,
        },
      });

      if (moduleType === ModuleType.SHOPPING) {
        const store = await prisma.shoppingStore.findFirst({
          where: {
            OR: [{ id: entityId }, { slug: entityId }],
          },
          select: {
            id: true,
            slug: true,
            name: true,
            tagline: true,
            imageUrl: true,
          },
        });

        if (!store) {
          return {
            ok: false as const,
            status: 404,
            reason: 'Store not found.',
          };
        }

        const participantProfile = await findBoundParticipantProfile(
          ProProfileType.SHOP,
          'shoppingStoreIds',
          store.id,
        );

        return {
          ok: true as const,
          participantUserId: participantProfile?.userId ?? null,
          title: store.name,
          metadata: {
            customerName: user == null ? 'Customer' : formatFullName(user),
            customerPhone: user?.phone ?? null,
            participantName: store.name,
            merchantName: store.name,
            merchantKind: 'store',
            storeId: store.id,
            storeSlug: store.slug,
          },
        };
      }

      if (moduleType === ModuleType.FOOD) {
        const restaurant = await prisma.restaurant.findUnique({
          where: { id: entityId },
          select: {
            id: true,
            name: true,
            cuisine: true,
            imageUrl: true,
          },
        });

        if (!restaurant) {
          return {
            ok: false as const,
            status: 404,
            reason: 'Restaurant not found.',
          };
        }

        const participantProfile = await findBoundParticipantProfile(
          ProProfileType.SHOP,
          'restaurantIds',
          restaurant.id,
        );

        return {
          ok: true as const,
          participantUserId: participantProfile?.userId ?? null,
          title: restaurant.name,
          metadata: {
            customerName: user == null ? 'Customer' : formatFullName(user),
            customerPhone: user?.phone ?? null,
            participantName: restaurant.name,
            merchantName: restaurant.name,
            merchantKind: 'restaurant',
            restaurantId: restaurant.id,
            cuisine: restaurant.cuisine,
          },
        };
      }

      if (moduleType === ModuleType.PHARMACY) {
        const businessName = entityId.trim();
        if (businessName.length == 0) {
          return {
            ok: false as const,
            status: 404,
            reason: 'Pharmacy business not found.',
          };
        }

        const participantProfile =
            await findBoundShopProfileByPharmacyBusiness(businessName);

        return {
          ok: true as const,
          participantUserId: participantProfile?.userId ?? null,
          title: businessName,
          metadata: {
            customerName: user == null ? 'Customer' : formatFullName(user),
            customerPhone: user?.phone ?? null,
            participantName: businessName,
            merchantName: businessName,
            merchantKind: 'pharmacy',
            pharmacyBusiness: businessName,
          },
        };
      }

      return {
        ok: true as const,
        participantUserId: null,
        title: metadata?.merchantName?.toString() ?? 'Merchant',
        metadata: {
          customerName: user == null ? 'Customer' : formatFullName(user),
          customerPhone: user?.phone ?? null,
          merchantName: metadata?.merchantName?.toString() ?? 'Merchant',
        },
      };
    }
    case ConversationEntityType.DOCTOR: {
      const appointmentId = metadata?.appointmentId?.toString();
      const [participantProfile, appointment, user] = await Promise.all([
        findBoundParticipantProfile(
          ProProfileType.DOCTOR,
          'doctorIds',
          entityId,
        ),
        appointmentId == null || appointmentId.length == 0
          ? Promise.resolve(null)
          : prisma.appointment.findFirst({
              where: {
                id: appointmentId,
                userId,
                doctorId: entityId,
              },
              include: {
                doctor: {
                  select: {
                    id: true,
                    name: true,
                    specialty: true,
                    contactPhone: true,
                  },
                },
              },
            }),
        prisma.user.findUnique({
          where: { id: userId },
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        }),
      ]);

      if (appointmentId != null && appointmentId.length > 0 && appointment == null) {
        return {
          ok: false as const,
          status: 404,
          reason: 'Appointment not found for this user.',
        };
      }

      const doctorName = appointment?.doctor.name ?? 'Doctor';
      return {
        ok: true as const,
        participantUserId: participantProfile?.userId ?? null,
        title: doctorName,
        metadata: {
          customerName: user == null ? 'Customer' : formatFullName(user),
          customerPhone: user?.phone ?? null,
          participantName: doctorName,
          participantPhone: appointment?.doctor.contactPhone ?? null,
          doctorId: entityId,
          appointmentId: appointment?.id ?? appointmentId ?? null,
          specialty:
            appointment?.doctor.specialty ??
            metadata?.specialty?.toString() ??
            null,
        },
      };
    }
    case ConversationEntityType.HOME_SERVICE_PROVIDER: {
      const orderId = metadata?.orderId?.toString();
      const [participantProfile, provider, user, order] = await Promise.all([
        findBoundParticipantProfile(
          ProProfileType.PROVIDER,
          'providerIds',
          entityId,
        ),
        prisma.homeServiceProvider.findUnique({
          where: { id: entityId },
          select: {
            id: true,
            name: true,
            title: true,
            categoryId: true,
            contactPhone: true,
          },
        }),
        prisma.user.findUnique({
          where: { id: userId },
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        }),
        orderId == null || orderId.length == 0
          ? Promise.resolve(null)
          : prisma.order.findFirst({
              where: {
                id: orderId,
                userId,
                moduleType: {
                  in: [ModuleType.HOME_SERVICES, ModuleType.HOUSE_HELP],
                },
              },
              select: {
                id: true,
              },
            }),
      ]);

      if (!provider) {
        return {
          ok: false as const,
          status: 404,
          reason: 'Provider not found.',
        };
      }

      if (orderId != null && orderId.length > 0 && order == null) {
        return {
          ok: false as const,
          status: 404,
          reason: 'Service request not found for this user.',
        };
      }

      return {
        ok: true as const,
        participantUserId: participantProfile?.userId ?? null,
        title: provider.name,
        metadata: {
          customerName: user == null ? 'Customer' : formatFullName(user),
          customerPhone: user?.phone ?? null,
          participantName: provider.name,
          participantPhone: provider.contactPhone ?? null,
          providerId: entityId,
          orderId: order?.id ?? orderId ?? null,
          categorySlug: metadata?.categorySlug?.toString() ?? null,
          providerTitle: provider.title,
        },
      };
    }
    case ConversationEntityType.DELIVERY: {
      const order = await prisma.order.findUnique({
        where: { id: entityId },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
          deliveryAssignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
        },
      });

      if (!order || order.userId !== userId) {
        return {
          ok: false as const,
          status: 404,
          reason: 'Order not found for this user.',
        };
      }

      if (!order.deliveryUserId || !order.deliveryAssignee) {
        return {
          ok: false as const,
          status: 409,
          reason:
            'Delivery chat becomes available once a courier has claimed the order.',
        };
      }

      const courierName = formatFullName(order.deliveryAssignee);
      return {
        ok: true as const,
        participantUserId: order.deliveryUserId,
        title: courierName,
        metadata: {
          customerName: formatFullName(order.user),
          customerPhone: order.user.phone,
          participantName: courierName,
          participantPhone: order.deliveryAssignee.phone,
          orderId: order.id,
          moduleType: order.moduleType,
        },
      };
    }
    case ConversationEntityType.RIDE: {
      const ride = await prisma.rideBooking.findUnique({
        where: { id: entityId },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
          driverUser: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
        },
      });

      if (!ride || ride.userId !== userId) {
        return {
          ok: false as const,
          status: 404,
          reason: 'Ride not found for this user.',
        };
      }

      if (!ride.driverUserId || !ride.driverUser) {
        return {
          ok: false as const,
          status: 409,
          reason:
            'Ride chat becomes available once a driver has accepted the trip.',
        };
      }

      const driverName =
        ride.driverName != null && ride.driverName.trim().length > 0
          ? ride.driverName!.trim()
          : formatFullName(ride.driverUser);

      return {
        ok: true as const,
        participantUserId: ride.driverUserId,
        title: driverName,
        metadata: {
          customerName: formatFullName(ride.user),
          customerPhone: ride.user.phone,
          participantName: driverName,
          participantPhone: ride.driverPhone ?? ride.driverUser.phone,
          rideId: ride.id,
          pickup: ride.pickupLabel,
          destination: ride.dropoffLabel,
          vehicle: ride.vehicleName,
        },
      };
    }
    default:
      return {
        ok: true as const,
        participantUserId: null,
        title: null,
        metadata: {},
      };
  }
}

function resolveViewer(
  conversation: Awaited<ReturnType<typeof prisma.conversation.findUnique>>,
  actorUserId?: string,
): ViewerType {
  if (actorUserId == null || actorUserId.length == 0) {
    return 'user';
  }

  if (actorUserId === conversation?.userId) {
    return 'user';
  }

  if (actorUserId === conversation?.participantUserId) {
    return 'participant';
  }

  throw new Error('Conversation access denied.');
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
    case ConversationEntityType.SHOP:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Hello, thanks for reaching out. How can we help with your order or item today?',
      };
    case ConversationEntityType.DELIVERY:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'Hello, I am handling your delivery. Message me here for updates.',
      };
    case ConversationEntityType.RIDE:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'I am on the way. Message me here if you need anything.',
      };
  }

  return {
    senderRole: MessageSenderRole.SYSTEM,
    senderLabel: title,
    body: 'Hello, how can I help you today?',
  };
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
    case ConversationEntityType.SHOP:
      return {
        senderRole: MessageSenderRole.PROVIDER,
        senderLabel: title,
        body: 'Thanks. We received your message and will help you shortly.',
      };
    case ConversationEntityType.DELIVERY:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'Thanks. I will keep you posted as your delivery moves forward.',
      };
    case ConversationEntityType.RIDE:
      return {
        senderRole: MessageSenderRole.DRIVER,
        senderLabel: title,
        body: 'Got it. I will keep you updated during the ride.',
      };
  }

  return {
    senderRole: MessageSenderRole.SYSTEM,
    senderLabel: title,
    body: 'Thanks for your message.',
  };
}

async function isDoctorConversationAllowed({
  userId,
  entityId,
  metadata,
}: {
  userId: string;
  entityId: string;
  metadata?: Record<string, unknown> | null;
}) {
  const appointmentId = metadata?.appointmentId?.toString();
  if (!appointmentId) {
    return {
      ok: false,
      reason: 'Doctor chat is only available from an appointment detail.',
    };
  }

  const appointment = await prisma.appointment.findFirst({
    where: {
      id: appointmentId,
      userId,
      doctorId: entityId,
      status: AppointmentStatus.APPROVED,
    },
    select: {
      id: true,
      status: true,
    },
  });

  if (!appointment) {
    return {
      ok: false,
      reason:
          'Doctor chat is only available for a valid appointment linked to this doctor.',
    };
  }

  return {
    ok: true,
    appointmentId: appointment.id,
    status: appointment.status,
  };
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
  '/pro/:userId/summary',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const conversations = await prisma.conversation.findMany({
      where: { participantUserId: userId },
      select: {
        id: true,
        participantUnreadCount: true,
      },
    });

    res.json({
      conversationCount: conversations.length,
      unreadCount: conversations.reduce(
        (sum, conversation) => sum + conversation.participantUnreadCount,
        0,
      ),
      hasUnread: conversations.some(
        (conversation) => conversation.participantUnreadCount > 0,
      ),
    });
  }),
);

router.get(
  '/pro/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const conversations = await prisma.conversation.findMany({
      where: { participantUserId: userId },
      orderBy: [{ lastMessageAt: 'desc' }, { updatedAt: 'desc' }],
    });

    res.json(
      conversations.map((conversation) =>
        serializeConversationForViewer(conversation, 'participant'),
      ),
    );
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

    const actorUserId =
      typeof req.query.actorUserId === 'string' ? req.query.actorUserId : '';
    const viewer = resolveViewer(conversation, actorUserId);

    res.json({
      ...serializeConversationForViewer(conversation, viewer),
      messages: conversation.messages.map(serializeMessage),
    });
  }),
);

router.post(
  '/conversations/start',
  asyncHandler(async (req, res) => {
    const body = startConversationSchema.parse(req.body);

    if (body.entityType === ConversationEntityType.DOCTOR) {
      const validation = await isDoctorConversationAllowed({
        userId: body.userId,
        entityId: body.entityId,
        metadata: body.metadata,
      });

      if (!validation.ok) {
        return res.status(403).json({ error: validation.reason });
      }
    }

    const participant = await resolveConversationParticipant({
      userId: body.userId,
      entityType: body.entityType,
      entityId: body.entityId,
      moduleType: body.moduleType,
      metadata: body.metadata,
    });
    if (!participant.ok) {
      return res.status(participant.status).json({ error: participant.reason });
    }

    const finalTitle = participant.title ?? body.title;
    const finalMetadata = {
      ...(body.metadata ?? {}),
      ...participant.metadata,
    };

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
      const updated = await prisma.conversation.update({
        where: { id: existing.id },
        data: {
          participantUserId: participant.participantUserId,
          title: finalTitle,
          subtitle: body.subtitle ?? existing.subtitle,
          avatarUrl: body.avatarUrl ?? existing.avatarUrl,
          accentColor: body.accentColor ?? existing.accentColor,
          metadata: finalMetadata,
        },
      });
      return res.json(serializeConversation(updated));
    }

    const welcome = buildWelcomeMessage(body.entityType, finalTitle);
    const created = await prisma.conversation.create({
      data: {
        userId: body.userId,
        participantUserId: participant.participantUserId,
        moduleType: body.moduleType,
        entityType: body.entityType,
        entityId: body.entityId,
        title: finalTitle,
        subtitle: body.subtitle ?? null,
        avatarUrl: body.avatarUrl ?? null,
        accentColor: body.accentColor ?? null,
        metadata: finalMetadata,
        lastMessage: welcome.body,
        lastMessageAt: new Date(),
        userUnreadCount: 1,
        participantUnreadCount: 0,
        messages: {
          create: {
            senderUserId: participant.participantUserId ?? undefined,
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
  '/pro/conversations/start',
  asyncHandler(async (req, res) => {
    const body = startProConversationSchema.parse(req.body);

    const [customer, participant] = await Promise.all([
      prisma.user.findUnique({
        where: { id: body.customerUserId },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          phone: true,
        },
      }),
      prisma.user.findUnique({
        where: { id: body.participantUserId },
        select: {
          id: true,
        },
      }),
    ]);

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found.' });
    }

    if (!participant) {
      return res.status(404).json({ error: 'Pro participant not found.' });
    }

    const finalMetadata = {
      ...(body.metadata ?? {}),
      customerName: formatFullName(customer),
      customerPhone: customer.phone ?? null,
      participantName: body.title,
    };

    const existing = await prisma.conversation.findUnique({
      where: {
        userId_entityType_entityId: {
          userId: body.customerUserId,
          entityType: body.entityType,
          entityId: body.entityId,
        },
      },
    });

    if (existing) {
      const updated = await prisma.conversation.update({
        where: { id: existing.id },
        data: {
          participantUserId: body.participantUserId,
          moduleType: body.moduleType,
          title: body.title,
          subtitle: body.subtitle ?? existing.subtitle,
          avatarUrl: body.avatarUrl ?? existing.avatarUrl,
          accentColor: body.accentColor ?? existing.accentColor,
          metadata: finalMetadata,
        },
      });
      return res.json(serializeConversationForViewer(updated, 'participant'));
    }

    const welcome = buildAutoReply(body.entityType, body.title);
    const created = await prisma.conversation.create({
      data: {
        userId: body.customerUserId,
        participantUserId: body.participantUserId,
        moduleType: body.moduleType,
        entityType: body.entityType,
        entityId: body.entityId,
        title: body.title,
        subtitle: body.subtitle ?? null,
        avatarUrl: body.avatarUrl ?? null,
        accentColor: body.accentColor ?? null,
        metadata: finalMetadata,
        lastMessage: welcome.body,
        lastMessageAt: new Date(),
        userUnreadCount: 1,
        participantUnreadCount: 0,
        messages: {
          create: {
            senderUserId: body.participantUserId,
            senderRole: welcome.senderRole,
            senderLabel: welcome.senderLabel,
            body: welcome.body,
          },
        },
      },
    });

    res.status(201).json(serializeConversationForViewer(created, 'participant'));
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

    let viewer: ViewerType;
    try {
      viewer = resolveViewer(conversation, body.actorUserId);
    } catch (error) {
      return res
        .status(403)
        .json({ error: error instanceof Error ? error.message : 'Forbidden.' });
    }

    if (
      body.senderRole === MessageSenderRole.USER &&
      viewer !== 'user'
    ) {
      return res.status(403).json({ error: 'Only the customer can send user messages.' });
    }

    if (
      body.senderRole !== MessageSenderRole.USER &&
      viewer !== 'participant'
    ) {
      return res.status(403).json({ error: 'Only the assigned pro can reply here.' });
    }

    if (conversation.entityType === ConversationEntityType.DOCTOR) {
      const metadata =
          conversation.metadata &&
          typeof conversation.metadata === 'object' &&
          !Array.isArray(conversation.metadata)
              ? (conversation.metadata as Record<string, unknown>)
              : null;

      const validation = await isDoctorConversationAllowed({
        userId: conversation.userId,
        entityId: conversation.entityId,
        metadata,
      });

      if (!validation.ok && body.senderRole === MessageSenderRole.USER) {
        return res.status(403).json({ error: validation.reason });
      }
    }

    const userMessage = await prisma.message.create({
      data: {
        conversationId,
        senderUserId:
          body.actorUserId ??
          (body.senderRole === MessageSenderRole.USER
            ? conversation.userId
            : conversation.participantUserId ?? undefined),
        senderRole: body.senderRole,
        senderLabel: body.senderLabel ?? null,
        body: body.body.trim(),
        metadata: body.metadata ?? undefined,
      },
    });

    let userUnreadCount = conversation.userUnreadCount;
    let participantUnreadCount = conversation.participantUnreadCount;
    let lastMessage = userMessage.body;
    let lastMessageAt = userMessage.createdAt;

    if (body.senderRole === MessageSenderRole.USER) {
      if (conversation.participantUserId) {
        participantUnreadCount += 1;
      } else {
        const reply = buildAutoReply(conversation.entityType, conversation.title);
        const autoReply = await prisma.message.create({
          data: {
            conversationId,
            senderRole: reply.senderRole,
            senderLabel: reply.senderLabel,
            body: reply.body,
          },
        });
        userUnreadCount += 1;
        lastMessage = autoReply.body;
        lastMessageAt = autoReply.createdAt;
      }
    } else {
      userUnreadCount += 1;
    }

    const updatedConversation = await prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessage,
        lastMessageAt,
        userUnreadCount,
        participantUnreadCount,
      },
    });

    if (
      body.senderRole === MessageSenderRole.USER &&
      conversation.participantUserId
    ) {
      await createMessageNotification({
        userId: conversation.participantUserId,
        conversationId: conversation.id,
        title: notificationTitleForParticipant(conversation),
        body: userMessage.body,
        route: `/pro/messages/chat/${conversation.id}`,
        actorRole: body.senderRole,
        entityType: conversation.entityType,
        entityId: conversation.entityId,
        moduleType: conversation.moduleType,
        dedupeKey: `message:${userMessage.id}:${conversation.participantUserId}`,
      });
    }

    if (
      body.senderRole !== MessageSenderRole.USER &&
      conversation.userId.length > 0
    ) {
      await createMessageNotification({
        userId: conversation.userId,
        conversationId: conversation.id,
        title: notificationTitleForUser(conversation),
        body: userMessage.body,
        route: `/messages/chat/${conversation.id}`,
        actorRole: body.senderRole,
        entityType: conversation.entityType,
        entityId: conversation.entityId,
        moduleType: conversation.moduleType,
        dedupeKey: `message:${userMessage.id}:${conversation.userId}`,
      });
    }

    res.status(201).json({
      sent: serializeMessage(userMessage),
      lastMessage,
      lastMessageAt,
      unreadCount:
        viewer === 'participant'
          ? updatedConversation.participantUnreadCount
          : updatedConversation.userUnreadCount,
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
    const body = readConversationSchema.parse(req.body);

    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found.' });
    }

    let viewer: ViewerType;
    try {
      viewer = resolveViewer(conversation, body.actorUserId);
    } catch (error) {
      return res
        .status(403)
        .json({ error: error instanceof Error ? error.message : 'Forbidden.' });
    }

    await prisma.message.updateMany({
      where: {
        conversationId,
        senderRole:
          viewer === 'participant'
            ? MessageSenderRole.USER
            : {
                not: MessageSenderRole.USER,
              },
        readAt: null,
      },
      data: {
        readAt: new Date(),
      },
    });

    const updatedConversation = await prisma.conversation.update({
      where: { id: conversationId },
      data:
        viewer === 'participant'
          ? { participantUnreadCount: 0 }
          : { userUnreadCount: 0 },
    });

    res.json(serializeConversationForViewer(updatedConversation, viewer));
  }),
);

export default router;
