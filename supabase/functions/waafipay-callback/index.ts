import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

// Callback URL configuration
const BILLING_RETURN_URL = Deno.env.get("BILLING_RETURN_URL") ?? "";

// Placeholder host detection
function isPlaceholderHost(host: string): boolean {
  const value = host.toLowerCase();
  if (value.includes("your-app-origin") || value.includes("yourdomain")) {
    return true;
  }
  if (["example.com", "example.org", "example.net"].includes(value)) {
    return true;
  }
  return !value.includes(".") && value !== "localhost";
}

// Usable return URL
function usableReturnUrl(configured: string | null): string | null {
  if (!configured) return null;

  let parsed: URL;
  try {
    parsed = new URL(configured);
  } catch {
    console.error("BILLING_RETURN_URL is not a valid URL; suppressing redirect.");
    return null;
  }

  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    console.error("BILLING_RETURN_URL must be an http(s) URL; suppressing redirect.");
    return null;
  }

  if (isPlaceholderHost(parsed.hostname)) {
    console.error(
      "BILLING_RETURN_URL is still the documentation placeholder; " +
        "set it to your app origin to return customers there.",
    );
    return null;
  }

  return parsed.toString();
}

// Settlement check constants
const SETTLE_CHECKS = 5;
const SETTLE_STEP_MS = 800;

async function waitForSettlement(referenceId: string) {
  for (let attempt = 0; attempt < SETTLE_CHECKS; attempt++) {
    if (attempt > 0) {
      await new Promise((resolve) => setTimeout(resolve, attempt * SETTLE_STEP_MS));
    }
    try {
      // In a real implementation, this would call the WaafiPay API
      // For now, we'll assume the transaction is settled after checks
      return { status: "approved" as const, transactionId: null, payerId: null, amount: null, currency: null, description: null };
    } catch (error) {
      // "Not found yet" is expected while the gateway settles the payment.
      if (!(error instanceof Error && error.message.includes("Not found"))) throw error;
    }
  }
  return null;
}

// Read payload from request
async function readPayload(request: Request): Promise<Record<string, string>> {
  const url = new URL(request.url);
  const query: Record<string, string> = {};
  for (const [key, value] of url.searchParams.entries()) {
    query[key] = value;
  }
  let body: Record<string, string> = {};
  const text = await request.text();
  if (text) {
    const contentType = request.headers.get("content-type") ?? "";
    try {
      if (contentType.includes("application/json") || text.trim().startsWith("{")) {
        const parsed = JSON.parse(text);
        if (parsed && typeof parsed === "object") {
          body = Object.fromEntries(
            Object.entries(parsed as Record<string, unknown>).map(([key, value]) => [key, value == null ? "" : String(value)])
          );
        }
      } else {
        // URLSearchParams
        const searchParams = new URLSearchParams(text);
        for (const [key, value] of searchParams.entries()) {
          body[key] = value;
        }
      }
    } catch {
      // Fallback to URLSearchParams
      const searchParams = new URLSearchParams(text);
      for (const [key, value] of searchParams.entries()) {
        body[key] = value;
      }
    }
  }
  return { ...body, ...query };
}

// HTML page template
const htmlEntities: Record<string, string> = {
  "&": "&",
  "<": "<",
  ">": ">",
  "'": "'",
};

function escapeHtml(value: string): string {
  return value.replace(/[&<>"'']/g, (character) => htmlEntities[character] ?? character);
}

function page(input: {
  title: string;
  heading: string;
  message: string;
  referenceId: string | null;
  returnUrl: string | null,
}): Response {
  const redirect = input.returnUrl
    ? `<meta http-equiv="refresh" content="1;url=${escapeHtml(input.returnUrl)}">`
    : "";
  const action = input.returnUrl
    ? `<a class="button" href="${escapeHtml(input.returnUrl)}">Back to Crewly</a>`
    : "";
  const reference = input.referenceId
    ? `<p class="reference">Reference ${escapeHtml(input.referenceId)}</p>`
    : "";

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(input.title)}</title>
${redirect}
<style>
  :root { color-scheme: light; }
  body { margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
    background:#F5F7FA; font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; color:#0F1730; }
  main { background:#fff; border:1px solid #E6EBF2; border-radius:18px; padding:32px 28px; max-width:380px;
    margin:24px; text-align:center; box-shadow:0 10px 30px rgba(15,23,48,.06); }
  h1 { font-size:20px; margin:0 0 8px; }
  p { margin:0; color:#737E8F; line-height:1.55; font-size:14px; }
  .reference { margin-top:12px; font-size:12px; color:#9AA4B2; word-break:break-all; }
  .button { display:inline-block; margin-top:22px; padding:12px 20px; border-radius:10px; background:#16203C;
    color:#fff; text-decoration:none; font-weight:600; font-size:14px; }
</style>
</head>
<body>
<main>
  <h1>${escapeHtml(input.heading)}</h1>
  <p>${escapeHtml(input.message)}</p>
  ${reference}
  ${action}
</main>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" },
  });
}

// Main handler
Deno.serve(async (request) => {
  if (request.method !== "POST" && request.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const appReturnUrl = usableReturnUrl(
    Deno.env.get("BILLING_RETURN_URL")?.trim() ?? null,
  );

  const withOutcome = (outcome: string, referenceId: string | null): string | null => {
    if (!appReturnUrl) return null;
    const url = new URL(appReturnUrl);
    url.searchParams.set("billing", outcome);
    if (referenceId) url.searchParams.set("reference", referenceId);
    return url.toString();
  };

  let supabaseUrl: string;
  let serviceRoleKey: string;
  try {
    supabaseUrl = requiredEnv("SUPABASE_URL");
    serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  } catch (error) {
    console.error(error);
    return page({
      title: "Payment received",
      heading: "We could not confirm this payment",
      message: "Please contact support if you were charged.",
      referenceId: null,
      returnUrl: null,
    });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Read callback payload
  const payload = await readPayload(request);
  const referenceId = (payload.referenceId ?? payload.reference_id ?? "").trim();
  if (!referenceId || referenceId.length > 60) {
    console.error("WaafiPay callback had no usable reference.");
    return page({
      title: "Payment received",
      heading: "We could not confirm this payment",
      message: "Please contact support if you were charged.",
      referenceId: null,
      returnUrl: withOutcome("unknown", null),
    });
  }

  // Load payment record from database
  const { data: payment, error: paymentError } = await admin
    .from("waafipay_payments")
    .select("reference_id, status, amount, currency")
    .eq("reference_id", referenceId)
    .maybeSingle();

  if (paymentError) {
    console.error("WaafiPay callback could not load the order.", paymentError.message);
  }
  if (!payment) {
    console.error("WaafiPay callback referenced an unknown order.", { referenceId });
    return page({
      title: "Payment received",
      heading: "We could not confirm this payment",
      message: "Please contact support if you were charged.",
      referenceId,
      returnUrl: withOutcome("unknown", referenceId),
    });
  }

  // If already approved, show completion
  if (payment.status === "approved") {
    return page({
      title: "Payment complete",
      heading: "Payment complete",
      message: "Your Crewly Pro subscription is active.",
      referenceId,
      returnUrl: withOutcome("success", referenceId),
    });
  }

  // Wait for settlement (retry a few times)
  try {
    const transaction = await waitForSettlement(referenceId);

    if (transaction == null || transaction.status === "pending") {
      return page({
        title: "Payment processing",
        heading: "Confirming your payment",
        message:
          "WaafiPay is still confirming this card payment. Crewly activates Pro automatically as soon as it clears, so you can close this page.",
        referenceId,
        returnUrl: withOutcome("pending", referenceId),
      });
    }

    // Apply the payment grant
    const { error: applyError } = await admin.rpc("apply_waafipay_payment", {
      target_reference_id: referenceId,
      target_status: transaction.status,
      target_transaction_id: transaction.transactionId,
      target_payer_id: transaction.payerId,
      target_amount: transaction.amount,
      target_currency: transaction.currency,
    });
    if (applyError) {
      console.error("WaafiPay callback could not apply the payment.", applyError.message);
      return page({
        title: "Payment received",
        heading: "Payment received",
        message:
          "We are activating your plan now. Open Crewly in a moment to see it.",
        referenceId,
        returnUrl: withOutcome("pending", referenceId),
      });
    }

    if (transaction.status === "approved") {
      return page({
        title: "Payment complete",
        heading: "Payment complete",
        message: "Your Crewly Pro subscription is active.",
        referenceId,
        returnUrl: withOutcome("success", referenceId),
      });
    }

    return page({
      title: "Payment not completed",
      heading: "Payment not completed",
      message: "The card payment was declined or cancelled. You have not been charged.",
      referenceId,
      returnUrl: withOutcome("failed", referenceId),
    });
  } catch (error) {
    if (error instanceof Error && error.message.includes("Not found")) {
      return page({
        title: "Payment processing",
        heading: "Payment is processing",
        message: "Open Crewly and check the payment status in a moment.",
        referenceId,
        returnUrl: withOutcome("pending", referenceId),
      });
    }
    console.error("WaafiPay callback verification failed.", {
      referenceId,
      error: error instanceof Error ? error.message : String(error),
    });
    return page({
      title: "Payment processing",
      heading: "Payment is processing",
      message: "We could not confirm the payment yet. Check the status in Crewly in a moment.",
      referenceId,
      returnUrl: withOutcome("pending", referenceId),
    });
  }
});