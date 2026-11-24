#!/usr/bin/env node
/**
 * One-time AliExpress authorization for the shopping module.
 *
 * The Drop Shipping API (`aliexpress.ds.*`) needs a user access token, so the
 * store owner has to authorize app 533838 once. This script builds the
 * authorize URL, exchanges the returned code for tokens, and stores the refresh
 * token as the ALIEXPRESS_REFRESH_TOKEN secret on the Supabase project — the
 * token never passes through the terminal output or a chat window.
 *
 * Setup (once): create `.aliexpress.env` in the repo root (git-ignored):
 *
 *   ALIEXPRESS_APP_KEY=533838
 *   ALIEXPRESS_APP_SECRET=...
 *   ALIEXPRESS_REDIRECT_URI=https://<ref>.supabase.co/functions/v1/aliexpress/callback
 *
 * The callback is the Edge Function itself: AliExpress redirects the browser
 * there, `handleCallback` in supabase/functions/aliexpress/index.ts exchanges
 * the code and stores the tokens, and the tab reports success. Register that
 * exact URL as the app callback on app 533838 — no Render backend involved.
 * ALIEXPRESS_REDIRECT_URI is optional; pass the URL as an argument to
 * `authorize` to use a different one (it must match the console exactly).
 * `exchange` stays as a manual fallback for when the redirect cannot run.
 *
 * Usage:
 *
 *   node tool/aliexpress_connect.mjs authorize
 *     → prints the URL to open in a browser
 *
 *   node tool/aliexpress_connect.mjs exchange "<full redirect URL>"
 *     → exchanges the `code` query parameter and sets the secret
 *
 * Re-run `exchange` only if the refresh token ever expires (the function
 * rotates it automatically from then on).
 */
import { createHmac } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const ENV_PATH = join(ROOT, ".aliexpress.env");
const TEMP_SECRETS_PATH = join(ROOT, ".aliexpress.tokens.env");
const PROJECT_REF = process.env.SUPABASE_PROJECT_REF ?? "tykmxdwewzarkoqnemko";
const GATEWAY = "https://api-sg.aliexpress.com";
/** The Edge Function that finishes the OAuth hand-off. */
const DEFAULT_REDIRECT_URI =
  `https://${PROJECT_REF}.supabase.co/functions/v1/aliexpress/callback`;

function readEnv(path) {
  if (!existsSync(path)) {
    throw new Error(
      `Missing ${path}. Create it with ALIEXPRESS_APP_KEY, ` +
        "ALIEXPRESS_APP_SECRET and ALIEXPRESS_REDIRECT_URI.",
    );
  }
  const values = {};
  for (const line of readFileSync(path, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const at = trimmed.indexOf("=");
    if (at < 0) continue;
    const key = trimmed.slice(0, at).trim();
    let value = trimmed.slice(at + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return values;
}

function sign(params, apiPath, secret) {
  const concatenated = apiPath +
    Object.keys(params).sort().map((key) => `${key}${params[key]}`).join("");
  return createHmac("sha256", secret).update(concatenated, "utf8").digest("hex")
    .toUpperCase();
}

function masked(value) {
  if (!value) return "(empty)";
  return `${value.slice(0, 6)}… (${value.length} chars)`;
}

async function exchange(code) {
  const env = readEnv(ENV_PATH);
  const appKey = env.ALIEXPRESS_APP_KEY;
  const secret = env.ALIEXPRESS_APP_SECRET;
  if (!appKey || !secret) {
    throw new Error(
      "ALIEXPRESS_APP_KEY and ALIEXPRESS_APP_SECRET are required in " +
        ".aliexpress.env",
    );
  }

  const apiPath = "/auth/token/create";
  const params = {
    app_key: appKey,
    code,
    sign_method: "sha256",
    timestamp: Date.now().toString(),
  };
  params.sign = sign(params, apiPath, secret);

  const query = Object.entries(params)
    .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
    .join("&");

  const response = await fetch(`${GATEWAY}/rest${apiPath}?${query}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
    },
  });
  const body = await response.json();

  if (body.error_response) {
    const { code: errorCode, msg } = body.error_response;
    throw new Error(`AliExpress rejected the code: ${errorCode} ${msg ?? ""}`);
  }

  const payload = body.token_create_response ?? body;
  const refreshToken = payload.refresh_token;
  if (!refreshToken) {
    throw new Error(
      `No refresh_token in the response (keys: ${Object.keys(payload).join(", ")})`,
    );
  }

  writeFileSync(
    TEMP_SECRETS_PATH,
    `ALIEXPRESS_REFRESH_TOKEN=${refreshToken}\n`,
    { mode: 0o600 },
  );
  try {
    execFileSync(
      "supabase",
      [
        "secrets",
        "set",
        "--env-file",
        TEMP_SECRETS_PATH,
        "--project-ref",
        PROJECT_REF,
      ],
      { stdio: "inherit" },
    );
  } finally {
    rmSync(TEMP_SECRETS_PATH, { force: true });
  }

  console.log(`Refresh token stored: ${masked(refreshToken)}`);
  console.log(
    `Access token expires in ${payload.expires_in ?? "?"}s; the Edge Function ` +
      "refreshes it automatically from now on.",
  );
}

async function main() {
  const [command, argument] = process.argv.slice(2);

  if (!command || command === "authorize") {
    const env = readEnv(ENV_PATH);
    const fromEnv = (env.ALIEXPRESS_REDIRECT_URI ?? "").trim();
    const override = (argument ?? "").trim();
    const redirectUri = override || fromEnv || DEFAULT_REDIRECT_URI;
    if (!/^https:\/\//.test(redirectUri)) {
      throw new Error(
        `The callback must be an https URL registered on the app; got ` +
          `"${redirectUri}".`,
      );
    }
    const source = override
      ? "argument"
      : fromEnv
      ? ".aliexpress.env"
      : "default";

    const params = new URLSearchParams({
      response_type: "code",
      force_auth: "true",
      redirect_uri: redirectUri,
      client_id: env.ALIEXPRESS_APP_KEY ?? "",
    });
    console.log("Open this URL, sign in and authorize:\n");
    console.log(`${GATEWAY}/oauth/authorize?${params.toString()}\n`);
    console.log(`Callback: ${redirectUri}  (from ${source})`);
    console.log(
      "It must be exactly the callback URL registered on app 533838. The " +
        "default is the Edge Function, which stores the token and shows a " +
        "confirmation page.\n",
    );
    console.log(
      "If the callback page does not load, copy the full URL from the " +
        "address bar and run:\n  node tool/aliexpress_connect.mjs exchange " +
        '"<that URL>"',
    );
    return;
  }

  if (command !== "exchange") {
    throw new Error(`Unknown command "${command}". Use authorize or exchange.`);
  }
  if (!argument) {
    throw new Error("Pass the full redirect URL (or just the code).");
  }

  let code = argument.trim();
  if (code.includes("code=")) {
    code = new URL(code).searchParams.get("code") ?? code;
  }
  await exchange(code);
}

main().catch((error) => {
  console.error(`\n${error instanceof Error ? error.message : error}`);
  process.exitCode = 1;
});
