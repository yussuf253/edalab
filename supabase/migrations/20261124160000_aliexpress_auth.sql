-- AliExpress OAuth tokens for the catalogue proxy Edge Function.
--
-- The Drop Shipping API needs a user access token. Access tokens expire in
-- hours, and each refresh returns a new refresh token, so the pair has to be
-- persisted between function invocations. Only the Edge Function's service
-- role touches this table: RLS is enabled with no policies, which denies every
-- anon/authenticated client while the service role bypasses RLS.
create table if not exists public.aliexpress_auth (
  id smallint primary key default 1 check (id = 1),
  access_token text,
  refresh_token text,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.aliexpress_auth enable row level security;

comment on table public.aliexpress_auth is
  'AliExpress OAuth token store. Written and read only by the aliexpress Edge Function via the service role; clients must never read it.';

revoke all on table public.aliexpress_auth from anon, authenticated;
