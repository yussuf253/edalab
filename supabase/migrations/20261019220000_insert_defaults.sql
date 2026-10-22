-- ============================================================================
-- Direct-mode insert defaults (phase 3d)
-- ============================================================================
-- Prisma generated `id` (cuid) and `updatedAt` (@updatedAt) *client-side*, so
-- neither column ever received a database default:
--
--   "Notification"."id"        default (none)   not null
--   "Address"."updatedAt"      default (none)   not null
--
-- The Express backend never noticed: Prisma always supplied both values. Any
-- direct PostgREST INSERT would fail with a NOT NULL violation instead, which
-- would break every create flow in the app (addresses, wishlist items, device
-- tokens, orders, rides, appointments, parcels…).
--
-- Adding defaults is purely additive: Prisma keeps sending both columns, so
-- backend behaviour is unchanged, while clients may now omit them.
-- ============================================================================

do $$
declare
  t text;
begin
  for t in
    select table_name
      from information_schema.tables
     where table_schema = 'public'
       and table_type = 'BASE TABLE'
  loop
    if exists (
      select 1
        from information_schema.columns
       where table_schema = 'public'
         and table_name = t
         and column_name = 'id'
         and column_default is null
    ) then
      execute format(
        'alter table public.%I alter column id set default gen_random_uuid()::text',
        t
      );
    end if;

    if exists (
      select 1
        from information_schema.columns
       where table_schema = 'public'
         and table_name = t
         and column_name = 'updatedAt'
         and column_default is null
    ) then
      execute format(
        'alter table public.%I alter column "updatedAt" set default now()',
        t
      );
    end if;
  end loop;
end;
$$;

-- `updatedAt` is not touched by UPDATE statements, so the gateway writes it
-- explicitly on every update; this default only covers INSERTs.
