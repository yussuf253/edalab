# Backend → Supabase Direct Migration Plan

Goal: disable the Render Node backend (`https://edalab.onrender.com/api`) and have
**edalab_app** (user app) and **edalab_pro** talk to Supabase directly, securely:
client → PostgREST/GoTrue/Storage with **RLS** instead of server checks; server-secret
logic (WaafiPay, FCM push, AliExpress proxy) moves to **Edge Functions**.

## Verified project state (audited 2026-10-19)

| Item | Value |
| --- | --- |
| Supabase project ref | `tykmxdwewzarkoqnemko` (eu-west-1 pooler) |
| DB tables (public) | 42 — exact 1:1 with Prisma schema |
| Supabase Auth roles in DB | `anon`, `authenticated`, `service_role` present (RLS-capable) |
| Customer accounts (`User`) | 52 rows, **30 not yet in auth.users** |
| Pro accounts (`ProAccount`) | 18 rows, **14 not yet in auth.users** |
| `auth.users` rows | 23 (signup already mirrors to GoTrue since pro-auth integration) |
| Anon/publishable key | **not stored anywhere in repos** — must be supplied at build time |
| Backend surface | 180 endpoints (91 GET / 70 POST / 13 PATCH / 5 DELETE / 1 PUT) |
| App call sites | 278 `ApiClient` calls (user app) + 141 (pro app) |

### Key structural findings

1. **IDs are cuids, not auth UUIDs.** `User.id` / `ProAccount.id` are Prisma cuids and
   every FK (`Order.userId`, `ProProfile.userId`, …) references them. `auth.uid()` will
   NOT match. Bridge: add `auth_uid uuid unique` to `User` + `ProAccount`, backfill from
   `auth.users` by email, and expose SQL helpers used inside RLS policies:
   - `app.current_user_id() → text` (cuid of the User row for `auth.uid()`)
   - `app.current_pro_account_id() → text`
2. **Passwords are double-hashed today** (bcrypt in `User.passwordHash` + GoTrue entry).
   For the 30+14 accounts missing from GoTrue: import via GoTrue admin
   `POST /auth/v1/admin/users?import=true` reusing existing bcrypt hashes
   (`password_hash` field) — no password resets needed.
3. **Pro duality:** pro register → GoTrue user + `ProAccount`; profile setup → `User` +
   `ProProfile(userId → User.id, accountId → ProAccount.id)`. RLS must bridge
   `auth.uid()` to **both** tables.
4. **Super admins** have no profile; the pro app uses a dedicated admin inbox id
   (`adminUserId`). Keep as a flag column or existing pattern; admin RLS =
   `auth.jwt() ->> 'email'` check like today (`admin@…`), moved into a SQL helper.

## Endpoint classification (180 total)

Bucket A — **direct client access** (PostgREST + RLS, no Edge Function):
catalog reads (18 GETs), users CRUD (addresses/payment methods/wishlist/profile),
notifications list/mark-read, device tokens, promotions, modules/zones reads,
restaurant-menu + shopping-products CRUD, availability/status toggles that only flip
own rows, laundry services CRUD, doctor/provider settings+availability,
car-rental/hotel/ride/appointment reads, messages reads.

Bucket B — **Postgres RPC / view** (complex read SQL, called via `postgrest.rpc`):
`/pro/:userId/queue|dashboard|summary`, messages summaries, admin overview/stats,
`/zones/resolve` (geo), order detail aggregation.

Bucket C — **Edge Function** (server secrets or multi-row fan-out):
- `waafipay/initiate` + payment confirm/callback (WAAFIPAY_* secrets)
- order/ride/appointment/parcel **create + status transitions** (notifyX fan-out, dedupe)
- `aliexpress/*` (third-party token + cache + webhook)
- `media/upload` (or direct Storage upload from client with scoped buckets)
- push send (FCM service account) — triggered from DB webhooks or from other functions
- admin mutations (ban/verify/status), version admin, cache clear
- auth-adjacent: `pro-auth/profile` side effects (creates User + ProProfile + admin notify)

Bucket D — **die with the backend**: SSE realtime routes (→ Supabase Realtime channels),
`/health`, version `check/report-action` (→ table reads/writes directly).

## Phases

1. ✅ Inventory (this doc)
2. ✅ `supabase_flutter` + `SupabaseService` config layer in both apps (URL + anon key via
   `--dart-define`; ApiClient untouched, apps keep working against Render meanwhile)
3. ✅ RLS migration SQL: `auth_uid` columns + helpers + policies for all 42 tables
   (applied + verified live: 92+ policies, isolation simulated per role;
   addendums: `auth_uid` column grants, `user_self_read`/`user_self_insert`)
4. ✅ Auth cutover: all 44 bcrypt-only accounts imported to GoTrue (passwords preserved,
   `auth_uid` fully linked); login/session/logout in both apps go through Supabase Auth
   when built with the defines. New customer signups self-provision their profile row
   on first login. Pro *registration + profile setup* still needs the backend
   (moves to an Edge Function in phase 5).
5. Edge Functions for Bucket C
6. Feature-by-feature read/mutation conversion off `ApiClient`
7. Verification, then decommission Render (scale to 0 / delete service)

## BLOCKER for runtime testing

The anon/publishable key is not stored in any repo. Until it is supplied, direct mode
cannot run on a device. Get it from Supabase dashboard → Settings → API →
"anon / publishable" key, then:

```
flutter run --dart-define=SUPABASE_URL=https://tykmxdwewzarkoqnemko.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

## Rollout safety

- Backend stays up until phase 6 completes; both apps keep the old path compile-clean.
- RLS enabled **after** policies are in place, table by table; backend (service role /
  postgres owner) is unaffected by RLS, so zero risk to production traffic.
- Cutover per app is a build-flag flip (`API_BASE_URL` no longer needed once all
  call sites are converted).
