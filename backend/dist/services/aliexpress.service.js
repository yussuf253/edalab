"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearAliExpressCache = clearAliExpressCache;
exports.extractAliExpressError = extractAliExpressError;
exports.throwIfAliExpressError = throwIfAliExpressError;
exports.queryCategoryTree = queryCategoryTree;
exports.searchProducts = searchProducts;
exports.getProductDetail = getProductDetail;
exports.exchangeCodeForToken = exchangeCodeForToken;
exports.refreshAccessToken = refreshAccessToken;
exports.queryOrderList = queryOrderList;
exports.queryOrderDetail = queryOrderDetail;
exports.parsePrice = parsePrice;
exports.parseRating = parseRating;
exports.normalizeProduct = normalizeProduct;
exports.verifyWebhookSignature = verifyWebhookSignature;
const crypto_1 = __importDefault(require("crypto"));
const env_1 = require("../config/env");
// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const ALIEXPRESS_APP_KEY = env_1.env.ALIEXPRESS_APP_KEY ?? '';
const ALIEXPRESS_APP_SECRET = env_1.env.ALIEXPRESS_APP_SECRET ?? '';
const ALIEXPRESS_GATEWAY_URL = env_1.env.ALIEXPRESS_GATEWAY_URL ?? 'https://api-sg.aliexpress.com';
const ALIEXPRESS_TRACKING_ID = env_1.env.ALIEXPRESS_TRACKING_ID ?? '';
const SIGN_METHOD = 'sha256';
const _cache = new Map();
function cacheKey(url) {
    return url;
}
function getCached(key, ttlMs) {
    const entry = _cache.get(key);
    if (!entry)
        return null;
    if (Date.now() - entry.cachedAt > ttlMs) {
        _cache.delete(key);
        return null;
    }
    return entry.body;
}
function setCache(key, body) {
    // Limit cache size to 500 entries
    if (_cache.size > 500) {
        const oldest = _cache.keys().next().value;
        if (oldest !== undefined)
            _cache.delete(oldest);
    }
    _cache.set(key, { body, cachedAt: Date.now() });
}
function clearAliExpressCache(prefix) {
    if (!prefix) {
        _cache.clear();
        return;
    }
    for (const key of _cache.keys()) {
        if (key.includes(prefix))
            _cache.delete(key);
    }
}
// ---------------------------------------------------------------------------
// Signature generation (HMAC-SHA256)
// ---------------------------------------------------------------------------
/**
 * Generate HMAC-SHA256 signature for AliExpress Open Platform API request.
 *
 * Business Interfaces: api_path is included as `method` param in the sorted params.
 * System Interfaces:   api_path is PREPENDED to the concatenated string.
 */
function signRequest(params, apiPath, isSystemApi) {
    // Step 1: Sort params by key alphabetically (ASCII order)
    const sortedKeys = Object.keys(params).sort();
    // Step 2: Concatenate key+value pairs
    let concatenated = '';
    for (const key of sortedKeys) {
        const value = params[key];
        if (key && value) {
            concatenated += key + value;
        }
    }
    // Step 3: For System APIs, prepend the API path
    if (isSystemApi) {
        concatenated = apiPath + concatenated;
    }
    // Step 4: HMAC-SHA256 digest
    const hmac = crypto_1.default.createHmac('sha256', ALIEXPRESS_APP_SECRET);
    hmac.update(concatenated, 'utf8');
    const digest = hmac.digest();
    // Step 5: Convert to uppercase hex string
    return digest.toString('hex').toUpperCase();
}
// ---------------------------------------------------------------------------
// Public API call helpers
// ---------------------------------------------------------------------------
function isSystemApi(apiPath) {
    return apiPath.startsWith('/auth/');
}
function buildTimestamp() {
    // Official docs use millisecond epoch as a string
    return Date.now().toString();
}
async function callAliExpressRaw(apiPath, businessParams, options) {
    if (!ALIEXPRESS_APP_KEY || !ALIEXPRESS_APP_SECRET) {
        throw new Error('AliExpress credentials not configured. Set ALIEXPRESS_APP_KEY and ALIEXPRESS_APP_SECRET.');
    }
    const systemApi = isSystemApi(apiPath);
    // Build the full parameter set
    const allParams = {
        app_key: ALIEXPRESS_APP_KEY,
        timestamp: buildTimestamp(),
        sign_method: SIGN_METHOD,
        simplify: 'true',
        ...businessParams,
    };
    // Add access_token if provided
    if (options?.accessToken) {
        allParams.access_token = options.accessToken;
    }
    // For Business APIs, `method` is the api_path (already in businessParams)
    // For System APIs, api_path is part of the URL path
    // Generate signature
    const sign = signRequest(allParams, apiPath, systemApi);
    allParams.sign = sign;
    // Build the URL
    const baseHost = ALIEXPRESS_GATEWAY_URL.replace(/\/+$/, '');
    let requestUrl;
    if (systemApi) {
        // System Interface: {base}/rest{api_path}?{query}
        requestUrl = `${baseHost}/rest${apiPath}`;
    }
    else {
        // Business Interface: {base}/sync?method={api_path}&{query}
        requestUrl = `${baseHost}/sync`;
        allParams.method = apiPath;
    }
    // Build query string
    const queryString = Object.entries(allParams)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');
    const fullUrl = `${requestUrl}?${queryString}`;
    // Check cache for GET-like operations
    if (options?.useCache) {
        const ttl = options.cacheTtlMs ?? 15 * 60 * 1000; // 15 min default
        const cached = getCached(cacheKey(fullUrl), ttl);
        if (cached) {
            return JSON.parse(cached);
        }
    }
    // Make the HTTP request
    const response = await fetch(fullUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        },
    });
    if (!response.ok) {
        throw new Error(`AliExpress API HTTP error: ${response.status} ${response.statusText}`);
    }
    const body = await response.text();
    const parsed = JSON.parse(body);
    // Cache successful responses
    if (options?.useCache && response.ok) {
        setCache(cacheKey(fullUrl), body);
    }
    return parsed;
}
function extractAliExpressError(response) {
    const errorResponse = response.error_response;
    if (!errorResponse)
        return null;
    const code = Number(errorResponse.code ?? 0);
    const msg = String(errorResponse.msg ?? 'Unknown AliExpress error');
    const requestId = errorResponse.request_id;
    let errorType = 'SYSTEM';
    if (code >= 20000 && code < 30000)
        errorType = 'ISV';
    if (code >= 30000)
        errorType = 'ISP';
    return { code, msg, requestId, errorType };
}
function throwIfAliExpressError(response) {
    const error = extractAliExpressError(response);
    if (error) {
        const details = error.requestId ? ` (request_id: ${error.requestId})` : '';
        throw new Error(`AliExpress API [${error.errorType}] ${error.code}: ${error.msg}${details}`);
    }
}
/**
 * Get child categories under a parent category.
 * Pass parentId=0 to get top-level categories.
 */
async function queryCategoryTree(parentId = 0) {
    const response = await callAliExpressRaw('aliexpress.solution.seller.category.tree.query', {
        parent_category_id: parentId.toString(),
        filter_no_permission: 'false',
    });
    throwIfAliExpressError(response);
    const treeResponse = response;
    const inner = treeResponse
        .aliexpress_solution_seller_category_tree_query_response;
    const childrenCategoryList = inner?.children_category_list;
    const categoryInfoArray = childrenCategoryList?.category_info;
    const categories = (categoryInfoArray ?? []).map((cat) => {
        const namesRaw = cat.multi_language_names;
        let name = '';
        if (namesRaw) {
            try {
                const parsed = JSON.parse(namesRaw);
                name = parsed.en ?? parsed.zh ?? Object.values(parsed)[0] ?? '';
            }
            catch {
                name = '';
            }
        }
        return {
            id: Number(cat.children_category_id ?? 0),
            name,
            isLeaf: cat.is_leaf_category === true,
            level: Number(cat.level ?? 0),
        };
    });
    return {
        categories,
        requestId: inner?.request_id ?? undefined,
    };
}
/**
 * Search products via AliExpress.
 */
async function searchProducts(params) {
    const businessParams = {
        keywords: params.keywords,
        page_no: (params.pageNo ?? 1).toString(),
        page_size: (params.pageSize ?? 20).toString(),
        target_currency: params.targetCurrency ?? 'USD',
        target_language: params.targetLanguage ?? 'EN',
        sort: params.sort ?? 'DEFAULT',
    };
    if (ALIEXPRESS_TRACKING_ID) {
        businessParams.tracking_id = ALIEXPRESS_TRACKING_ID;
    }
    const response = await callAliExpressRaw('aliexpress.affiliate.product.query', businessParams, { useCache: true, cacheTtlMs: 10 * 60 * 1000 });
    throwIfAliExpressError(response);
    const queryResponse = response;
    const respResult = queryResponse
        .aliexpress_affiliate_product_query_response;
    const result = respResult?.resp_result?.result;
    const productsWrapper = result?.products;
    const productArray = productsWrapper?.product;
    const products = (productArray ?? []).map((p) => {
        const imagesRaw = p.product_images;
        let productImages = [];
        if (typeof imagesRaw === 'string') {
            try {
                const parsed = JSON.parse(imagesRaw);
                productImages = Array.isArray(parsed) ? parsed : [];
            }
            catch {
                productImages = [];
            }
        }
        else if (Array.isArray(imagesRaw)) {
            productImages = imagesRaw;
        }
        return {
            productId: String(p.product_id ?? ''),
            productTitle: String(p.product_title ?? ''),
            salePrice: String(p.sale_price ?? ''),
            productMainImageUrl: String(p.product_main_image_url ?? ''),
            productImages,
            evaluateRate: String(p.evaluate_rate ?? ''),
            lastestVolume: Number(p.lastest_volume ?? 0),
            promotionLink: String(p.promotion_link ?? ''),
            storeName: String(p.store_name ?? ''),
            storeId: String(p.store_id ?? ''),
            categoryId: String(p.category_id ?? ''),
            originalPrice: p.original_price
                ? String(p.original_price)
                : undefined,
            targetCurrency: p.target_currency
                ? String(p.target_currency)
                : undefined,
        };
    });
    return {
        products,
        totalRecords: Number(result?.total_record_count ?? 0),
        currentPage: Number(result?.current_page_no ?? params.pageNo ?? 1),
        requestId: respResult?.request_id ?? undefined,
    };
}
/**
 * Get single product details by product ID.
 */
async function getProductDetail(productId) {
    const response = await callAliExpressRaw('aliexpress.affiliate.productdetail.get', {
        product_ids: productId,
        target_currency: 'USD',
        target_language: 'EN',
        tracking_id: ALIEXPRESS_TRACKING_ID,
    }, { useCache: true, cacheTtlMs: 30 * 60 * 1000 });
    throwIfAliExpressError(response);
    const detailResponse = response;
    const inner = detailResponse
        .aliexpress_affiliate_productdetail_get_response;
    const respResult = inner?.resp_result;
    const result = respResult?.result;
    const productArray = result?.product;
    if (!productArray || productArray.length === 0) {
        return { product: null, requestId: inner?.request_id };
    }
    const p = productArray[0];
    const imagesRaw = p.product_images;
    let productImages = [];
    if (typeof imagesRaw === 'string') {
        try {
            const parsed = JSON.parse(imagesRaw);
            productImages = Array.isArray(parsed) ? parsed : [];
        }
        catch {
            productImages = [];
        }
    }
    else if (Array.isArray(imagesRaw)) {
        productImages = imagesRaw;
    }
    return {
        product: {
            productId: String(p.product_id ?? ''),
            productTitle: String(p.product_title ?? ''),
            salePrice: String(p.sale_price ?? ''),
            productMainImageUrl: String(p.product_main_image_url ?? ''),
            productImages,
            evaluateRate: String(p.evaluate_rate ?? ''),
            lastestVolume: Number(p.lastest_volume ?? 0),
            promotionLink: String(p.promotion_link ?? ''),
            storeName: String(p.store_name ?? ''),
            storeId: String(p.store_id ?? ''),
            categoryId: String(p.category_id ?? ''),
            originalPrice: p.original_price
                ? String(p.original_price)
                : undefined,
            targetCurrency: p.target_currency
                ? String(p.target_currency)
                : undefined,
        },
        requestId: inner?.request_id ?? undefined,
    };
}
/**
 * Exchange authorization code for access token (System API).
 * POST to {base}/rest/auth/token/create?{signed_params}
 */
async function exchangeCodeForToken(code) {
    const response = await callAliExpressRaw('/auth/token/create', {
        code,
    });
    throwIfAliExpressError(response);
    const tokenResponse = response;
    const accessToken = String(tokenResponse.access_token ?? '');
    const refreshToken = String(tokenResponse.refresh_token ?? '');
    const expireTime = String(tokenResponse.expire_time ?? '');
    if (!accessToken) {
        throw new Error('AliExpress token exchange failed: no access_token returned');
    }
    return {
        accessToken,
        refreshToken,
        expireTime,
        requestId: tokenResponse.request_id ?? undefined,
    };
}
/**
 * Refresh an expired access token (System API).
 * POST to {base}/rest/auth/token/refresh?{signed_params}
 */
async function refreshAccessToken(refreshToken) {
    const response = await callAliExpressRaw('/auth/token/refresh', {
        refresh_token: refreshToken,
    });
    throwIfAliExpressError(response);
    const tokenResponse = response;
    const accessToken = String(tokenResponse.access_token ?? '');
    const newRefreshToken = String(tokenResponse.refresh_token ?? refreshToken);
    const expireTime = String(tokenResponse.expire_time ?? '');
    if (!accessToken) {
        throw new Error('AliExpress token refresh failed: no access_token returned');
    }
    return {
        accessToken,
        refreshToken: newRefreshToken,
        expireTime,
        requestId: tokenResponse.request_id ?? undefined,
    };
}
/**
 * Get order list for an authorized seller.
 */
async function queryOrderList(accessToken, params = {}) {
    const businessParams = {
        page_no: (params.pageNo ?? 1).toString(),
        page_size: (params.pageSize ?? 20).toString(),
    };
    if (params.createTimeStart)
        businessParams.create_time_start = params.createTimeStart;
    if (params.createTimeEnd)
        businessParams.create_time_end = params.createTimeEnd;
    if (params.orderStatus)
        businessParams.order_status = params.orderStatus;
    const response = await callAliExpressRaw('aliexpress.trade.order.list.query', businessParams, { accessToken });
    throwIfAliExpressError(response);
    const listResponse = response;
    const inner = listResponse
        .aliexpress_trade_order_list_query_response;
    const result = inner?.result;
    const orderArray = result?.order_list;
    const orders = (orderArray ?? []).map((o) => {
        const itemArray = o.order_list;
        return {
            orderId: String(o.order_id ?? ''),
            orderStatus: String(o.order_status ?? ''),
            totalAmount: String(o.total_amount ?? ''),
            currency: String(o.currency ?? ''),
            createTime: String(o.create_time ?? ''),
            updateTime: String(o.update_time ?? ''),
            items: (itemArray ?? []).map((item) => ({
                productId: String(item.product_id ?? ''),
                productTitle: String(item.product_title ?? ''),
                skuId: String(item.sku_id ?? ''),
                quantity: Number(item.quantity ?? 0),
                price: String(item.product_price ?? ''),
            })),
        };
    });
    return {
        orders,
        totalResults: Number(result?.total_results ?? 0),
        requestId: inner?.request_id ?? undefined,
    };
}
/**
 * Get order detail by order ID.
 */
async function queryOrderDetail(accessToken, orderId) {
    const response = await callAliExpressRaw('aliexpress.trade.order.detail.query', { order_id: orderId }, { accessToken });
    throwIfAliExpressError(response);
    const detailResponse = response;
    const inner = detailResponse
        .aliexpress_trade_order_detail_query_response;
    const result = inner?.result;
    if (!result) {
        return { order: null, requestId: inner?.request_id ?? undefined };
    }
    const itemArray = result.order_list;
    return {
        order: {
            orderId: String(result.order_id ?? ''),
            orderStatus: String(result.order_status ?? ''),
            totalAmount: String(result.total_amount ?? ''),
            currency: String(result.currency ?? ''),
            createTime: String(result.create_time ?? ''),
            updateTime: String(result.update_time ?? ''),
            items: (itemArray ?? []).map((item) => ({
                productId: String(item.product_id ?? ''),
                productTitle: String(item.product_title ?? ''),
                skuId: String(item.sku_id ?? ''),
                quantity: Number(item.quantity ?? 0),
                price: String(item.product_price ?? ''),
            })),
        },
        requestId: inner?.request_id ?? undefined,
    };
}
// ---------------------------------------------------------------------------
// Response normalization → ProductModel shape
// ---------------------------------------------------------------------------
/**
 * Parse price string like "USD 12.99" or "12.99" to a number.
 */
function parsePrice(priceStr) {
    const cleaned = priceStr.replace(/[^0-9.]/g, '');
    const parsed = parseFloat(cleaned);
    return Number.isFinite(parsed) ? parsed : 0;
}
/**
 * Parse evaluate rate "96.5%" to a 1-5 star rating.
 */
function parseRating(evaluateRate) {
    const cleaned = evaluateRate.replace(/[^0-9.]/g, '');
    const pct = parseFloat(cleaned);
    if (!Number.isFinite(pct))
        return 0;
    // Convert percentage (0-100) to 1-5 star rating
    return Math.round((pct / 100) * 5 * 10) / 10;
}
/**
 * Normalize an AliExpress product to the ProductModel shape used by the Flutter app.
 */
function normalizeProduct(product) {
    const price = parsePrice(product.salePrice);
    const originalPrice = product.originalPrice
        ? parsePrice(product.originalPrice)
        : undefined;
    return {
        id: product.productId,
        name: product.productTitle,
        brand: product.storeName,
        description: `Product from ${product.storeName} on AliExpress.`,
        price,
        originalPrice: originalPrice && originalPrice > price ? originalPrice : undefined,
        rating: parseRating(product.evaluateRate),
        reviewCount: product.lastestVolume,
        images: [
            product.productMainImageUrl,
            ...product.productImages.filter((img) => img !== product.productMainImageUrl),
        ].filter((img) => img.length > 0),
        colors: [],
        sizes: [],
        category: product.categoryId || 'Uncategorized',
        badge: product.lastestVolume > 1000 ? 'Best Seller' : undefined,
        inStock: true,
        features: [],
        shopId: product.storeId,
        shopName: product.storeName,
        // AliExpress-specific metadata
        metadata: {
            aliexpressProductId: product.productId,
            promotionLink: product.promotionLink,
            originalPrice,
            salePriceRaw: product.salePrice,
        },
    };
}
// ---------------------------------------------------------------------------
// Webhook signature verification
// ---------------------------------------------------------------------------
/**
 * Verify the Authorization header signature for AliExpress webhook callbacks.
 * Signature = HEX(HMAC-SHA256(appKey + messageBody, appSecret))
 */
function verifyWebhookSignature(authorizationHeader, messageBody) {
    const base = ALIEXPRESS_APP_KEY + messageBody;
    const hmac = crypto_1.default.createHmac('sha256', ALIEXPRESS_APP_SECRET);
    hmac.update(base, 'utf8');
    const expectedSignature = hmac.digest('hex').toLowerCase();
    return authorizationHeader.toLowerCase() === expectedSignature;
}
