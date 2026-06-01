import crypto from 'crypto';
import { env } from '../config/env';

type VerificationKind = 'auth' | 'pro-auth';

type VerificationEmailParams = {
  email: string;
  name: string;
  token: string;
  kind: VerificationKind;
};

type VerificationDelivery = {
  sent: boolean;
  verificationUrl: string | null;
  devToken?: string;
};

export function createEmailVerificationChallenge() {
  const token = crypto.randomBytes(32).toString('base64url');
  const tokenHash = hashEmailVerificationToken(token);
  const expiresAt = new Date(
    Date.now() + env.EMAIL_VERIFICATION_TTL_MINUTES * 60 * 1000,
  );

  return { token, tokenHash, expiresAt };
}

export function hashEmailVerificationToken(token: string) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function hasPendingEmailVerification(account: {
  emailVerifiedAt?: Date | null;
  emailVerificationTokenHash?: string | null;
}) {
  return account.emailVerifiedAt == null && account.emailVerificationTokenHash != null;
}

function publicApiBaseUrl() {
  const baseUrl = env.PUBLIC_BASE_URL?.trim();
  if (!baseUrl) return null;
  return baseUrl.replace(/\/+$/g, '');
}

export function buildEmailVerificationUrl(kind: VerificationKind, token: string) {
  const baseUrl = publicApiBaseUrl();
  if (!baseUrl) return null;
  return `${baseUrl}/api/${kind}/verify-email?token=${encodeURIComponent(token)}`;
}

export async function sendEmailVerification(
  params: VerificationEmailParams,
): Promise<VerificationDelivery> {
  const verificationUrl = buildEmailVerificationUrl(params.kind, params.token);
  const apiKey = env.RESEND_API_KEY?.trim();
  if (!apiKey || !verificationUrl) {
    return {
      sent: false,
      verificationUrl,
      ...(env.NODE_ENV === 'production' ? {} : { devToken: params.token }),
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
        from: env.RESEND_FROM_EMAIL,
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
      console.error(
        `[EMAIL_VERIFICATION] Resend failed (${response.status}): ${rawBody.slice(0, 300)}`,
      );
      return { sent: false, verificationUrl };
    }

    return { sent: true, verificationUrl };
  } catch (error) {
    console.error('[EMAIL_VERIFICATION] Delivery failed.', error);
    return { sent: false, verificationUrl };
  }
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
