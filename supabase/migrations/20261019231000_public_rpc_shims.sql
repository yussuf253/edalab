-- ============================================================================
-- Public RPC shims (phase 5b)
-- ============================================================================
-- PostgREST only searches the schemas listed in its `db-schemas` setting, and
-- this project exposes just `public`. Calling `app.current_user_id()` from a
-- client therefore fails:
--
--   POST /rest/v1/rpc/app.current_user_id
--   -> 404 PGRST202 "Searched for the function public.app.current_user_id"
--
-- The SQL-side users of these helpers (RLS policies, other functions) are
-- unaffected — they resolve `app.*` directly. Only the client-facing entry
-- points need a `public` alias, which is what these wrappers are.
--
-- They are SECURITY DEFINER so the caller never needs `USAGE` on the `app`
-- schema (the service role does not have it, and neither should clients).
-- Access is still controlled by the EXECUTE grants at the bottom: everything
-- is revoked from `anon`, and the write helpers are granted to
-- `authenticated` only. The guards inside `app.create_notification` compute
-- the caller's identity from the JWT, so running as the function owner does
-- not loosen them.
-- ============================================================================

create or replace function public.current_user_id()
returns text
language sql
stable
security definer
set search_path = public
as $$ select app.current_user_id() $$;

create or replace function public.current_pro_account_id()
returns text
language sql
stable
security definer
set search_path = public
as $$ select app.current_pro_account_id() $$;

-- Safety net for accounts whose `User`/`ProAccount` row predates the auth_uid
-- backfill: links them to the signed-in auth user by email.
create or replace function public.claim_account()
returns void
language sql
security definer
set search_path = public
as $$ select app.claim_account() $$;

create or replace function public.create_notification(
  id              text   default null,
  user_id         text   default null,
  title           text   default null,
  body            text   default null,
  module          text   default 'SYSTEM',
  type            text   default 'SYSTEM',
  priority        text   default 'HIGH',
  route           text   default null,
  dedupe_key      text   default null,
  metadata        jsonb  default null,
  data            jsonb  default null,
  created_at      timestamptz default null,
  read_at         timestamptz default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select app.create_notification(
    id, user_id, title, body, module, type, priority, route,
    dedupe_key, metadata, data, created_at, read_at
  )
$$;

create or replace function public.notify_admins(
  title      text,
  body       text,
  module     text   default 'SYSTEM',
  type       text   default 'SYSTEM',
  priority   text   default 'HIGH',
  route      text   default null,
  dedupe_key text   default null,
  metadata   jsonb  default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select app.notify_admins(title, body, module, type, priority, route,
                           dedupe_key, metadata)
$$;

-- Visibility: helper identity functions are harmless, the write helpers are
-- authenticated-only. Nothing here is reachable by `anon`.
revoke all on function public.current_user_id()          from public, anon;
revoke all on function public.current_pro_account_id()   from public, anon;
revoke all on function public.claim_account()            from public, anon;
revoke all on function public.create_notification(text, text, text, text, text,
    text, text, text, text, jsonb, jsonb, timestamptz, timestamptz) from public, anon;
revoke all on function public.notify_admins(text, text, text, text, text, text,
    text, jsonb) from public, anon;

grant execute on function public.current_user_id()        to authenticated;
grant execute on function public.current_pro_account_id() to authenticated;
grant execute on function public.claim_account()          to authenticated;
grant execute on function public.create_notification(text, text, text, text, text,
    text, text, text, text, jsonb, jsonb, timestamptz, timestamptz)
    to authenticated;
grant execute on function public.notify_admins(text, text, text, text, text, text,
    text, jsonb) to authenticated;
