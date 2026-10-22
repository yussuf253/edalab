-- ============================================================================
-- Order-domain RPCs (phase 6) — car rentals, provider fan-out, messaging
-- ============================================================================
-- Three things the customer session cannot do directly under RLS:
--
--   1. Car-rental double-booking protection. The backend serialized bookings
--      per car inside a transaction (advisory lock + overlap check + booking
--      + accounting Order). PostgREST has no multi-statement transactions, so
--      the whole flow moves into one SECURITY DEFINER function.
--   2. Availability checks must see *every* booking for a car, not only the
--      caller's own rows (CarRentalBooking RLS is owner-only).
--   3. Resolving which pro profile is bound to a public catalog entity
--      (store, restaurant, doctor, provider) or a pharmacy business name.
--      ProProfile is owner-only, but the binding target itself (the store id
--      etc.) is public catalog data, so exposing the bound inbox user id adds
--      nothing the backend did not already return as `participantUserId`.
--
-- Also widens `create_notification`'s cross-inbox guard: a customer who has
-- never placed an order may still notify the pro they already share an active
-- conversation thread with (messaging a store before the first purchase).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Atomic car-rental booking (mirrors POST /car-rentals/bookings)
-- ---------------------------------------------------------------------------
create or replace function app.create_car_rental_booking(
  p_user_id       text,
  p_car_id        text,
  p_start         timestamptz,
  p_end           timestamptz,
  p_pickup        text,
  p_dropoff       text default null,
  p_notes         text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_car          "Product";
  v_metadata     jsonb;
  v_total_days   int;
  v_price        numeric;
  v_subtotal     numeric;
  v_tax          numeric;
  v_total        numeric;
  v_booking      "CarRentalBooking";
  v_order        "Order";
  v_overlap      "CarRentalBooking";
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_user_id is null or btrim(p_user_id) <> app.current_user_id() then
    raise exception 'You can only book for yourself.' using errcode = '42501';
  end if;
  if p_end <= p_start then
    raise exception 'End date must be after start date.';
  end if;

  select * into v_car
    from "Product"
   where id = p_car_id
     and "moduleType" = 'RIDE'
     and "inStock" = true
     and metadata->'rentalCar' = 'true'::jsonb;
  if not found then
    raise exception 'Car not found or unavailable.';
  end if;

  v_metadata := case when jsonb_typeof(v_car.metadata) = 'object'
                     then v_car.metadata else '{}'::jsonb end;
  v_total_days := greatest(1, ceil(extract(epoch from (p_end - p_start)) / 86400)::int);
  v_price      := v_car.price;
  v_subtotal   := v_price * v_total_days;
  v_tax        := v_subtotal * 0.08;
  v_total      := v_subtotal + v_tax;

  -- Serialize concurrent bookings for the same car (the backend's
  -- pg_advisory_xact_lock(hashtext(carId)) — locking the catalog row has
  -- the same effect and needs no hash function).
  perform 1 from "Product" where id = p_car_id for update;

  select * into v_overlap
    from "CarRentalBooking"
   where "carId" = p_car_id
     and status in ('PENDING', 'CONFIRMED', 'ACTIVE')
     and "startDate" < p_end
     and "endDate" > p_start
   limit 1;
  if found then
    raise exception 'Car is already booked for the selected dates.';
  end if;

  insert into "CarRentalBooking"
    ("userId", "carId", "carName", "carType", "startDate", "endDate",
     "totalDays", "pricePerDay", subtotal, tax, total, status,
     "pickupLocation", "dropoffLocation", notes, metadata)
  values
    (p_user_id, p_car_id, v_car.name,
     coalesce(v_metadata->>'type', v_car.brand, 'Standard'),
     p_start, p_end, v_total_days, v_price, v_subtotal, v_tax, v_total,
     'CONFIRMED', p_pickup, coalesce(p_dropoff, p_pickup), nullif(btrim(coalesce(p_notes, '')), ''),
     jsonb_build_object('createdBy', 'api'))
  returning * into v_booking;

  insert into "Order"
    ("userId", "moduleType", status, subtotal, tax, "deliveryFee", discount,
     total, notes, metadata)
  values
    (p_user_id, 'RIDE', 'CONFIRMED', v_subtotal, v_tax, 0, 0, v_total,
     nullif(btrim(coalesce(p_notes, '')), ''),
     jsonb_build_object(
       'rentalBooking', true, 'bookingId', v_booking.id, 'carId', p_car_id,
       'carName', v_car.name,
       'carType', coalesce(v_metadata->>'type', v_car.brand, 'Standard'),
       'startDate', to_char(p_start at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
       'endDate', to_char(p_end at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
       'totalDays', v_total_days, 'pricePerDay', v_price,
       'pickupLocation', p_pickup, 'dropoffLocation', coalesce(p_dropoff, p_pickup)))
  returning * into v_order;

  insert into "OrderItem"
    ("orderId", "productId", name, brand, quantity, "unitPrice", "lineTotal", metadata)
  values
    (v_order.id, p_car_id, v_car.name,
     coalesce(v_metadata->>'type', v_car.brand, 'Car Rental'),
     v_total_days, v_price, v_subtotal,
     jsonb_build_object(
       'bookingId', v_booking.id,
       'startDate', to_char(p_start at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
       'endDate', to_char(p_end at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
       'totalDays', v_total_days, 'pickupLocation', p_pickup,
       'dropoffLocation', coalesce(p_dropoff, p_pickup), 'rentalBooking', true));

  return to_jsonb(v_booking);
end;
$$;

-- ---------------------------------------------------------------------------
-- 2b. Atomic car-rental cancel (mirrors POST /car-rentals/bookings/:id/cancel)
-- ---------------------------------------------------------------------------
-- The backend cancelled the booking and its accounting Order in one
-- transaction; two separate PostgREST statements could leave the history row
-- showing CONFIRMED after a crash between them. Raises with the backend's
-- exact messages; returns null when the booking is not the caller's.
create or replace function app.cancel_car_rental_booking(
  p_booking_id text,
  p_user_id    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking "CarRentalBooking";
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into v_booking
    from "CarRentalBooking"
   where id = p_booking_id and "userId" = p_user_id;
  if not found then
    return null;
  end if;
  if v_booking.status = 'CANCELLED' then
    raise exception 'Booking is already cancelled.';
  end if;
  if v_booking.status = 'COMPLETED' then
    raise exception 'Completed bookings cannot be cancelled.';
  end if;
  if v_booking."startDate" <= now() then
    raise exception 'This rental has already started and cannot be cancelled.';
  end if;

  update "CarRentalBooking" set status = 'CANCELLED'
   where id = v_booking.id
  returning * into v_booking;

  update "Order" set status = 'CANCELLED'
   where "userId" = p_user_id
     and metadata->>'bookingId' = p_booking_id
     and status <> 'CANCELLED';

  return to_jsonb(v_booking);
end;
$$;

-- ---------------------------------------------------------------------------
-- 2c. Car-rental availability (sees every booking, not only the caller's)
-- ---------------------------------------------------------------------------
create or replace function app.car_rental_available(
  p_car_id text,
  p_start  timestamptz,
  p_end    timestamptz
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from "CarRentalBooking"
     where "carId" = p_car_id
       and status in ('PENDING', 'CONFIRMED', 'ACTIVE')
       and "startDate" < p_end
       and "endDate" > p_start
  );
$$;

-- ---------------------------------------------------------------------------
-- 3. Bound-profile resolution (messages participant + order fan-out)
-- ---------------------------------------------------------------------------
-- `p_active_module` mirrors the backend's `activeModules: { has: ... }`
-- filter for fan-out; pass null (messages) to skip it. Matching is
-- trim+lower on both sides so pharmacy business names compare
-- case-insensitively while cuid bindings stay exact.
create or replace function app.resolve_bound_profile_user_ids(
  p_type          text,
  p_binding_key   text,
  p_targets       text[],
  p_active_module text default null
)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(distinct pp."userId"), '{}')
  from "ProProfile" pp
  where pp.type = p_type::"ProProfileType"
    and (p_active_module is null
         or p_active_module::"ProModule" = any (pp."activeModules"))
    and exists (
      select 1
      from jsonb_array_elements_text(
        case when jsonb_typeof(pp.bindings -> p_binding_key) = 'array'
             then pp.bindings -> p_binding_key
             else '[]'::jsonb
        end
      ) entry(value)
      where lower(btrim(entry.value)) in (
        select lower(btrim(t)) from unnest(p_targets) t
      )
    );
$$;

-- ---------------------------------------------------------------------------
-- 4. Counterparty contact (courier/driver name + phone for my own rows)
-- ---------------------------------------------------------------------------
-- RLS keeps other people's `User` rows invisible, but the courier assigned to
-- my order (or the driver of my ride) is a legitimate contact. Exposes only
-- name + phone — never email.
create or replace function app.counterparty_contact(p_user_id text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when exists (
    select 1 from "Order"      x where x."deliveryUserId" = p_user_id and x."userId" = app.current_user_id()
    union all
    select 1 from "RideBooking" x where x."driverUserId"  = p_user_id and x."userId" = app.current_user_id()
    union all
    select 1 from "ParcelDelivery" x where x."courierUserId" = p_user_id and x."userId" = app.current_user_id()
    union all
    select 1 from "Conversation" c where c."participantUserId" = p_user_id and c."userId" = app.current_user_id()
  ) then (
    select jsonb_build_object(
             'id', u.id,
             'name', btrim(u."firstName" || ' ' || u."lastName"),
             'phone', u.phone)
      from "User" u where u.id = p_user_id
  ) else null end;
$$;

-- ---------------------------------------------------------------------------
-- create_notification: allow notifying a pro I already talk to
-- ---------------------------------------------------------------------------
-- The existing guard permits cross-inbox writes when the caller has any
-- booking row. A customer messaging a store *before* their first purchase has
-- none — the pro would silently never get the push. Sharing a conversation
-- thread is an equally strong relationship, so add it to the allow-list.
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
     or exists (
       select 1 from "Conversation" c
        where c."participantUserId" = user_id
          and c."userId" = v_self
     )
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
     user_id, type::"NotificationType", module::"NotificationModule",
     priority::"NotificationPriority", title, body, route,
     dedupe_key, coalesce(data, metadata), coalesce(metadata, data),
     coalesce(created_at, now()), read_at)
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

-- ---------------------------------------------------------------------------
-- Public shims (PostgREST only sees `public`)
-- ---------------------------------------------------------------------------
create or replace function public.create_car_rental_booking(
  p_user_id text, p_car_id text, p_start timestamptz, p_end timestamptz,
  p_pickup text, p_dropoff text default null, p_notes text default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select app.create_car_rental_booking(p_user_id, p_car_id, p_start, p_end,
                                       p_pickup, p_dropoff, p_notes)
$$;

create or replace function public.car_rental_available(
  p_car_id text, p_start timestamptz, p_end timestamptz
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select app.car_rental_available(p_car_id, p_start, p_end)
$$;

create or replace function public.cancel_car_rental_booking(
  p_booking_id text, p_user_id text
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select app.cancel_car_rental_booking(p_booking_id, p_user_id)
$$;

create or replace function public.resolve_bound_profile_user_ids(
  p_type text, p_binding_key text, p_targets text[],
  p_active_module text default null
)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select app.resolve_bound_profile_user_ids(p_type, p_binding_key, p_targets,
                                            p_active_module)
$$;

create or replace function public.counterparty_contact(p_user_id text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select app.counterparty_contact(p_user_id)
$$;

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
    dedupe_key, metadata, data, created_at, read_at)
$$;

-- ---------------------------------------------------------------------------
-- Grants: authenticated only — anon never reaches any of these.
-- ---------------------------------------------------------------------------
revoke all on function public.create_car_rental_booking(text, text, timestamptz, timestamptz, text, text, text) from public, anon;
revoke all on function public.car_rental_available(text, timestamptz, timestamptz)  from public, anon;
revoke all on function public.cancel_car_rental_booking(text, text)                  from public, anon;
revoke all on function public.resolve_bound_profile_user_ids(text, text, text[], text) from public, anon;
revoke all on function public.counterparty_contact(text)                            from public, anon;
revoke all on function public.create_notification(text, text, text, text, text, text, text, text, text, jsonb, jsonb, timestamptz, timestamptz) from public, anon;

grant execute on function public.create_car_rental_booking(text, text, timestamptz, timestamptz, text, text, text) to authenticated;
grant execute on function public.car_rental_available(text, timestamptz, timestamptz)  to authenticated;
grant execute on function public.cancel_car_rental_booking(text, text)                  to authenticated;
grant execute on function public.resolve_bound_profile_user_ids(text, text, text[], text) to authenticated;
grant execute on function public.counterparty_contact(text)                            to authenticated;
grant execute on function public.create_notification(text, text, text, text, text, text, text, text, text, jsonb, jsonb, timestamptz, timestamptz) to authenticated;
