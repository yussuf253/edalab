"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendPushToUser = sendPushToUser;
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const env_1 = require("../config/env");
const db_1 = require("../db");
let initialized = false;
let available = false;
function readCredential() {
    if (env_1.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        try {
            const parsed = JSON.parse(env_1.env.FIREBASE_SERVICE_ACCOUNT_JSON);
            return parsed;
        }
        catch (error) {
            console.error('[PUSH] Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON', error);
            return null;
        }
    }
    if (env_1.env.FIREBASE_PROJECT_ID &&
        env_1.env.FIREBASE_CLIENT_EMAIL &&
        env_1.env.FIREBASE_PRIVATE_KEY) {
        return {
            projectId: env_1.env.FIREBASE_PROJECT_ID,
            clientEmail: env_1.env.FIREBASE_CLIENT_EMAIL,
            privateKey: env_1.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        };
    }
    return null;
}
function ensureFirebaseAdmin() {
    if (initialized)
        return available;
    initialized = true;
    const credential = readCredential();
    if (!credential) {
        console.warn('[PUSH] Firebase Admin credentials are not configured. Push send skipped.');
        available = false;
        return available;
    }
    try {
        if (firebase_admin_1.default.apps.length === 0) {
            firebase_admin_1.default.initializeApp({
                credential: firebase_admin_1.default.credential.cert(credential),
            });
        }
        available = true;
    }
    catch (error) {
        console.error('[PUSH] Firebase Admin initialization failed', error);
        available = false;
    }
    return available;
}
async function sendPushToUser(payload) {
    if (!ensureFirebaseAdmin())
        return;
    const tokens = await db_1.prisma.deviceToken.findMany({
        where: { userId: payload.userId },
        orderBy: { updatedAt: 'desc' },
        take: 20,
    });
    if (tokens.length === 0) {
        return;
    }
    const message = await firebase_admin_1.default.messaging().sendEachForMulticast({
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
                : Object.fromEntries(Object.entries(payload.metadata).map(([key, value]) => [
                    key,
                    value == null ? '' : String(value),
                ]))),
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
        .filter(({ response, token }) => token != null &&
        !response.success &&
        response.error?.code != null &&
        [
            'messaging/invalid-registration-token',
            'messaging/registration-token-not-registered',
        ].includes(response.error.code))
        .map((item) => item.token);
    if (invalidTokens.length > 0) {
        await db_1.prisma.deviceToken.deleteMany({
            where: {
                token: { in: invalidTokens },
            },
        });
    }
}
