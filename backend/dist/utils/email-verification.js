"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createEmailVerificationChallenge = createEmailVerificationChallenge;
exports.hashEmailVerificationToken = hashEmailVerificationToken;
exports.hasPendingEmailVerification = hasPendingEmailVerification;
exports.buildEmailVerificationUrl = buildEmailVerificationUrl;
exports.sendEmailVerification = sendEmailVerification;
const crypto_1 = __importDefault(require("crypto"));
const env_1 = require("../config/env");
function createEmailVerificationChallenge() {
    const token = crypto_1.default.randomBytes(32).toString('base64url');
    const tokenHash = hashEmailVerificationToken(token);
    const expiresAt = new Date(Date.now() + env_1.env.EMAIL_VERIFICATION_TTL_MINUTES * 60 * 1000);
    return { token, tokenHash, expiresAt };
}
function hashEmailVerificationToken(token) {
    return crypto_1.default.createHash('sha256').update(token).digest('hex');
}
function hasPendingEmailVerification(account) {
    return account.emailVerifiedAt == null && account.emailVerificationTokenHash != null;
}
function publicApiBaseUrl() {
    const baseUrl = env_1.env.PUBLIC_BASE_URL?.trim();
    if (!baseUrl)
        return null;
    return baseUrl.replace(/\/+$/g, '');
}
function buildEmailVerificationUrl(kind, token) {
    const baseUrl = publicApiBaseUrl();
    if (!baseUrl)
        return null;
    return `${baseUrl}/api/${kind}/verify-email?token=${encodeURIComponent(token)}`;
}
async function sendEmailVerification(params) {
    const verificationUrl = buildEmailVerificationUrl(params.kind, params.token);
    const apiKey = env_1.env.RESEND_API_KEY?.trim();
    if (!apiKey || !verificationUrl) {
        return {
            sent: false,
            verificationUrl,
            ...(env_1.env.NODE_ENV === 'production' ? {} : { devToken: params.token }),
        };
    }
    try {
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: env_1.env.RESEND_FROM_EMAIL,
                to: [params.email],
                subject: 'Verify your EdaLab email',
                html: [
                    `<p>Hello ${escapeHtml(params.name)},</p>`,
                    '<p>Please verify your email address to finish setting up your EdaLab account.</p>',
                    `<p><a href="${escapeHtml(verificationUrl)}">Verify email address</a></p>`,
                    '<p>This link expires soon. If you did not create this account, you can ignore this email.</p>',
                ].join(''),
                text: [
                    `Hello ${params.name},`,
                    '',
                    'Please verify your email address to finish setting up your EdaLab account.',
                    verificationUrl,
                    '',
                    'This link expires soon. If you did not create this account, you can ignore this email.',
                ].join('\n'),
            }),
        });
        if (!response.ok) {
            const rawBody = await response.text().catch(() => '');
            console.error(`[EMAIL_VERIFICATION] Resend failed (${response.status}): ${rawBody.slice(0, 300)}`);
            return { sent: false, verificationUrl };
        }
        return { sent: true, verificationUrl };
    }
    catch (error) {
        console.error('[EMAIL_VERIFICATION] Delivery failed.', error);
        return { sent: false, verificationUrl };
    }
}
function escapeHtml(value) {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}
