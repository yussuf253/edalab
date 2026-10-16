"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const aliexpress_service_1 = require("../services/aliexpress.service");
const db_1 = require("../db");
const router = (0, express_1.Router)();
// ---------------------------------------------------------------------------
// Request validation schemas
// ---------------------------------------------------------------------------
const searchQuerySchema = zod_1.z.object({
    q: zod_1.z.string().min(1, 'Search query is required'),
    page: zod_1.z.coerce.number().int().positive().default(1),
    pageSize: zod_1.z.coerce.number().int().min(1).max(50).default(20),
    targetCurrency: zod_1.z.string().default('USD'),
    targetLanguage: zod_1.z.string().default('EN'),
    sort: zod_1.z.string().default('DEFAULT'),
});
const categoryQuerySchema = zod_1.z.object({
    parentId: zod_1.z.coerce.number().int().default(0),
});
const tokenExchangeSchema = zod_1.z.object({
    code: zod_1.z.string().min(1, 'Authorization code is required'),
});
const tokenRefreshSchema = zod_1.z.object({
    refreshToken: zod_1.z.string().min(1, 'Refresh token is required'),
});
const orderQuerySchema = zod_1.z.object({
    accessToken: zod_1.z.string().min(1, 'Access token is required'),
    pageNo: zod_1.z.coerce.number().int().positive().default(1),
    pageSize: zod_1.z.coerce.number().int().min(1).max(50).default(20),
    createTimeStart: zod_1.z.string().optional(),
    createTimeEnd: zod_1.z.string().optional(),
    orderStatus: zod_1.z.string().optional(),
});
const orderDetailSchema = zod_1.z.object({
    accessToken: zod_1.z.string().min(1, 'Access token is required'),
    orderId: zod_1.z.string().min(1, 'Order ID is required'),
});
// ---------------------------------------------------------------------------
// Product search
// ---------------------------------------------------------------------------
router.get('/products/search', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const params = searchQuerySchema.parse(req.query);
    const result = await (0, aliexpress_service_1.searchProducts)({
        keywords: params.q,
        pageNo: params.page,
        pageSize: params.pageSize,
        targetCurrency: params.targetCurrency,
        targetLanguage: params.targetLanguage,
        sort: params.sort,
    });
    // Normalize to ProductModel shape
    const normalizedProducts = result.products.map(aliexpress_service_1.normalizeProduct);
    res.json({
        products: normalizedProducts,
        pagination: {
            totalRecords: result.totalRecords,
            currentPage: result.currentPage,
            pageSize: params.pageSize,
            totalPages: Math.ceil(result.totalRecords / params.pageSize),
        },
    });
}));
// ---------------------------------------------------------------------------
// Product detail
// ---------------------------------------------------------------------------
router.get('/products/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const productId = (0, http_1.getParam)(req.params.id, 'productId');
    const result = await (0, aliexpress_service_1.getProductDetail)(productId);
    if (!result.product) {
        return res.status(404).json({ error: 'Product not found on AliExpress.' });
    }
    const normalized = (0, aliexpress_service_1.normalizeProduct)(result.product);
    res.json(normalized);
}));
// ---------------------------------------------------------------------------
// Category tree
// ---------------------------------------------------------------------------
router.get('/categories', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const params = categoryQuerySchema.parse(req.query);
    const result = await (0, aliexpress_service_1.queryCategoryTree)(params.parentId);
    res.json({
        categories: result.categories,
    });
}));
// ---------------------------------------------------------------------------
// Token exchange (OAuth callback)
// ---------------------------------------------------------------------------
router.post('/auth/token', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const params = tokenExchangeSchema.parse(req.body);
    const tokenResult = await (0, aliexpress_service_1.exchangeCodeForToken)(params.code);
    res.json({
        accessToken: tokenResult.accessToken,
        refreshToken: tokenResult.refreshToken,
        expireTime: tokenResult.expireTime,
    });
}));
// ---------------------------------------------------------------------------
// Token refresh
// ---------------------------------------------------------------------------
router.post('/auth/refresh', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const params = tokenRefreshSchema.parse(req.body);
    const tokenResult = await (0, aliexpress_service_1.refreshAccessToken)(params.refreshToken);
    res.json({
        accessToken: tokenResult.accessToken,
        refreshToken: tokenResult.refreshToken,
        expireTime: tokenResult.expireTime,
    });
}));
// ---------------------------------------------------------------------------
// Orders list
// ---------------------------------------------------------------------------
router.get('/orders', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const params = orderQuerySchema.parse(req.query);
    const result = await (0, aliexpress_service_1.queryOrderList)(params.accessToken, {
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
}));
// ---------------------------------------------------------------------------
// Order detail
// ---------------------------------------------------------------------------
router.get('/orders/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const orderId = (0, http_1.getParam)(req.params.id, 'orderId');
    // accessToken comes from query params for GET requests
    const accessToken = req.query.accessToken ?? '';
    if (!accessToken || accessToken.trim().length === 0) {
        return res.status(400).json({ error: 'Access token is required.' });
    }
    const result = await (0, aliexpress_service_1.queryOrderDetail)(accessToken, orderId);
    if (!result.order) {
        return res.status(404).json({ error: 'Order not found.' });
    }
    res.json(result.order);
}));
// ---------------------------------------------------------------------------
// Webhook receiver for AliExpress order status push
// ---------------------------------------------------------------------------
router.post('/webhook', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const authorization = req.headers.authorization;
    const rawBody = req.body;
    // Body should be the raw JSON string for signature verification
    const bodyString = typeof rawBody === 'string' ? rawBody : JSON.stringify(rawBody);
    // Verify signature (recommended but not mandatory per docs)
    if (authorization) {
        const isValid = (0, aliexpress_service_1.verifyWebhookSignature)(authorization, bodyString);
        if (!isValid) {
            console.warn('[AliExpress Webhook] Invalid signature — rejecting');
            return res.status(401).json({ error: 'Invalid signature' });
        }
    }
    // Parse the webhook data
    const webhookData = typeof rawBody === 'string'
        ? JSON.parse(rawBody)
        : rawBody;
    const messageType = Number(webhookData.message_type ?? 0);
    const sellerId = String(webhookData.seller_id ?? '');
    const data = webhookData.data;
    console.log(`[AliExpress Webhook] message_type=${messageType} seller_id=${sellerId}`);
    // Handle order status updates
    // message_type 1 = online order successfully (PLACE_ORDER_SUCCESS)
    // message_type 6 = waiting for shipping
    // message_type 12 = transaction successful (FINISH)
    if (data &&
        typeof data.trade_order_id === 'string' &&
        typeof data.order_status === 'string') {
        const aliexpressOrderId = data.trade_order_id;
        const orderStatus = data.order_status;
        // Update local order status if we have a matching order
        try {
            await db_1.prisma.order.updateMany({
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
        }
        catch (err) {
            console.error(`[AliExpress Webhook] Failed to update order ${aliexpressOrderId}:`, err);
        }
    }
    // Must respond 200 OK within 500ms per AliExpress requirements
    res.status(200).json({ success: true });
}));
// ---------------------------------------------------------------------------
// Cache management (admin/debug)
// ---------------------------------------------------------------------------
router.post('/cache/clear', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    (0, aliexpress_service_1.clearAliExpressCache)();
    res.json({ success: true, message: 'AliExpress cache cleared.' });
}));
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function mapAliExpressOrderStatus(aeStatus) {
    const statusMap = {
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
exports.default = router;
