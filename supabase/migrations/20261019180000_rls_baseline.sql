-- ============================================================================
-- RLS baseline for direct Supabase access (backend decommission, phase 3)
-- ============================================================================
-- Adds the auth-uid bridge (Prisma cuids vs auth.users uuids), helper
-- functions, column-safe grants and Row Level Security for all 42 public
-- tables.
--
-- Safe to run while the Render backend is live:
--   * the backend connects as the `postgres` role = table owner, and RLS
--     never applies to the table owner (no FORCE), so production traffic is
--     unaffected;
--   * `service_role` has BYPASSRLS, so Edge Functions are unaffected.
--
-- Rollback: see the "Rollback" section at the bottom.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Bridge columns: map auth.users uuid -> app cuid rows
-- ---------------------------------------------------------------------------
alter table public."User"        add column if not exists auth_uid uuid;
alter table public."ProAccount"  add column if not exists auth_uid uuid;

update public."User" u
set auth_uid = a.id
from auth.users a
where lower(a.email) = lower(u.email)
  and u.auth_uid is null;

update public."ProAccount" p
set auth_uid = a.id
from auth.users a
where lower(a.email) = lower(p.email)
  and p.auth_uid is null;

create unique index if not exists user_auth_uid_key        on public."User"       (auth_uid);
create unique index if not exists pro_account_auth_uid_key on public."ProAccount" (auth_uid);

-- ---------------------------------------------------------------------------
-- 2. Helper functions (security definer so policies don't recurse)
-- ---------------------------------------------------------------------------
create schema if not exists app;

-- cuid of the User row belonging to the signed-in Supabase Auth user
create or replace function app.current_user_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select u.id from public."User" u where u.auth_uid = auth.uid()
$$;

-- cuid of the ProAccount row belonging to the signed-in Supabase Auth user
create or replace function app.current_pro_account_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.id from public."ProAccount" p where p.auth_uid = auth.uid()
$$;

-- Same super-admin rule as the backend (pro_auth_provider.isSuperAdmin):
-- configured email, or any admin@… / …+admin@… address.
create or replace function app.is_admin()
returns boolean
language sql
stable
as $$
  select
    lower(coalesce(auth.jwt() ->> 'email', ''))
    in ('admin@edalab.com')
    or lower(coalesce(auth.jwt() ->> 'email', '')) like 'admin@%'
    or lower(coalesce(auth.jwt() ->> 'email', '')) like '%+admin@%'
$$;

-- Claim the legacy cuid row that matches the signed-in auth user's email.
-- Called by the app once after login so pre-migration accounts (bcrypt-only
-- rows that get imported to GoTrue) become reachable under RLS.
create or replace function app.claim_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
begin
  if v_email = '' then
    raise exception 'claim_account requires an authenticated JWT';
  end if;

  update public."User" u
  set auth_uid = auth.uid()
  where lower(u.email) = v_email and u.auth_uid is null;

  update public."ProAccount" p
  set auth_uid = auth.uid()
  where lower(p.email) = v_email and p.auth_uid is null;
end;
$$;

revoke all on function app.claim_account() from public;
revoke all on function app.claim_account() from anon;
grant  execute on function app.claim_account() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Grants
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant usage on schema app    to authenticated;

grant select on all tables in schema public to anon, authenticated;

grant insert, update, delete on
  public."Address", public."PaymentMethod", public."WishlistItem",
  public."Notification", public."DeviceToken", public."UserCoupon",
  public."CarRentalBooking", public."Appointment", public."HotelBooking",
  public."LaundryOrder", public."Order", public."OrderItem",
  public."RideBooking", public."ParcelDelivery", public."Conversation",
  public."Message", public."DoctorReview"
  to authenticated;

-- Column-level safety: clients must never read password hashes. This must run
-- AFTER the blanket table grants above so it wins.
revoke select on public."User" from anon, authenticated;
grant select (id, email, "firstName", "lastName", phone, "avatarUrl",
              "dateOfBirth", points, banned, "banReason", "createdAt", "updatedAt",
              auth_uid)
  on public."User" to authenticated;

revoke select on public."ProAccount" from anon, authenticated;
grant select (id, email, "fullName", phone, "avatarUrl", banned, "banReason",
              "createdAt", "updatedAt", auth_uid)
  on public."ProAccount" to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Enable RLS everywhere
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  for t in
    select table_name from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Policies — user-owned data (owner = all rights)
-- ---------------------------------------------------------------------------
-- Helper macro-style policy per owner table.
do $$
declare
  t text;
  pname text;
begin
  foreach t in array array[
    'Address','PaymentMethod','WishlistItem','Notification','DeviceToken',
    'UserCoupon','CarRentalBooking','Appointment','HotelBooking',
    'LaundryOrder','Order','RideBooking','ParcelDelivery','Conversation'
  ] loop
    pname := t || '_owner';
    execute format('drop policy if exists %I on public.%I', pname, t);
    execute format(
      'create policy %I on public.%I for all to authenticated '
      || 'using ("userId" = app.current_user_id()) '
      || 'with check ("userId" = app.current_user_id())',
      pname, t);
  end loop;
end;
$$;

-- User: the account holder reads their own profile row; new signups
-- (registered via GoTrue directly) self-provision it on first login with
-- id = auth uid. Admins read all (moderation, super-admin inbox).
drop policy if exists user_self_read on public."User";
create policy user_self_read on public."User"
  for select to authenticated
  using (id = app.current_user_id()
         or auth_uid = auth.uid()
         or app.is_admin());

drop policy if exists user_self_insert on public."User";
create policy user_self_insert on public."User"
  for insert to authenticated
  with check (auth_uid = auth.uid() and id = auth.uid()::text);

-- ProProfile: the pro user owns their own profile row.
drop policy if exists pro_profile_owner on public."ProProfile";
create policy pro_profile_owner on public."ProProfile"
  for all to authenticated
  using ("userId" = app.current_user_id()
         or app.current_pro_account_id() is not null
            and "accountId" = app.current_pro_account_id()
         or app.is_admin())
  with check ("userId" = app.current_user_id() or app.is_admin());

-- ProAccount: own row, read-only for clients (writes go through auth flows).
drop policy if exists pro_account_own on public."ProAccount";
create policy pro_account_own on public."ProAccount"
  for select to authenticated
  using (id = app.current_pro_account_id() or app.is_admin());

-- ---------------------------------------------------------------------------
-- 6. Policies — multi-party tables (counterparty access)
-- ---------------------------------------------------------------------------
-- Order: customer owns; assigned delivery user reads/updates status fields.
drop policy if exists order_customer on public."Order";
create policy order_customer on public."Order"
  for all to authenticated
  using ("userId" = app.current_user_id())
  with check ("userId" = app.current_user_id());

drop policy if exists order_delivery on public."Order";
create policy order_delivery on public."Order"
  for select to authenticated
  using ("deliveryUserId" = app.current_user_id());
-- Status transitions for assigned deliveries go through Edge Functions
-- (service_role); clients only see their assigned rows.

-- OrderItem: readable/writable through the parent order.
drop policy if exists order_item_via_order on public."OrderItem";
create policy order_item_via_order on public."OrderItem"
  for all to authenticated
  using (exists (
    select 1 from public."Order" o
    where o.id = "OrderItem"."orderId"
      and o."userId" = app.current_user_id()))
  with check (exists (
    select 1 from public."Order" o
    where o.id = "OrderItem"."orderId"
      and o."userId" = app.current_user_id()));

-- RideBooking: customer owns; assigned driver sees + updates own rides.
drop policy if exists ride_customer on public."RideBooking";
create policy ride_customer on public."RideBooking"
  for all to authenticated
  using ("userId" = app.current_user_id())
  with check ("userId" = app.current_user_id());

drop policy if exists ride_driver on public."RideBooking";
create policy ride_driver on public."RideBooking"
  for all to authenticated
  using ("driverUserId" = app.current_user_id())
  with check ("driverUserId" = app.current_user_id());

-- ParcelDelivery: customer owns; assigned courier sees + updates.
drop policy if exists parcel_customer on public."ParcelDelivery";
create policy parcel_customer on public."ParcelDelivery"
  for all to authenticated
  using ("userId" = app.current_user_id())
  with check ("userId" = app.current_user_id());

drop policy if exists parcel_courier on public."ParcelDelivery";
create policy parcel_courier on public."ParcelDelivery"
  for all to authenticated
  using ("courierUserId" = app.current_user_id())
  with check ("courierUserId" = app.current_user_id());

-- Conversation: owner or bound pro participant.
drop policy if exists conversation_party on public."Conversation";
create policy conversation_party on public."Conversation"
  for all to authenticated
  using ("userId" = app.current_user_id()
         or "participantUserId" = app.current_user_id())
  with check ("userId" = app.current_user_id()
              or "participantUserId" = app.current_user_id());

-- Message: visible to both sides of the conversation.
drop policy if exists message_party on public."Message";
create policy message_party on public."Message"
  for all to authenticated
  using (exists (
    select 1 from public."Conversation" c
    where c.id = "Message"."conversationId"
      and (c."userId" = app.current_user_id()
           or c."participantUserId" = app.current_user_id())))
  with check (exists (
    select 1 from public."Conversation" c
    where c.id = "Message"."conversationId"
      and (c."userId" = app.current_user_id()
           or c."participantUserId" = app.current_user_id())));

-- DoctorReview: public catalog reviews; any signed-in user may post one.
drop policy if exists doctor_review_read on public."DoctorReview";
create policy doctor_review_read on public."DoctorReview"
  for select to anon, authenticated using (true);

drop policy if exists doctor_review_insert on public."DoctorReview";
create policy doctor_review_insert on public."DoctorReview"
  for insert to authenticated with check (true);

-- UpdateActionLog: a user logs their own app-version actions.
drop policy if exists update_action_log_own on public."UpdateActionLog";
create policy update_action_log_own on public."UpdateActionLog"
  for insert to authenticated with check ("userId" = app.current_user_id());

drop policy if exists update_action_log_admin on public."UpdateActionLog";
create policy update_action_log_admin on public."UpdateActionLog"
  for select to authenticated using (app.is_admin());

-- ---------------------------------------------------------------------------
-- 7. Policies — public catalog & platform tables (read for everyone,
--    writes only via service_role / Edge Functions)
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'ShoppingStore','Product','ProductCategory','Restaurant',
    'RestaurantMenuCategory','RestaurantMenuItem','Pharmacy','Medicine',
    'Doctor','HomeServiceCategory','HomeServiceProvider','Hotel',
    'LaundryService','RideCategory','HealthServiceCategory','LabTest',
    'Promotion','AppModule','ServiceZone','ZoneModuleConfig','AppVersion'
  ] loop
    execute format('drop policy if exists %I on public.%I',
                   t || '_public_read', t);
    execute format(
      'create policy %I on public.%I for select to anon, authenticated using (true)',
      t || '_public_read', t);
  end loop;
end;
$$;

-- AppVersion: the app's unauthenticated "check for update" read stays public.
-- (Writes are admin-only; the admin UI already routes through the backend,
--  which keeps working as table owner; later via an admin Edge Function.)

-- ---------------------------------------------------------------------------
-- 8. Admin full access (super-admin inbox in the pro app, moderation, …)
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  for t in
    select table_name from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
  loop
    execute format('drop policy if exists %I on public.%I', t || '_admin', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using (app.is_admin()) with check (app.is_admin())',
      t || '_admin', t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Verification (run manually after apply):
--   set role authenticated;
--   set local request.jwt.claims = '{"sub":"<auth-uuid-of-a-test-user>","role":"authenticated","email":"<their email>"}';
--   select count(*) from public."Address";            -- must be only their rows
--   select password_hash from public."User";          -- must ERROR (column not granted)
--   set role service_role;                            -- must see everything
--
-- Rollback:
--   drop schema app cascade;
--   alter table public."User" drop column if exists auth_uid;
--   alter table public."ProAccount" drop column if exists auth_uid;
--   do $$ declare t text; begin
--     for t in select table_name from information_schema.tables
--               where table_schema='public' and table_type='BASE TABLE' loop
--       execute format('alter table public.%I disable row level security', t);
--     end loop;
--   end; $$;
--   -- drop every policy created above, restore blanket grants
-- ============================================================================
