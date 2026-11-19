// Shared WaafiPay helpers for the Hosted Payment Page (HPP) checkout flow.
// Credentials are only ever read from Edge Function secrets; they must never be
// shipped in the Flutter client.

export const PRODUCTION_ENDPOINT = "https://api.waafipay.net/asm";
export const SANDBOX_ENDPOINT = "https://sandbox.waafipay.com/asm";
export const DEFAULT_ENTITLEMENT_ID = "pro";

export type WaafiPlan = {
  id: string;
  name: string;
  description: string;
  amount: number;
  currency: string;
  periodDays: number;
};

/**
 * Server-side price list. The app asks for this list and never sends an amount,
 * so a tampered client cannot choose what it pays.
 */
export const PLANS: readonly WaafiPlan[] = [
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

export function planById(id: string): WaafiPlan | undefined {
  return PLANS.find((plan) => plan.id === id);
}

export type WaafiCredentials = {
  merchantUid: string;
  storeId: number;
  hppKey: string;
};

export class WaafiPayError extends Error {
  readonly responseCode: string;

  constructor(message: string, responseCode = "") {
    super(message);
    this.name = "WaafiPayError";
    this.responseCode = responseCode;
  }

  /// WaafiPay cannot find a transaction yet, which is expected while a hosted
  /// page order is still unpaid.
  get isNotSettled(): boolean {
    return this.responseCode === "5213";
  }
}

export function waafipayEndpoint(): string {
  const override = Deno.env.get("WAAFI_ENDPOINT")?.trim();
  if (override) return override;
  return Deno.env.get("WAAFI_TEST_MODE")?.trim() === "true"
    ? SANDBOX_ENDPOINT
    : PRODUCTION_ENDPOINT;
}

export function waafipayCredentials(): WaafiCredentials {
  const merchantUid = Deno.env.get("WAAFI_MERCHANT_UID")?.trim() ?? "";
  const storeIdRaw = Deno.env.get("WAAFI_STORE_ID")?.trim() ?? "";
  const hppKey = Deno.env.get("WAAFI_HPP_KEY")?.trim() ?? "";
  const storeId = Number(storeIdRaw);
  if (!merchantUid || !hppKey || !Number.isInteger(storeId) || storeId <= 0) {
    throw new WaafiPayError("WaafiPay is not configured.");
  }
  return { merchantUid, storeId, hppKey };
}

export function entitlementId(): string {
  const configured = Deno.env.get("BILLING_ENTITLEMENT_ID")?.trim();
  if (configured) return configured;
  return Deno.env.get("REVENUECAT_ENTITLEMENT")?.trim() || DEFAULT_ENTITLEMENT_ID;
}

function timestamp(): string {
  return new Date().toISOString().slice(0, 19).replace("T", " ");
}

type WaafiResponse = {
  responseCode?: string;
  errorCode?: string;
  responseMsg?: string;
  params?: Record<string, unknown>;
}

/**
 * Call WaafiPay API with timeout using Promise.race instead of AbortSignal
 * which is not fully supported in all Deno runtimes (e.g. Supabase Edge).
 */
async function callWaafiTimeout(
  serviceName: string,
  serviceParams: Record<string, unknown>,
  timeoutMs: number = 20000
): Promise<Record<string, unknown>> {
  const credentials = waafipayCredentials();
  const abortController = new AbortController();
  const timeoutId = setTimeout(() => abortController.abort(), timeoutMs);

  try {
    const response = await fetch(waafipayEndpoint(), {
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
        serviceName,
        serviceParams: {
          merchantUid: credentials.merchantUid,
          storeId: credentials.storeId,
          hppKey: credentials.hppKey,
          ...serviceParams,
        },
      },
      signal: abortController.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      console.error("WaafiPay returned an HTTP error.", {
        serviceName,
        status: response.status,
      });
      throw new WaafiPayError("WaafiPay rejected the request. Please try again.");
    }

    const text = await response.text();
    let payload: WaafiResponse;
    try {
      payload = JSON.parse(text) as WaafiResponse;
    } catch {
      console.error("WaafiPay returned a non-JSON response.", { serviceName });
      throw new WaafiPayError("WaafiPay returned an unexpected response.");
    }

    if (payload.errorCode !== "0" || payload.responseCode !== "2001") {
      console.error("WaafiPay declined the request.", {
        serviceName,
        responseCode: payload.responseCode,
        errorCode: payload.errorCode,
        responseMsg: payload.responseMsg,
      });
      throw new WaafiPayError(
        payload.responseMsg || "WaafiPay declined the request.",
        payload.responseCode ?? "",
      );
    }

    return payload.params ?? {};
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      console.error("WaafiPay request timed out.", { serviceName });
      throw new WaafiPayError("WaafiPay request timed out. Please try again.");
    }
    console.error("WaafiPay request failed.", { serviceName, error });
    throw new WaafiPayError("Could not reach WaafiPay. Please try again.");
  }
}

export type HppCheckout = {
  hppUrl: string;
  orderId: string | null;
  referenceId: string;
};

function trustedHppUrl(value: unknown): string {
  if (typeof value !== "string") throw new WaafiPayError("WaafiPay did not return a payment page.");
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new WaafiPayError("WaafiPay returned an invalid payment page.");
  }
  const host = url.hostname.toLowerCase();
  const trusted = host === "waafipay.com" || host.endsWith(".waafipay.com") ||
    host === "waafipay.net" || host.endsWith(".waafipay.net");
  if (url.protocol !== "https:" || !trusted) {
    throw new WaafiPayError("WaafiPay returned an untrusted payment page.");
  }
  return url.toString();
}

export async function createHppPurchase(input: {
  referenceId: string;
  amount: number;
  currency: string;
  description: string;
  successUrl: string;
  failureUrl: string,
}): Promise<HppCheckout> {
  const params = await callWaafiTimeout("HPP_PURCHASE", {
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

export type PaymentStatus = "approved" | "pending" | "failed" | "cancelled";

export type TransactionInfo = {
  status: PaymentStatus;
  transactionId: string | null;
  payerId: string | null;
  amount: number | null;
  currency: string | null;
  description: string | null;
};

function classify(value: unknown): PaymentStatus {
  const status = typeof value === "string" ? value.trim().toLowerCase() : "";
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

export async function fetchTransaction(referenceId: string): Promise<TransactionInfo> {
  const params = await callWaafiTimeout("HPP_GETTRANINFO", { referenceId });
  const rawStatus = params.status ?? params.tranStatusDesc ?? params.tranStatusId;
  const amount = params.tranAmount ?? params.amount;
  return {
    status: classify(rawStatus),
    transactionId: params.transactionId == null ? null : String(params.transactionId),
    payerId: params.payerId == null ? null : String(params.payerId),
    amount: typeof amount === "number" ? amount : Number(amount),
    currency: typeof params.currency === "string" ? params.currency : null,
    description: typeof params.description === "string" ? params.description : null,
  };
}