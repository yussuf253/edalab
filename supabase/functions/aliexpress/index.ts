/**
 * AliExpress catalogue proxy — Drop Shipping API.
 *
 * App key 533838 is entitled to `AE-Dropshipper` + `System Tool`, not to the
 * Affiliate family (`aliexpress.affiliate.*` answers InsufficientPermission).
 * Catalogue reads therefore go through `aliexpress.ds.text.search` and
 * `aliexpress.ds.product.get`, which are "需要授权" (authorization required) and
 * carry a user `session` access token.
 *
 * Token lifecycle: the store owner authorizes once in the browser. AliExpress
 * redirects to `GET /functions/v1/aliexpress/callback` (register that exact URL
 * as the app callback), and `handleCallback` below exchanges the `code`, stores
 * the rotating token pair in `aliexpress_auth` (service role only) and reuses it
 * until it is close to expiry. `tool/aliexpress_connect.mjs` can do the same
 * exchange by hand when the browser redirect is unavailable.
 *
 * IMPORTANT: this function must be deployed with `--no-verify-jwt`, because the
 * browser redirect from AliExpress arrives without an Authorization header.
 *
 * Secrets:
 *   ALIEXPRESS_APP_KEY / ALIEXPRESS_APP_SECRET — Open Platform credentials
 *   ALIEXPRESS_REFRESH_TOKEN                  — bootstrap refresh token
 *   ALIEXPRESS_SHIP_TO / _CURRENCY / _LOCALE  — optional: US / USD / en_US
 */
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return Response.json(body, {
    status,
    headers: { ...corsHeaders, "Cache-Control": "no-store" },
  });
}

const APP_KEY = Deno.env.get("ALIEXPRESS_APP_KEY")?.trim() ?? "";
const APP_SECRET = Deno.env.get("ALIEXPRESS_APP_SECRET")?.trim() ?? "";
const BOOTSTRAP_REFRESH_TOKEN =
  Deno.env.get("ALIEXPRESS_REFRESH_TOKEN")?.trim() ?? "";
const GATEWAY_URL = (Deno.env.get("ALIEXPRESS_GATEWAY_URL") ??
  "https://api-sg.aliexpress.com").replace(/\/+$/, "");
const SUPABASE_URL = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/+$/, "");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SHIP_TO = (Deno.env.get("ALIEXPRESS_SHIP_TO") ?? "US").trim().toUpperCase();
const CURRENCY = (Deno.env.get("ALIEXPRESS_CURRENCY") ?? "USD").trim().toUpperCase();
const LOCALE = (Deno.env.get("ALIEXPRESS_LOCALE") ?? "en_US").trim();
const SIGN_METHOD = "sha256";
const REQUEST_TIMEOUT_MS = 20_000;
const TOKEN_TABLE = "aliexpress_auth";

/**
 * Feed name resolved from `ds.feedname.get`, cached per function instance.
 * Promo names are account specific (and rotate), so they are discovered rather
 * than hard-coded.
 */
let resolvedFeedName = "";

/** The app cannot call AliExpress until the store is authorized. */
class SetupError extends Error {}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

function asText(value: unknown): string {
  return value == null ? "" : String(value);
}

function toArray(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value) ? value as Record<string, unknown>[] : [];
}

function positiveInt(
  value: unknown,
  fallback: number,
  max = Number.MAX_SAFE_INTEGER,
): number {
  const parsed = Number(asText(value).replace(/[^0-9]/g, ""));
  if (!Number.isFinite(parsed) || parsed < 1) return fallback;
  return Math.min(Math.floor(parsed), max);
}

/** `"1.83"` → `1.83`, `"USD 12.99"` → `12.99`, unparsable → `0`. */
function toNumberText(value: unknown): number {
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : 0;
  }
  const parsed = parseFloat(asText(value).replace(/[^0-9.]/g, ""));
  return Number.isFinite(parsed) ? parsed : 0;
}

/** `"10,000+"` → `10000`. */
function toCount(value: unknown): number {
  return Math.trunc(toNumberText(value));
}

/** `score` is already 0–5; `evaluateRate` is a percentage. */
function ratingOf(score: unknown, evaluateRate: unknown): number {
  const direct = toNumberText(score);
  if (direct > 0 && direct <= 5) return Math.round(direct * 10) / 10;
  const percent = toNumberText(evaluateRate);
  if (percent > 0) return Math.round((percent / 100) * 5 * 10) / 10;
  return 0;
}

/** AliExpress returns protocol-relative image and product URLs. */
function absoluteUrl(value: string): string {
  const url = value.trim();
  if (!url) return "";
  if (url.startsWith("//")) return `https:${url}`;
  if (url.startsWith("http://")) return `https://${url.slice(7)}`;
  return url;
}

// ---------------------------------------------------------------------------
// Response cache (best effort: a function instance lives for minutes)
// ---------------------------------------------------------------------------

type CacheEntry = { body: string; cachedAt: number };

const cache = new Map<string, CacheEntry>();
const CACHE_LIMIT = 200;

async function cached<T>(
  key: string,
  ttlMs: number,
  load: () => Promise<T>,
): Promise<T> {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.cachedAt <= ttlMs) {
    try {
      return JSON.parse(hit.body) as T;
    } catch {
      cache.delete(key);
    }
  }
  const value = await load();
  if (cache.size >= CACHE_LIMIT) cache.clear();
  cache.set(key, { body: JSON.stringify(value), cachedAt: Date.now() });
  return value;
}

// ---------------------------------------------------------------------------
// Signing + transport
// ---------------------------------------------------------------------------

function toHex(buffer: ArrayBuffer): string {
  return [...new Uint8Array(buffer)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}

/**
 * Signature = upper-case HEX(HMAC-SHA256(secret, concatenated)).
 *
 * Business (`/sync`) interfaces sign the sorted `key + value` pairs; system
 * (`/rest/auth/…`) interfaces prefix the API path.
 */
async function signRequest(
  params: Record<string, string>,
  apiPath: string,
  isSystemApi: boolean,
): Promise<string> {
  let concatenated = Object.keys(params)
    .sort()
    .map((key) => (key && params[key] ? key + params[key] : ""))
    .join("");

  if (isSystemApi) concatenated = apiPath + concatenated;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(APP_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(concatenated),
  );
  return toHex(digest);
}

async function post(url: string): Promise<Record<string, unknown>> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
      },
      signal: controller.signal,
    });
  } catch (error) {
    const aborted = error instanceof DOMException &&
      error.name === "AbortError";
    throw new Error(
      aborted
        ? "AliExpress did not respond in time."
        : "AliExpress could not be reached.",
    );
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new Error(
      `HTTP ${response.status} from AliExpress: ${detail.slice(0, 400)}`,
    );
  }

  const body = await response.text();
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(body) as Record<string, unknown>;
  } catch {
    throw new Error(
      `AliExpress returned a non-JSON body: ${body.slice(0, 400)}`,
    );
  }

  const errorResponse = parsed.error_response as
    | Record<string, unknown>
    | undefined;
  if (errorResponse) {
    const code = asText(errorResponse.code).trim() || "unknown";
    const message = asText(errorResponse.msg).trim() ||
      "Unknown AliExpress error";
    throw new Error(`AliExpress error ${code}: ${message}`);
  }

  return parsed;
}

/** `/rest/auth/token/*` — signed with the API path as a prefix. */
async function callSystemApi(
  apiPath: string,
  businessParams: Record<string, string>,
): Promise<Record<string, unknown>> {
  const params: Record<string, string> = {
    app_key: APP_KEY,
    timestamp: Date.now().toString(),
    sign_method: SIGN_METHOD,
    ...businessParams,
  };
  params.sign = await signRequest(params, apiPath, true);

  const query = Object.entries(params)
    .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
    .join("&");
  return await post(`${GATEWAY_URL}/rest${apiPath}?${query}`);
}

/** `/sync` business interface: the access token travels as `session`. */
async function callBusinessApi(
  apiPath: string,
  businessParams: Record<string, string>,
  session: string,
  options?: { cacheable?: boolean },
): Promise<Record<string, unknown>> {
  const params: Record<string, string> = {
    app_key: APP_KEY,
    timestamp: Date.now().toString(),
    sign_method: SIGN_METHOD,
    format: "json",
    v: "2.0",
    session,
    method: apiPath,
    ...businessParams,
  };
  params.sign = await signRequest(params, apiPath, false);

  const query = Object.entries(params)
    .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
    .join("&");
  const url = `${GATEWAY_URL}/sync?${query}`;

  if (!options?.cacheable) return await post(url);
  return await cached(url, 10 * 60 * 1000, () => post(url));
}

/** Unwraps `<method>_response` and turns a non-success `code` into a throw. */
function unwrap(
  payload: Record<string, unknown>,
  wrapperKey: string,
): Record<string, unknown> {
  const inner = (payload[wrapperKey] ?? {}) as Record<string, unknown>;
  const code = asText(inner.code).trim();
  if (code && code !== "00" && code !== "200") {
    const message = asText(inner.msg).trim() || asText(inner.message).trim() ||
      "Unknown AliExpress error";
    throw new Error(`AliExpress error ${code}: ${message}`);
  }
  return inner;
}

/** The payload sometimes sits at `result`, sometimes at `resp_result.result`. */
function resultOf(inner: Record<string, unknown>): Record<string, unknown> {
  const direct = inner.result;
  if (direct && typeof direct === "object") {
    return direct as Record<string, unknown>;
  }
  const respResult = inner.resp_result;
  if (respResult && typeof respResult === "object") {
    const nested = (respResult as Record<string, unknown>).result;
    if (nested && typeof nested === "object") {
      return nested as Record<string, unknown>;
    }
  }
  return {};
}

// ---------------------------------------------------------------------------
// Access token
// ---------------------------------------------------------------------------

type Tokens = {
  access_token: string;
  refresh_token: string;
  /** Epoch milliseconds. */
  expires_at: number;
};

let memoryTokens: Tokens | null = null;

function serviceHeaders(): Record<string, string> {
  return {
    apikey: SERVICE_ROLE_KEY,
    Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
    "Content-Type": "application/json",
  };
}

async function loadTokens(): Promise<Tokens | null> {
  if (memoryTokens) return memoryTokens;
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return null;
  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/${TOKEN_TABLE}` +
        `?id=eq.1&select=access_token,refresh_token,expires_at`,
      { headers: serviceHeaders() },
    );
    if (!response.ok) return null; // table not migrated yet — memory only
    const rows = await response.json() as Record<string, unknown>[];
    const row = rows[0];
    if (!row) return null;
    const expires = Date.parse(asText(row.expires_at));
    memoryTokens = {
      access_token: asText(row.access_token).trim(),
      refresh_token: asText(row.refresh_token).trim(),
      expires_at: Number.isFinite(expires) ? expires : 0,
    };
    return memoryTokens;
  } catch {
    return null;
  }
}

/** Returns false only when the durable copy could not be written. */
async function saveTokens(tokens: Tokens): Promise<boolean> {
  memoryTokens = tokens;
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return false;
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/${TOKEN_TABLE}`, {
      method: "POST",
      headers: {
        ...serviceHeaders(),
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify({
        id: 1,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expires_at: new Date(tokens.expires_at).toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });
    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      console.error("aliexpress_auth write failed.", {
        status: response.status,
        detail: detail.slice(0, 300),
      });
      return false;
    }
    return true;
  } catch (error) {
    console.error("aliexpress_auth write failed.", {
      error: error instanceof Error ? error.message : String(error),
    });
    return false;
  }
}

function tokenPayload(
  response: Record<string, unknown>,
): Record<string, unknown> {
  for (const key of ["token_create_response", "token_refresh_response"]) {
    const inner = response[key];
    if (inner && typeof inner === "object") {
      return inner as Record<string, unknown>;
    }
  }
  return response;
}

/** Returns a valid access token, refreshing it when it is about to expire. */
async function accessToken(): Promise<string> {
  const stored = await loadTokens();
  const now = Date.now();
  if (stored?.access_token && stored.expires_at - 120_000 > now) {
    return stored.access_token;
  }

  const refreshToken = stored?.refresh_token || BOOTSTRAP_REFRESH_TOKEN;
  if (!refreshToken) throw new SetupError("AliExpress is not connected yet.");

  let response: Record<string, unknown>;
  try {
    response = await callSystemApi("/auth/token/refresh", {
      refresh_token: refreshToken,
    });
  } catch (error) {
    console.error("AliExpress token refresh failed.", {
      error: error instanceof Error ? error.message : String(error),
    });
    throw new SetupError("AliExpress needs to be reconnected.");
  }

  const payload = tokenPayload(response);
  const access = asText(payload.access_token).trim();
  if (!access) {
    console.error("AliExpress token refresh returned no access token.", {
      keys: Object.keys(payload).join(","),
    });
    throw new SetupError("AliExpress needs to be reconnected.");
  }

  const tokens: Tokens = {
    access_token: access,
    refresh_token: asText(payload.refresh_token).trim() || refreshToken,
    expires_at: now + (Number(payload.expires_in) || 3600) * 1000,
  };
  await saveTokens(tokens);
  return tokens.access_token;
}

// ---------------------------------------------------------------------------
// Normalization → ProductModel shape used by the Flutter app
// ---------------------------------------------------------------------------

function normalizeSearchProduct(row: Record<string, unknown>) {
  const id = asText(row.itemId ?? row.product_id ?? row.item_id).trim();
  const name = asText(row.title ?? row.product_title ?? row.subject).trim();
  const image = absoluteUrl(
    asText(row.itemMainPic ?? row.product_main_image_url),
  );
  const price = toNumberText(
    row.targetSalePrice ?? row.target_sale_price ?? row.salePrice ??
      row.sale_price,
  );
  const originalPrice = toNumberText(
    row.targetOriginalPrice ?? row.target_original_price ?? row.originalPrice ??
      row.original_price,
  );
  const orders = toCount(row.orders ?? row.lastest_volume ?? row.trade_count);
  const rating = ratingOf(row.score, row.evaluateRate ?? row.evaluate_rate);
  const productUrl = absoluteUrl(
    asText(row.itemUrl ?? row.product_detail_url ?? row.productUrl),
  );
  const shopName = asText(row.store_name ?? row.shopName).trim();

  return {
    id,
    name,
    brand: shopName,
    description: "Sold on AliExpress.",
    price,
    originalPrice: originalPrice > price ? originalPrice : undefined,
    rating,
    reviewCount: orders,
    images: image ? [image] : [],
    colors: [] as string[],
    sizes: [] as string[],
    category: asText(row.first_level_category_name).trim() || "AliExpress",
    badge: orders > 1000 ? "Best Seller" : undefined,
    inStock: true,
    features: [] as string[],
    shopId: asText(row.store_id).trim(),
    shopName,
    metadata: {
      aliexpressProductId: id,
      productUrl,
      discount: asText(row.discount).trim(),
    },
  };
}

function skuRows(result: Record<string, unknown>): Record<string, unknown>[] {
  const container = result.ae_item_sku_info_dtos;
  if (!container || typeof container !== "object") return [];
  const list = (container as Record<string, unknown>).ae_item_sku_info_d_t_o;
  return toArray(list);
}

function normalizeProductDetail(result: Record<string, unknown>) {
  const base = (result.ae_item_base_info_dto ?? {}) as Record<string, unknown>;
  const media = (result.ae_multimedia_info_dto ?? {}) as Record<string, unknown>;
  const store = (result.ae_store_info ?? {}) as Record<string, unknown>;
  const skus = skuRows(result);

  const id = asText(base.product_id ?? result.product_id).trim();
  const name = asText(base.subject ?? base.product_title).trim();

  const images = asText(media.image_urls)
    .split(";")
    .map((url) => absoluteUrl(url))
    .filter((url) => url.length > 0);

  const colors = new Set<string>();
  const sizes = new Set<string>();
  let price = 0;
  let originalPrice = 0;
  let inStock = true;

  for (const sku of skus) {
    const sale = toNumberText(
      sku.offer_sale_price ?? sku.sku_price ?? sku.sku_sale_price,
    );
    const list = toNumberText(sku.sku_price ?? sku.offer_sale_price);
    if (sale > 0 && (price === 0 || sale < price)) price = sale;
    if (list > 0 && (originalPrice === 0 || list < originalPrice)) {
      originalPrice = list;
    }
    if (sku.sku_stock === false || toNumberText(sku.sku_available_stock) === 0) {
      // A single sold-out variant does not make the product unavailable.
    }
    const attributes = asText(sku.sku_attr);
    for (const pair of attributes.split(";")) {
      const [rawKey, ...rest] = pair.split(":");
      const value = rest.join(":").trim();
      if (!value) continue;
      const key = rawKey.trim().toLowerCase();
      if (key.includes("color") || key.includes("colour")) colors.add(value);
      else if (key.includes("size")) sizes.add(value);
    }
  }

  if (skus.length === 0 || price === 0) {
    inStock = false;
  }

  const productUrl = id
    ? `https://www.aliexpress.com/item/${id}.html`
    : "";

  return {
    id,
    name,
    brand: asText(store.store_name).trim(),
    description: asText(base.detail) ? ""
      : `Product from ${asText(store.store_name).trim() || "AliExpress"}.`,
    price,
    originalPrice: originalPrice > price ? originalPrice : undefined,
    rating: ratingOf(
      base.average_star_rating ?? result.average_star_rating,
      base.evaluate_rate,
    ),
    reviewCount: toCount(
      base.evaluation_count ?? result.evaluation_count ?? base.review_count,
    ),
    images: images.length > 0 ? images : (
      asText(media.image_url).trim() ? [absoluteUrl(asText(media.image_url))] : []
    ),
    colors: [...colors],
    sizes: [...sizes],
    category: asText(base.category_id).trim() || "AliExpress",
    badge: undefined as string | undefined,
    inStock,
    features: [] as string[],
    shopId: asText(store.store_id).trim(),
    shopName: asText(store.store_name).trim(),
    metadata: {
      aliexpressProductId: id,
      productUrl,
      status: asText(base.product_status_type).trim(),
      currency: asText(base.currency_code).trim(),
    },
  };
}

/** Maps the app's sort values onto the Drop Shipping `sort` vocabulary. */
function dsSort(value: unknown): string {
  const raw = asText(value).trim();
  if (!raw) return "";
  const byValue: Record<string, string> = {
    SALE_PRICE_ASC: "priceAsc",
    SALE_PRICE_DESC: "priceDesc",
    LAST_VOLUME_ASC: "volumeAsc",
    LAST_VOLUME_DESC: "volumeDesc",
    DISCOUNT_ASC: "discountAsc",
    DISCOUNT_DESC: "discountDesc",
    RATING_ASC: "DSRratingAsc",
    RATING_DESC: "DSRratingDesc",
    DEFAULT: "",
  };
  const mapped = byValue[raw.toUpperCase()];
  if (mapped !== undefined) return mapped;
  if (/^[a-zA-Z]+$/.test(raw)) return raw; // already camelCase
  return "";
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

async function handleSearch(body: Record<string, unknown>) {
  const keywords = asText(body.q ?? body.keywords).trim();
  if (!keywords) {
    return json({ error: "Search query is required." }, 400);
  }

  const page = positiveInt(body.page, 1);
  const pageSize = positiveInt(body.pageSize, 20, 50);

  const params: Record<string, string> = {
    keyword: keywords,
    countryCode: SHIP_TO,
    currency: CURRENCY,
    local: LOCALE,
    page_size: pageSize.toString(),
    page_index: page.toString(),
  };
  const sort = dsSort(body.sort);
  if (sort) params.sort = sort;

  const categoryId = asText(body.categoryId).trim();
  if (categoryId && categoryId !== "0") params.category_id = categoryId;

  const session = await accessToken();
  const response = await callBusinessApi(
    "aliexpress.ds.text.search",
    params,
    session,
    { cacheable: true },
  );
  const inner = unwrap(response, "aliexpress_ds_text_search_response");
  const data = (inner.data ?? {}) as Record<string, unknown>;
  const container = (data.products ?? {}) as Record<string, unknown>;
  const rows = toArray(container.selection_search_product);
  const totalRecords = toCount(data.totalCount) || rows.length;

  return json({
    products: rows.map((row) => normalizeSearchProduct(row)),
    pagination: {
      totalRecords,
      currentPage: positiveInt(data.pageIndex, page),
      pageSize: positiveInt(data.pageSize, pageSize),
      totalPages: Math.max(1, Math.ceil(totalRecords / pageSize)),
    },
  });
}

async function handleProduct(body: Record<string, unknown>) {
  const productId = asText(body.productId).trim();
  if (!productId) {
    return json({ error: "Product ID is required." }, 400);
  }

  const session = await accessToken();
  const response = await callBusinessApi(
    "aliexpress.ds.product.get",
    {
      product_id: productId,
      ship_to_country: SHIP_TO,
      target_currency: CURRENCY,
      target_language: "EN",
    },
    session,
  );

  const result = resultOf(
    unwrap(response, "aliexpress_ds_product_get_response"),
  );
  if (!result.ae_item_base_info_dto) {
    return json({ error: "Product not found on AliExpress." }, 404);
  }
  return json(normalizeProductDetail(result));
}

async function handleCategories(body: Record<string, unknown>) {
  const parentId = positiveInt(body.parentId, 0);

  const session = await accessToken();
  const response = await callBusinessApi(
    "aliexpress.ds.category.get",
    {
      category_id: parentId.toString(),
      language: "en",
    },
    session,
    { cacheable: true },
  );

  const result = resultOf(
    unwrap(response, "aliexpress_ds_category_get_response"),
  );
  const container = (result.categories ?? {}) as Record<string, unknown>;
  const rows = toArray(container.category ?? container.categories);

  return json({
    categories: rows.map((category) => ({
      id: toCount(category.category_id),
      name: asText(category.category_name).trim(),
      isLeaf: category.is_leaf_category === true,
      level: toCount(category.level),
    })),
  });
}

/** Feed rows arrive either as an array or wrapped in a named DTO container. */
function feedRows(result: Record<string, unknown>): Record<string, unknown>[] {
  for (const container of [result, result.products]) {
    if (Array.isArray(container)) {
      return container as Record<string, unknown>[];
    }
    if (!container || typeof container !== "object") continue;
    const box = container as Record<string, unknown>;
    for (
      const key of [
        "traffic_product_d_t_o",
        "product",
        "products",
        "item_list",
        "selection_search_product",
      ]
    ) {
      if (Array.isArray(box[key])) {
        return box[key] as Record<string, unknown>[];
      }
    }
  }
  return [];
}

/**
 * `aliexpress.ds.recommend.feed.get` — the browsable storefront feed.
 *
 * Unlike `ds.text.search` (which ignores its paging parameters and answers a
 * random 20 rows per call), the feed honours `page_no` / `page_size` and takes
 * a `category_id`, so it is what the tab uses for browsing and infinite scroll.
 */
async function handleFeed(body: Record<string, unknown>) {
  const page = positiveInt(body.page, 1);
  const pageSize = positiveInt(body.pageSize, 20, 50);
  const session = await accessToken();
  const feedName = asText(body.feedName).trim() || await defaultFeedName(session);

  const params: Record<string, string> = {
    feed_name: feedName,
    country: SHIP_TO,
    target_currency: CURRENCY,
    target_language: "EN",
    page_size: pageSize.toString(),
    page_no: page.toString(),
  };
  const categoryId = asText(body.categoryId).trim();
  if (categoryId && categoryId !== "0") params.category_id = categoryId;
  const sort = dsSort(body.sort);
  if (sort) params.sort = sort;

  const response = await callBusinessApi(
    "aliexpress.ds.recommend.feed.get",
    params,
    session,
    { cacheable: true },
  );
  const inner = unwrap(response, "aliexpress_ds_recommend_feed_get_response");
  const result = resultOf(inner);

  const rows = feedRows(result);
  const totalRecords = toCount(
    result.total_record_count ?? result.totalRecordCount,
  );
  const currentPage = positiveInt(
    result.current_page_no ?? result.currentPageNo,
    page,
  );
  const totalPages = positiveInt(
    result.total_page_no ?? result.totalPageNo,
    Math.max(1, Math.ceil(totalRecords / pageSize)),
  );

  return json({
    products: rows.map((row) => normalizeSearchProduct(row)),
    pagination: {
      totalRecords,
      currentPage,
      pageSize,
      totalPages,
      hasMore: rows.length > 0 && currentPage < totalPages,
    },
  });
}

/** `aliexpress.ds.feedname.get` — the feed names `handleFeed` accepts. */
function promoRows(result: Record<string, unknown>): Record<string, unknown>[] {
  const promos = result.promos;
  if (!promos || typeof promos !== "object") return [];
  return toArray((promos as Record<string, unknown>).promo);
}

/**
 * Picks the storefront feed to browse: the largest promo that looks like a
 * bestseller/choice set, falling back to the largest promo overall. Promos with
 * "test" in the name are ignored.
 */
async function defaultFeedName(session: string): Promise<string> {
  if (resolvedFeedName) return resolvedFeedName;

  const response = await callBusinessApi(
    "aliexpress.ds.feedname.get",
    { country: SHIP_TO, target_currency: CURRENCY, target_language: "EN" },
    session,
    { cacheable: true },
  );
  const rows = promoRows(
    resultOf(unwrap(response, "aliexpress_ds_feedname_get_response")),
  )
    .map((row) => ({
      name: asText(row.promo_name).trim(),
      size: toCount(row.product_num),
    }))
    .filter((promo) =>
      promo.name.length > 0 && !/test/i.test(promo.name) && promo.size > 0
    );

  const bestsellers = rows.filter((promo) => /bestseller/i.test(promo.name));
  const pool = bestsellers.length > 0 ? bestsellers : rows;
  pool.sort((a, b) => b.size - a.size);

  resolvedFeedName = pool.length > 0 ? pool[0].name : "";
  if (!resolvedFeedName) {
    throw new Error("AliExpress returned no storefront feeds.");
  }
  console.log("AliExpress feed resolved.", { feed: resolvedFeedName });
  return resolvedFeedName;
}

/** `aliexpress.ds.feedname.get` — the feed names `handleFeed` accepts. */
async function handleFeedNames() {
  const session = await accessToken();
  const response = await callBusinessApi(
    "aliexpress.ds.feedname.get",
    { country: SHIP_TO, target_currency: CURRENCY, target_language: "EN" },
    session,
    { cacheable: true },
  );
  const inner = unwrap(response, "aliexpress_ds_feedname_get_response");
  return json({
    feeds: promoRows(resultOf(inner))
      .map((row) => ({
        name: asText(row.promo_name).trim(),
        productCount: toCount(row.product_num),
      }))
      .filter((feed) => feed.name.length > 0),
  });
}

// ---------------------------------------------------------------------------
// Browser callback — AliExpress redirects here after the seller authorizes
// ---------------------------------------------------------------------------

/**
 * Plain-text page opened in a browser tab after the redirect.
 *
 * Supabase serves every function from its own `*.supabase.co` domain and
 * rewrites `text/html` responses to `text/plain` (plus a sandbox CSP) so the
 * domain cannot host pages — verified against this deployment. Markup would be
 * shown as source, so the confirmation is plain text on purpose.
 */
function browserPage(title: string, message: string, ok: boolean): Response {
  const body = `${ok ? "OK" : "FAILED"} — ${title}\n\n${message}\n`;
  return new Response(body, {
    status: 200,
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}

async function handleCallback(url: URL): Promise<Response> {
  if (!APP_KEY || !APP_SECRET) {
    console.error("AliExpress callback reached without credentials configured.");
    return browserPage(
      "Not configured",
      "AliExpress credentials are missing on the server.",
      false,
    );
  }

  const rejected = (url.searchParams.get("error") ??
    url.searchParams.get("error_code") ?? "").trim();
  if (rejected) {
    console.error("AliExpress callback returned an error.", {
      error: rejected,
      description: (url.searchParams.get("error_description") ??
        url.searchParams.get("error_msg") ?? "").slice(0, 300),
    });
    return browserPage(
      "Authorization was not completed",
      "AliExpress did not approve the connection. Open the authorize link again and finish the sign-in.",
      false,
    );
  }

  const code = (url.searchParams.get("code") ?? "").trim();
  if (!code) {
    return browserPage(
      "Nothing to do here",
      "This is the AliExpress authorization callback. Open the authorize link from tool/aliexpress_connect.mjs to connect the store.",
      false,
    );
  }

  let response: Record<string, unknown>;
  try {
    // The code is single use and short lived — exchange it immediately.
    response = await callSystemApi("/auth/token/create", { code });
  } catch (error) {
    console.error("AliExpress code exchange failed.", {
      error: error instanceof Error ? error.message : String(error),
    });
    return browserPage(
      "Authorization code rejected",
      "AliExpress did not accept the code. It may have expired or already been used — open the authorize link again.",
      false,
    );
  }

  const payload = tokenPayload(response);
  const access = asText(payload.access_token).trim();
  const refresh = asText(payload.refresh_token).trim();
  if (!access || !refresh) {
    console.error("AliExpress code exchange returned no tokens.", {
      keys: Object.keys(payload).join(","),
    });
    return browserPage(
      "Authorization incomplete",
      "AliExpress returned no tokens. Open the authorize link again.",
      false,
    );
  }

  const saved = await saveTokens({
    access_token: access,
    refresh_token: refresh,
    expires_at: Date.now() + (Number(payload.expires_in) || 3600) * 1000,
  });
  if (!saved) {
    return browserPage(
      "One step left",
      "AliExpress approved the app, but the token could not be saved. Apply supabase/migrations/20261124160000_aliexpress_auth.sql, then open the authorize link again.",
      false,
    );
  }

  console.log("AliExpress connected.", {
    seller: asText(payload.user_nick).trim(),
  });
  return browserPage(
    "AliExpress connected",
    "The store is linked. You can close this tab and reopen the AliExpress tab in the app.",
    true,
  );
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method === "GET") {
    return await handleCallback(new URL(request.url));
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  if (!APP_KEY || !APP_SECRET) {
    return json({ error: "AliExpress is not configured yet." }, 503);
  }

  let body: Record<string, unknown>;
  try {
    const parsed = await request.json();
    body = parsed && typeof parsed === "object"
      ? parsed as Record<string, unknown>
      : {};
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const action = asText(body.action).trim().toLowerCase();

  try {
    switch (action) {
      case "search":
        return await handleSearch(body);
      case "product":
        return await handleProduct(body);
      case "categories":
        return await handleCategories(body);
      case "feed":
        return await handleFeed(body);
      case "feed-names":
        return await handleFeedNames();
      default:
        return json({ error: "Unknown action." }, 400);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("AliExpress request failed.", { action, error: message });

    if (error instanceof SetupError) {
      return json({ error: message }, 503);
    }
    // Upstream detail stays in the function log; the app only needs a
    // user-facing message it can show as-is.
    return json({ error: "AliExpress is unavailable right now." }, 502);
  }
});
