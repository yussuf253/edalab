import { OrderStatus, Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { Request, Router } from 'express';
import { z } from 'zod';
import { env } from '../config/env';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';

const router = Router();

const defaultWaafiPayStoreId = '1008147';
const defaultWaafiPayHppKey = 'HPP-mnhsbMzojHqgAP7FXemveLt4Sa7O';
const defaultWaafiPayMerchantUid = 'M0913935';

const waafiPayBaseUrl = env.WAAFIPAY_PRODUCTION
  ? 'https://api.waafipay.net/asm'
  : 'https://sandbox.waafipay.net/asm';

const initiateWaafiSchema = z.object({
  orderId: z.string().min(1),
  userId: z.string().min(1),
  amount: z.coerce.number().positive(),
  description: z.string().optional(),
});

function paymentMetadata(value: Prisma.JsonValue | null | undefined) {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return { ...(value as Record<string, unknown>) };
  }
  return {};
}

function publicApiOrigin(req: Request) {
  const configuredBase = env.PUBLIC_BASE_URL?.replace(/\/+$/, '');
  if (configuredBase) {
    return configuredBase.endsWith('/api')
      ? configuredBase
      : `${configuredBase}/api`;
  }
  return `${req.protocol}://${req.get('host')}/api`;
}

function decodeWaafiResult(rawToken: string) {
  const candidates = [rawToken];
  if (/^[0-9a-f]+$/i.test(rawToken) && rawToken.length % 2 === 0) {
    candidates.push(Buffer.from(rawToken, 'hex').toString('utf8'));
  }

  for (const candidate of candidates) {
    const trimmed = candidate.trim();
    if (trimmed.startsWith('{')) {
      try {
        return JSON.parse(trimmed) as Record<string, unknown>;
      } catch {
        // Try the next decoding strategy.
      }
    }

    try {
      const decoded = Buffer.from(trimmed, 'base64').toString('utf8').trim();
      if (decoded.startsWith('{')) {
        return JSON.parse(decoded) as Record<string, unknown>;
      }
    } catch {
      // WaafiPay can send an opaque/encrypted HPP token on failure.
    }
  }

  return {
    opaqueToken: true,
    tokenPreview: rawToken.slice(0, 32),
  };
}

router.post(
  '/waafipay/initiate',
  asyncHandler(async (req, res) => {
    const body = initiateWaafiSchema.parse(req.body);
    const storeId = env.WAAFIPAY_STORE_ID || defaultWaafiPayStoreId;
    const hppKey = env.WAAFIPAY_HPP_KEY || defaultWaafiPayHppKey;
    const merchantUid =
      env.WAAFIPAY_MERCHANT_UID || defaultWaafiPayMerchantUid;

    const order = await prisma.order.findFirst({
      where: { id: body.orderId, userId: body.userId },
    });
    if (!order) return res.status(404).json({ error: 'Order not found.' });

    const referenceId = `EDA-${randomUUID().slice(0, 8)}`;
    const apiOrigin = publicApiOrigin(req);
    const callbackQuery = `orderId=${encodeURIComponent(order.id)}&referenceId=${encodeURIComponent(referenceId)}`;
    const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');

    const payload = {
      schemaVersion: '1.0',
      requestId: randomUUID(),
      timestamp,
      channelName: 'WEB',
      serviceName: 'HPP_PURCHASE',
      serviceParams: {
        merchantUid,
        storeId,
        hppKey,
        hppSuccessCallbackUrl: `${apiOrigin}/payments/waafipay/callback/success?${callbackQuery}`,
        hppFailureCallbackUrl: `${apiOrigin}/payments/waafipay/callback/failure?${callbackQuery}`,
        hppRespDataFormat: '4',
        paymentMethod: 'MWALLET_ACCOUNT',
        transactionInfo: {
          referenceId,
          invoiceId: order.id,
          amount: body.amount.toFixed(2),
          currency: 'DJF',
          description:
            body.description?.replace(/[^\w\s.-]/g, '').slice(0, 120) ??
            `eDaLab order ${order.id}`,
        },
      },
    };

    const response = await fetch(waafiPayBaseUrl, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(30000),
    });
    const rawResponse = await response.text();
    let waafiResponse: Record<string, unknown>;
    try {
      waafiResponse = JSON.parse(rawResponse) as Record<string, unknown>;
    } catch {
      waafiResponse = { rawResponse };
    }

    const params =
      waafiResponse.params &&
      typeof waafiResponse.params === 'object' &&
      !Array.isArray(waafiResponse.params)
        ? (waafiResponse.params as Record<string, unknown>)
        : {};
    const success = response.ok && waafiResponse.responseCode === '2001';

    await prisma.order.update({
      where: { id: order.id },
      data: {
        metadata: {
          ...paymentMetadata(order.metadata),
          payment: {
            provider: 'WAAFIPAY',
            status: success ? 'INITIATED' : 'FAILED',
            referenceId,
            transactionId: params.transactionId,
            responseCode: waafiResponse.responseCode,
            responseMessage: waafiResponse.responseMsg,
            updatedAt: new Date().toISOString(),
          },
        } as Prisma.InputJsonValue,
      },
    });

    res.json({
      success,
      referenceId,
      transactionId: params.transactionId,
      paymentUrl: params.directPaymentLink,
      responseCode: waafiResponse.responseCode,
      responseMessage: waafiResponse.responseMsg,
      data: waafiResponse,
    });
  }),
);

router.all(
  '/waafipay/callback/:result',
  asyncHandler(async (req, res) => {
    const callbackResult = req.params.result?.toString().toLowerCase();
    const orderId = req.query.orderId?.toString() || req.body?.orderId;
    const referenceId =
      req.query.referenceId?.toString() || req.body?.referenceId;
    const hppResultToken =
      req.query.hppResultToken?.toString() ||
      req.body?.hppResultToken ||
      req.body?.HPP_RESULT_TOKEN;

    if (!orderId || !hppResultToken) {
      return res.status(400).json({ error: 'Missing WaafiPay callback data.' });
    }

    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) return res.status(404).json({ error: 'Order not found.' });

    const callbackData = decodeWaafiResult(hppResultToken.toString());
    const responseCode = callbackData.responseCode?.toString();
    const responseMsg = callbackData.responseMsg?.toString();
    const hasParsedResult = responseCode != null || responseMsg != null;
    const paid =
      (responseCode === '2001' && responseMsg === 'RCS_SUCCESS') ||
      (!hasParsedResult && callbackResult === 'success');
    const cancelled = responseCode === '5001' || responseCode === '5002';
    const paymentStatus = paid
      ? 'COMPLETED'
      : cancelled
        ? 'CANCELLED'
        : 'FAILED';

    await prisma.order.update({
      where: { id: order.id },
      data: {
        status: paid
          ? OrderStatus.CONFIRMED
          : cancelled
            ? OrderStatus.CANCELLED
            : order.status,
        metadata: {
          ...paymentMetadata(order.metadata),
          payment: {
            provider: 'WAAFIPAY',
            status: paymentStatus,
            referenceId:
              callbackData.referenceId?.toString() || referenceId || null,
            responseCode,
            responseMessage: responseMsg,
            callbackResult,
            callbackData,
            updatedAt: new Date().toISOString(),
          },
        } as Prisma.InputJsonValue,
      },
    });

    res.json({
      success: paid,
      status: paymentStatus,
      orderId: order.id,
    });
  }),
);

export default router;
