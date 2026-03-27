import admin from 'firebase-admin';

import { env } from '../config/env';
import { prisma } from '../db';

type PushPayload = {
  userId: string;
  title: string;
  body: string;
  route?: string | null;
  module: string;
  priority: string;
  dedupeKey?: string | null;
  metadata?: Record<string, unknown>;
};

let initialized = false;
let available = false;

function readCredential():
  | admin.ServiceAccount
  | null {
  if (env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const parsed = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
      return parsed as admin.ServiceAccount;
    } catch (error) {
      console.error('[PUSH] Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON', error);
      return null;
    }
  }

  if (
    env.FIREBASE_PROJECT_ID &&
    env.FIREBASE_CLIENT_EMAIL &&
    env.FIREBASE_PRIVATE_KEY
  ) {
    return {
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    };
  }

  return null;
}

function ensureFirebaseAdmin(): boolean {
  if (initialized) return available;
  initialized = true;

  const credential = readCredential();
  if (!credential) {
    console.warn(
      '[PUSH] Firebase Admin credentials are not configured. Push send skipped.',
    );
    available = false;
    return available;
  }

  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(credential),
      });
    }
    available = true;
  } catch (error) {
    console.error('[PUSH] Firebase Admin initialization failed', error);
    available = false;
  }

  return available;
}

export async function sendPushToUser(payload: PushPayload) {
  if (!ensureFirebaseAdmin()) return;

  const tokens = await prisma.deviceToken.findMany({
    where: { userId: payload.userId },
    orderBy: { updatedAt: 'desc' },
    take: 20,
  });

  if (tokens.length === 0) {
    return;
  }

  const message = await admin.messaging().sendEachForMulticast({
    tokens: tokens.map((item) => item.token),
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      title: payload.title,
      body: payload.body,
      route: payload.route ?? '',
      module: payload.module,
      priority: payload.priority,
      dedupeKey: payload.dedupeKey ?? '',
      ...(payload.metadata == null
          ? {}
          : Object.fromEntries(
              Object.entries(payload.metadata).map(([key, value]) => [
                key,
                value == null ? '' : String(value),
              ]),
            )),
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'edalab_high_priority',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  });

  const invalidTokens = message.responses
      .map((response, index) => ({ response, token: tokens[index]?.token }))
      .filter(
        ({ response, token }) =>
          token != null &&
          !response.success &&
          response.error?.code != null &&
          [
            'messaging/invalid-registration-token',
            'messaging/registration-token-not-registered',
          ].includes(response.error.code),
      )
      .map((item) => item.token as string);

  if (invalidTokens.length > 0) {
    await prisma.deviceToken.deleteMany({
      where: {
        token: { in: invalidTokens },
      },
    });
  }
}
