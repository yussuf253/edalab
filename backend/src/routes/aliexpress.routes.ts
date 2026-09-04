import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import {
  searchProducts,
  getProductDetail,
  queryCategoryTree,
  exchangeCodeForToken,
  refreshAccessToken,
  queryOrderList,
  queryOrderDetail,
  verifyWebhookSignature,
  clearAliExpressCache,
  normalizeProduct,
  parsePrice,
} from '../services/aliexpress.service';
import { prisma } from '../db';

const router = Router();

// ---------------------------------------------------------------------------
// Request validation schemas
// ---------------------------------------------------------------------------

const searchQuerySchema = z.object({
  q: z.string().min(1, 'Search query is required'),
  page: z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
  targetCurrency: z.string().default('USD'),
  targetLanguage: z.string().default('EN'),
  sort: z.string().default('DEFAULT'),
});

const categoryQuerySchema = z.object({
  parentId: z.coerce.number().int().default(0),
});

const tokenExchangeSchema = z.object({
  code: z.string().min(1, 'Authorization code is required'),
});

const tokenRefreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

const orderQuerySchema = z.object({
  accessToken: z.string().min(1, 'Access token is required'),
  pageNo: z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
  createTimeStart: z.string().optional(),
  createTimeEnd: z.string().optional(),
  orderStatus: z.string().optional(),
});

const orderDetailSchema = z.object({
  accessToken: z.string().min(1, 'Access token is required'),
  orderId: z.string().min(1, 'Order ID is required'),
});

// ---------------------------------------------------------------------------
// Product search
// ---------------------------------------------------------------------------

router.get(
  '/products/search',
  asyncHandler(async (req, res) => {
    const params = searchQuerySchema.parse(req.query);

    const result = await searchProducts({
      keywords: params.q,
      pageNo: params.page,
      pageSize: params.pageSize,
      targetCurrency: params.targetCurrency,
      targetLanguage: params.targetLanguage,
      sort: params.sort,
    });

    // Normalize to ProductModel shape
    const normalizedProducts = result.products.map(normalizeProduct);

    res.json({
      products: normalizedProducts,
      pagination: {
        totalRecords: result.totalRecords,
        currentPage: result.currentPage,
        pageSize: params.pageSize,
        totalPages: Math.ceil(result.totalRecords / params.pageSize),
      },
    });
  }),
);

// ---------------------------------------------------------------------------
// Product detail
// ---------------------------------------------------------------------------

router.get(
  '/products/:id',
  asyncHandler(async (req, res) => {
    const productId = getParam(req.params.id, 'productId');

    const result = await getProductDetail(productId);

    if (!result.product) {
      return res.status(404).json({ error: 'Product not found on AliExpress.' });
    }

    const normalized = normalizeProduct(result.product);
    res.json(normalized);
  }),
);

// ---------------------------------------------------------------------------
// Category tree
// ---------------------------------------------------------------------------

router.get(
  '/categories',
  asyncHandler(async (req, res) => {
    const params = categoryQuerySchema.parse(req.query);

    const result = await queryCategoryTree(params.parentId);

    res.json({
      categories: result.categories,
    });
  }),
);

// ---------------------------------------------------------------------------
// Token exchange (OAuth callback)
// ---------------------------------------------------------------------------

router.post(
  '/auth/token',
  asyncHandler(async (req, res) => {
    const params = tokenExchangeSchema.parse(req.body);

    const tokenResult = await exchangeCodeForToken(params.code);

    res.json({
      accessToken: tokenResult.accessToken,
      refreshToken: tokenResult.refreshToken,
      expireTime: tokenResult.expireTime,
    });
  }),
);

// ---------------------------------------------------------------------------
// Token refresh
// ---------------------------------------------------------------------------

router.post(
  '/auth/refresh',
  asyncHandler(async (req, res) => {
    const params = tokenRefreshSchema.parse(req.body);

    const tokenResult = await refreshAccessToken(params.refreshToken);

    res.json({
      accessToken: tokenResult.accessToken,
      refreshToken: tokenResult.refreshToken,
      expireTime: tokenResult.expireTime,
    });
  }),
);

// ---------------------------------------------------------------------------
// Orders list
// ---------------------------------------------------------------------------

router.get(
  '/orders',
  asyncHandler(async (req, res) => {
    const params = orderQuerySchema.parse(req.query);

    const result = await queryOrderList(params.accessToken, {
      pageNo: params.pageNo,
      pageSize: params.pageSize,
      createTimeStart: params.createTimeStart,
      createTimeEnd: params.createTimeEnd,
      orderStatus: params.orderStatus,
    });

    res.json({
      orders: result.orders,
      totalResults: result.totalResults,
    });
  }),
);

// ---------------------------------------------------------------------------
// Order detail
// ---------------------------------------------------------------------------

router.get(
  '/orders/:id',
  asyncHandler(async (req, res) => {
    const orderId = getParam(req.params.id, 'orderId');

    // accessToken comes from query params for GET requests
    const accessToken = (req.query.accessToken as string | undefined) ?? '';
    if (!accessToken || accessToken.trim().length === 0) {
      return res.status(400).json({ error: 'Access token is required.' });
    }

    const result = await queryOrderDetail(accessToken, orderId);

    if (!result.order) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    res.json(result.order);
  }),
);

// ---------------------------------------------------------------------------
// Webhook receiver for AliExpress order status push
// ---------------------------------------------------------------------------

router.post(
  '/webhook',
  asyncHandler(async (req, res) => {
    const authorization = req.headers.authorization as string | undefined;
    const rawBody = req.body as string | Record<string, unknown>;

    // Body should be the raw JSON string for signature verification
    const bodyString =
      typeof rawBody === 'string' ? rawBody : JSON.stringify(rawBody);

    // Verify signature (recommended but not mandatory per docs)
    if (authorization) {
      const isValid = verifyWebhookSignature(authorization, bodyString);
      if (!isValid) {
        console.warn('[AliExpress Webhook] Invalid signature — rejecting');
        return res.status(401).json({ error: 'Invalid signature' });
      }
    }

    // Parse the webhook data
    const webhookData =
      typeof rawBody === 'string'
        ? (JSON.parse(rawBody) as Record<string, unknown>)
        : rawBody;

    const messageType = Number(webhookData.message_type ?? 0);
    const sellerId = String(webhookData.seller_id ?? '');
    const data = webhookData.data as Record<string, unknown> | undefined;

    console.log(
      `[AliExpress Webhook] message_type=${messageType} seller_id=${sellerId}`,
    );

    // Handle order status updates
    // message_type 1 = online order successfully (PLACE_ORDER_SUCCESS)
    // message_type 6 = waiting for shipping
    // message_type 12 = transaction successful (FINISH)
    if (
      data &&
      typeof data.trade_order_id === 'string' &&
      typeof data.order_status === 'string'
    ) {
      const aliexpressOrderId = data.trade_order_id;
      const orderStatus = data.order_status;

      // Update local order status if we have a matching order
      try {
        await prisma.order.updateMany({
          where: {
            metadata: {
              path: ['aliexpressOrderId'],
              equals: aliexpressOrderId,
            },
          },
          data: {
            status: mapAliExpressOrderStatus(orderStatus),
          },
        });
      } catch (err) {
        console.error(
          `[AliExpress Webhook] Failed to update order ${aliexpressOrderId}:`,
          err,
        );
      }
    }

    // Must respond 200 OK within 500ms per AliExpress requirements
    res.status(200).json({ success: true });
  }),
);

// ---------------------------------------------------------------------------
// Cache management (admin/debug)
// ---------------------------------------------------------------------------

router.post(
  '/cache/clear',
  asyncHandler(async (_req, res) => {
    clearAliExpressCache();
    res.json({ success: true, message: 'AliExpress cache cleared.' });
  }),
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function mapAliExpressOrderStatus(
  aeStatus: string,
): 'PENDING' | 'CONFIRMED' | 'PROCESSING' | 'DISPATCHED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED' | 'REFUNDED' {
  const statusMap: Record<string, 'PENDING' | 'CONFIRMED' | 'PROCESSING' | 'DISPATCHED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED' | 'REFUNDED'> = {
    PLACE_ORDER_SUCCESS: 'CONFIRMED',
    RISK_CONTROL: 'PENDING',
    WAIT_SELLER_VERIFY: 'PENDING',
    WAIT_GROUP: 'PENDING',
    IN_CANCEL: 'CANCELLED',
    WAIT_SELLER_SEND_GOODS: 'PROCESSING',
    SELLER_PARTLY_SEND_GOODS: 'DISPATCHED',
    WAIT_BUYER_ACCEPT_GOODS: 'DISPATCHED',
    FINISH: 'COMPLETED',
    IN_ISSUE: 'IN_PROGRESS',
  };

  return statusMap[aeStatus] ?? 'PROCESSING';
}

export default router;
