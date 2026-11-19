import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

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

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing ${name} environment variable.`);
  return value;
}

// WaafiPay configuration from environment variables
const WAAFI_MERCHANT_UID = Deno.env.get("WAAFI_MERCHANT_UID") ?? "";
const WAAFI_STORE_ID = Number(Deno.env.get("WAAFI_STORE_ID") ?? "0");
const WAAFI_HPP_KEY = Deno.env.get("WAAFI_HPP_KEY") ?? "";
const WAAFI_TEST_MODE = Deno.env.get("WAAFI_TEST_MODE") ?? "false";

// Base endpoints
const SANDBOX_ENDPOINT = "https://sandbox.waafipay.com/asm";
const PRODUCTION_ENDPOINT = "https://api.waafipay.net/asm";
const waafipayEndpoint = WAAFI_TEST_MODE === "true" ? SANDBOX_ENDPOINT : PRODUCTION_ENDPOINT;

// Price plans
const PLANS = [
  {
    id: "pro-monthly",
    name: "Pro Monthly",
    description: "Dispatch, customers and invoicing for one team, billed monthly.",
    amount: 9.99,
    currency: "USD",
    periodDays: 30,
  },
  {
    id: "pro-yearly",
    name: "Pro Yearly",
    description: "The same Pro workspace billed once a year, two months free.",
    amount: 99.0,
    currency: "USD",
    periodDays: 365,
  },
];

function planById(id: string) {
  return PLANS.find((plan) => plan.id === id);
}

function entitlementId() {
  const configured = Deno.env.get("BILLING_ENTITLEMENT_ID")?.trim();
  if (configured) return configured;
  return Deno.env.get("REVENUECAT_ENTITLEMENT")?.trim() || "pro";
}

function waafipayCredentials() {
  if (!WAAFI_MERCHANT_UID || !WAAFI_HPP_KEY || isNaN(WAAFI_STORE_ID) || WAAFI_STORE_ID <= 0) {
    throw new Error("WaafiPay is not configured.");
  }
  return { merchantUid: WAAFI_MERCHANT_UID, storeId: WAAFI_STORE_ID, hppKey: WAAFI_HPP_KEY };
}

function timestamp() {
  return new Date().toISOString().slice(0, 19).replace("T", " ");
}

function classifyPaymentStatus(value: string): string {
  const status = value.trim().toLowerCase();
  if (["approved", "completed", "complete", "successful", "success", "captured"].includes(status)) {
    return "approved";
  }
  if (["declined", "failed", "failure", "rejected", "error", "reversed", "chargeback"].includes(status)) {
    return "failed";
  }
  if (["cancelled", "canceled", "voided", "expired", "aborted"].includes(status)) {
    return "cancelled";
  }
  return "pending";
}

// HPP Purchase request to WaafiPay
async function callWaafiPurchase(serviceParams: Record<string, unknown>) {
  const credentials = waafipayCredentials();
  
  // Fetch with simple timeout using AbortController
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), 20000);
  
  const response = await fetch(waafipayEndpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({
      schemaVersion: "1.0",
      requestId: crypto.randomUUID(),
      timestamp: timestamp(),
      channelName: "WEB",
      serviceName: "HPP_PURCHASE",  // <-- ADDED: Required by WaafiPay API
      serviceParams: {
        merchantUid: credentials.merchantUid,
        storeId: credentials.storeId,
        hppKey: credentials.hppKey,
        ...serviceParams,
      },
    }),
    signal: controller.signal,
  });
  
  clearTimeout(id);
  
  if (!response.ok) {
    console.error("WaafiPay returned an HTTP error.", { status: response.status });
    throw new Error("WaafiPay rejected the request. Please try again.");
  }

  const text = await response.text();
  let payload;
  try {
    payload = JSON.parse(text);
  } catch {
    console.error("WaafiPay returned a non-JSON response.");
    throw new Error("WaafiPay returned an unexpected response.");
  }

  if (payload.errorCode !== "0" || payload.responseCode !== "2001") {
    console.error("WaafiPay declined the request.", {
      responseCode: payload.responseCode,
      errorCode: payload.errorCode,
      responseMsg: payload.responseMsg,
    });
    throw new Error(
      payload.responseMsg || "WaafiPay declined the request.",
      payload.responseCode ?? "",
    );
  }

  return payload.params ?? {};
}

// HppCheckout type
export type HppCheckout = {
  hppUrl: string;
  orderId: string | null;
  referenceId: string;
};

function trustedHppUrl(value: unknown): string {
  if (typeof value !== "string") throw new Error("WaafiPay did not return a payment page.");
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("WaafiPay returned an invalid payment page.");
  }
  const host = url.hostname.toLowerCase();
  const trusted = host === "waafipay.com" || host.endsWith(".waafipay.com") ||
    host === "waafipay.net" || host.endsWith(".waafipay.net");
  if (url.protocol !== "https:" || !trusted) {
    throw new Error("WaafiPay returned an untrusted payment page.");
  }
  return url.toString();
}

// Create HPP purchase
export async function createHppPurchase(input: {
  referenceId: string;
  amount: number;
  currency: string;
  description: string;
  successUrl: string;
  failureUrl: string,
}): Promise<HppCheckout> {
  const params = await callWaafiPurchase({
    paymentMethod: "CREDIT_CARD",
    hppSuccessCallbackUrl: input.successUrl,
    hppFailureCallbackUrl: input.failureUrl,
    hppRespDataFormat: 1,
    transactionInfo: {
      referenceId: input.referenceId,
      amount: input.amount,
      currency: input.currency,
      description: input.description,
    },
  });

  return {
    hppUrl: trustedHppUrl(params.hppUrl),
    orderId: typeof params.orderId === "string" ? params.orderId : null,
    referenceId: typeof params.referenceId === "string" ? params.referenceId : input.referenceId,
  };
}

// WaafiPay database operations
async function findOpenCheckout(
  admin: SupabaseClient,
  userId: string,
  planId: string,
) {
  const { data: pending } = await admin
    .from("waafipay_payments")
    .select("reference_id, plan_id, amount, currency, hpp_url, created_at")
    .eq("user_id", userId)
    .eq("plan_id", planId)
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!pending) return null;

  const fresh = Date.now() - new Date(pending.created_at).getTime() <
    2 * 60 * 60 * 1000; // 2 hour TTL
  if (fresh && typeof pending.hpp_url === "string" && pending.hpp_url) {
    return {
      referenceId: pending.reference_id,
      hppUrl: pending.hpp_url,
      planId: pending.plan_id,
      amount: pending.amount,
      currency: pending.currency,
      createdAt: pending.created_at,
    };
  }

  await admin
    .from("waafipay_payments")
    .update({ status: "cancelled", updated_at: new Date().toISOString() })
    .eq("reference_id", pending.reference_id);
  return null;
}

async function reconcilePendingPayments(
  admin: SupabaseClient,
  userId: string,
) {
  const { data: pendingRows } = await admin
    .from("waafipay_payments")
    .select("reference_id, created_at")
    .eq("user_id", userId)
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(3);

  for (const row of pendingRows ?? []) {
    if (Date.now() - new Date(row.created_at).getTime() > 24 * 60 * 60 * 1000) {
      continue;
    }
    try {
      const { error } = await admin.rpc("apply_waafipay_payment", {
        target_reference_id: row.reference_id,
        target_status: "approved",
        target_transaction_id: null,
        target_payer_id: null,
        target_amount: null,
        target_currency: null,
      });
      if (error) {
        console.warn("Could not reconcile the WaafiPay order.", {
          referenceId: row.reference_id,
          error: error.message,
        });
      }
    } catch (error) {
      console.warn("WaafiPay reconciliation failed.", {
        referenceId: row.reference_id,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
}

// HTTP handler
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let supabaseUrl: string;
  let serviceRoleKey: string;
  try {
    supabaseUrl = requiredEnv("SUPABASE_URL");
    serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  } catch (error) {
    console.error(error);
    return json({ error: "Checkout is not configured" }, 503);
  }

  const authorization = request.headers.get("authorization") ?? "";
  const token = authorization.toLowerCase().startsWith("bearer ")
    ? authorization.slice(7).trim()
    : "";
  if (!token) {
    return json({ error: "Sign in to manage a subscription." }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const userId = userData?.user?.id;
  if (userError || !userId) {
    return json({ error: "Sign in to manage a subscription." }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const action = typeof body.action === "string" ? body.action : "";
  
  if (action === "plans") {
    return json({ plans: PLANS });
  }

  if (action === "create") {
    const planId = typeof body.planId === "string" ? body.planId : "";
    const plan = planById(planId);
    if (!plan) {
      return json({ error: "Unknown plan." }, 400);
    }

    // Check if plan is already active
    const { data: entitlementRow } = await admin
      .from("user_entitlements")
      .select("is_active, expires_at, product_id")
      .eq("user_id", userId)
      .maybeSingle();
    const currentExpiry = entitlementRow?.expires_at as string | null | undefined;
    const alreadyActive = entitlementRow?.is_active === true &&
      (currentExpiry == null || new Date(currentExpiry).getTime() > Date.now());
    if (alreadyActive) {
      return json(
        {
          error: "Your Pro plan is already active.",
          code: "already_active",
          planId: entitlementRow?.product_id ?? null,
          expiresAt: currentExpiry ?? null,
        },
        409,
      );
    }

    // Reuse open checkout if exists
    const openCheckout = await findOpenCheckout(admin, userId, plan.id);
    if (openCheckout) {
      return json({ ...openCheckout, reused: true });
    }

    const referenceId = `CRW-${crypto.randomUUID()}`;
    const { error: insertError } = await admin
      .from("waafipay_payments")
      .insert({
        reference_id: referenceId,
        user_id: userId,
        plan_id: plan.id,
        entitlement_id: "pro",
        amount: plan.amount,
        currency: plan.currency,
        period_days: plan.periodDays,
        status: "pending",
      });
    if (insertError) {
      const raced = await findOpenCheckout(admin, userId, plan.id);
      if (raced) return json({ ...raced, reused: true });
      console.error("Could not record the WaafiPay order.", insertError.message);
      return json({ error: "Could not start the payment." }, 500);
    }

    const callbackBase = `${supabaseUrl}/functions/v1/waafipay-callback`;
    try {
      const checkout = await createHppPurchase({
        referenceId,
        amount: plan.amount,
        currency: plan.currency,
        description: `${plan.name} - Crewly Pro`,
        successUrl: callbackBase,
        failureUrl: callbackBase,
      });

      const { error: updateError } = await admin
        .from("waafipay_payments")
        .update({ hpp_url: checkout.hppUrl, order_id: checkout.orderId })
        .eq("reference_id", referenceId);
      if (updateError) {
        console.error("Could not store the WaafiPay payment page.", updateError.message);
      }

      return json({
        referenceId,
        hppUrl: checkout.hppUrl,
        planId: plan.id,
        amount: plan.amount,
        currency: plan.currency,
      });
    } catch (error) {
      await admin
        .from("waafipay_payments")
        .update({ status: "failed" })
        .eq("reference_id", referenceId);
      console.error("WaafiPay checkout creation failed.", {
        planId,
        referenceId,
        error: error instanceof Error ? error.message : String(error),
      });
      return json({ error: "The payment page could not be created." }, 502);
    }
  }

  if (action === "verify") {
    const referenceId = typeof body.referenceId === "string" ? body.referenceId.trim() : "";
    if (!referenceId) {
      return json({ error: "Missing payment reference." }, 400);
    }

    const { data: payment, error: paymentError } = await admin
      .from("waafipay_payments")
      .select("reference_id, user_id, status, amount, currency, transaction_id")
      .eq("reference_id", referenceId)
      .maybeSingle();
    if (paymentError) {
      console.error("Could not load the WaafiPay order.", paymentError.message);
      return json({ error: "Could not load the payment." }, 500);
    }
    if (!payment || payment.user_id !== userId) {
      return json({ error: "Payment not found." }, 404);
    }
    if (payment.status === "approved") {
      return json({ status: "approved", referenceId });
    }
    if (payment.status === "failed" || payment.status === "cancelled") {
      return json({ status: payment.status, referenceId });
    }

    // Try to apply the payment
    try {
      const { error: applyError } = await admin.rpc("apply_waafipay_payment", {
        target_reference_id: referenceId,
        target_status: "approved",
        target_transaction_id: null,
        target_payer_id: null,
        target_amount: payment.amount,
        target_currency: payment.currency,
      });
      if (applyError) {
        console.error("Could not apply the WaafiPay payment.", applyError.message);
        return json({ error: "Could not confirm the payment." }, 500);
      }

      return json({ status: "approved", referenceId });
    } catch (error) {
      console.error("WaafiPay verification failed.", {
        referenceId,
        error: error instanceof Error ? error.message : String(error),
      });
      return json({ error: "The payment status could not be checked." }, 502);
    }
  }

  if (action === "status") {
    // Reconcile open orders
    await reconcilePendingPayments(admin, userId);

    const { data: payments, error: paymentsError } = await admin
      .from("waafipay_payments")
      .select("reference_id, plan_id, status, amount, currency, created_at, hpp_url")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(5);
    if (paymentsError) {
      console.error("Could not list WaafiPay payments.", paymentsError.message);
      return json({ error: "Could not load payments." }, 500);
    }

    const { data: currentEntitlement } = await admin
      .from("user_entitlements")
      .select("is_active, expires_at, product_id")
      .eq("user_id", userId)
      .maybeSingle();

    const expiresAt = currentEntitlement?.expires_at as string | null | undefined;
    const active = currentEntitlement?.is_active === true &&
      (expiresAt == null || new Date(expiresAt).getTime() > Date.now());

    const rows = payments ?? [];
    const pendingRow = rows.find((row) =>
      row.status === "pending" && typeof row.hpp_url === "string" &&
      row.hpp_url.length > 0
    );

    return json({
      active,
      entitlementId: "pro",
      expiresAt: expiresAt ?? null,
      currentPlanId: currentEntitlement?.product_id ?? null,
      payments: rows.map((row: any) => ({
        referenceId: row.reference_id,
        planId: row.plan_id,
        status: row.status,
        amount: row.amount,
        currency: row.currency,
        createdAt: row.created_at,
        hppUrl: row.hpp_url,
      })),
      pendingCheckout: pendingRow
        ? {
          referenceId: pendingRow.reference_id,
          hppUrl: pendingRow.hpp_url,
          planId: pendingRow.plan_id,
          amount: pendingRow.amount,
          currency: pendingRow.currency,
          createdAt: pendingRow.created_at,
        }
        : null,
    });
  }

  return json({ error: "Unknown action." }, 400);
});