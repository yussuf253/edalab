-- ============================================================================
-- Notification fan-out RPCs (phase 5a)
-- ============================================================================
-- Every lifecycle event in the backend wrote TWO kinds of row:
--   * one to the actor's own inbox        (the client can do this under RLS)
--   * one to every super-admin inbox      (other users' rows — RLS forbids it)
--
-- Handing clients a blanket insert would turn inboxes into a spam endpoint, so
-- both helpers are SECURITY DEFINER with explicit authorization:
--
--   app.create_notification  target is
--       (a) the caller's own user row, or
--       (b) a pro/business inbox AND the caller has at least one live booking
--           (order, ride, appointment, parcel, car rental, laundry, hotel) —
--           the "customer created something -> tell the provider" case, which
--           a caller with no transactions cannot satisfy.
--
--   app.notify_admins        fans out to every super-admin inbox, creating the
--           inbox User row on demand exactly like the backend's
--           ensureNotificationUser(); dedupe keys get the same "admin:" prefix.
--
-- Dedupe semantics match createBackendNotification: a repeated dedupeKey
-- returns the existing row instead of inserting a second one.
-- ============================================================================

-- Same rule as the backend's isSuperAdminEmail(), parameterized so it can be
-- evaluated for an arbitrary address instead of only the caller's JWT.
create or replace function app.is_admin_email(p_email text)
returns boolean
language sql
stable
as $$
  select lower(coalesce(p_email, ''))
    in ('admin@edalab.com')
    or lower(coalesce(p_email, '')) like 'admin@%'
    or lower(coalesce(p_email, '')) like '%+admin@%'
$$;

-- Super-admin inboxes: one "User" row per admin ProAccount email. Such a row
-- is only a notification target — super admins authenticate through their pro
-- account, never through this password hash.
create or replace function app.admin_inbox_ids()
returns setof text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  acc record;
  v_id text;
begin
  for acc in
    select distinct lower(trim(p.email)) as email
      from "ProAccount" p
     where not p.banned
       and app.is_admin_email(p.email)
  loop
    select u.id into v_id from "User" u where lower(u.email) = acc.email limit 1;

    if v_id is null then
      begin
        insert into "User" (id, email, "firstName", "lastName", "passwordHash")
        values (gen_random_uuid()::text, acc.email, 'Super', 'Admin',
                encode(gen_random_bytes(32), 'hex'))
        returning id into v_id;
      exception when unique_violation then
        select u.id into v_id from "User" u where lower(u.email) = acc.email limit 1;
      end;
    end if;

    if v_id is not null then
      return next v_id;
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- create_notification: self or provider inbox
-- ---------------------------------------------------------------------------
create or replace function app.create_notification(
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
language plpgsql
security definer
set search_path = public
as $$
declare
  v_self text := app.current_user_id();
  v_row  "Notification";
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if user_id is null or coalesce(btrim(user_id), '') = '' then
    raise exception 'userId is required.';
  end if;
  if coalesce(btrim(title), '') = '' then
    raise exception 'title is required.';
  end if;
  if coalesce(btrim(body), '') = '' then
    raise exception 'body is required.';
  end if;

  if dedupe_key is not null and btrim(dedupe_key) <> '' then
    select * into v_row
      from "Notification"
     where "userId" = user_id
       and "dedupeKey" = dedupe_key
     limit 1;
    if found then
      return to_jsonb(v_row);
    end if;
  end if;

  if user_id = v_self
     or app.is_admin()
     or exists (select 1 from "User" u
                 where u.id = user_id and app.is_admin_email(u.email))
     or (
       exists (select 1 from "ProProfile" pp where pp."userId" = user_id)
       and exists (
         select 1 from "Order" x where x."userId" = v_self
         union all select 1 from "RideBooking"      x where x."userId" = v_self
         union all select 1 from "Appointment"      x where x."userId" = v_self
         union all select 1 from "ParcelDelivery"   x where x."userId" = v_self
         union all select 1 from "CarRentalBooking" x where x."userId" = v_self
         union all select 1 from "LaundryOrder"     x where x."userId" = v_self
         union all select 1 from "HotelBooking"     x where x."userId" = v_self
       )
     )
  then
    null;
  else
    raise exception 'You do not have permission to notify that inbox.'
      using errcode = '42501';
  end if;

  insert into "Notification"
    (id, "userId", type, module, priority, title, body, route,
     "dedupeKey", data, metadata, "createdAt", "readAt")
  values
    (coalesce(nullif(btrim(id), ''), gen_random_uuid()::text),
     user_id,
     type::"NotificationType",
     module::"NotificationModule",
     priority::"NotificationPriority",
     title, body, route,
     dedupe_key, coalesce(data, metadata), coalesce(metadata, data),
     coalesce(created_at, now()), read_at)
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

-- ---------------------------------------------------------------------------
-- notify_admins: fan every event out to the super-admin inboxes
-- ---------------------------------------------------------------------------
create or replace function app.notify_admins(
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
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key     text := nullif(btrim(coalesce(dedupe_key, '')), '');
  v_keyed   text := case when v_key is null then null else 'admin:' || v_key end;
  v_target  text;
  v_count   int  := 0;
  v_existing "Notification";
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if coalesce(btrim(title), '') = '' then
    raise exception 'title is required.';
  end if;
  if coalesce(btrim(body), '') = '' then
    raise exception 'body is required.';
  end if;

  for v_target in select app.admin_inbox_ids() loop
    if v_keyed is not null then
      select * into v_existing
        from "Notification"
       where "userId" = v_target and "dedupeKey" = v_keyed
       limit 1;
      if found then
        continue;
      end if;
    end if;

    insert into "Notification"
      (id, "userId", type, module, priority, title, body, route,
       "dedupeKey", data, metadata, "createdAt")
    values
      (gen_random_uuid()::text,
       v_target,
       type::"NotificationType",
       module::"NotificationModule",
       priority::"NotificationPriority",
       title, body, route,
       v_keyed, metadata, metadata, now());
    v_count := v_count + 1;
  end loop;

  return jsonb_build_object('sent', v_count);
end;
$$;

revoke all on function app.is_admin_email(text) from public;
revoke all on function app.is_admin_email(text) from anon;
revoke all on function app.admin_inbox_ids() from public;
revoke all on function app.admin_inbox_ids() from anon;
revoke all on function app.admin_inbox_ids() from authenticated;
revoke all on function app.create_notification(text, text, text, text, text,
    text, text, text, text, jsonb, jsonb, timestamptz, timestamptz) from public;
revoke all on function app.create_notification(text, text, text, text, text,
    text, text, text, text, jsonb, jsonb, timestamptz, timestamptz) from anon;
revoke all on function app.notify_admins(text, text, text, text, text, text,
    text, jsonb) from public;
revoke all on function app.notify_admins(text, text, text, text, text, text,
    text, jsonb) from anon;

grant execute on function app.is_admin_email(text) to authenticated;
grant execute on function app.create_notification(text, text, text, text, text,
    text, text, text, text, jsonb, jsonb, timestamptz, timestamptz)
    to authenticated;
grant execute on function app.notify_admins(text, text, text, text, text, text,
    text, jsonb) to authenticated;
