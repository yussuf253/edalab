-- ============================================================================
-- Direct-mode updatedAt trigger (phase 3e)
-- ============================================================================
-- Prisma applies `@updatedAt` in the client, so an UPDATE issued straight from
-- PostgREST would leave `updatedAt` frozen. Several read paths sort by it
-- (addresses and payment methods both use `updatedAt desc`), so "make this
-- address the default" would otherwise keep sorting by an ancient timestamp.
--
-- A BEFORE UPDATE trigger reproduces exactly what the Prisma client did —
-- stamp the row at write time — for every table that has the column. Backend
-- behaviour is unchanged because Prisma already sets the same value.
--
-- The stamp only applies when the statement did NOT move `updatedAt` itself,
-- so an explicit value (a Prisma write, or a data backfill that restores a
-- historical timestamp) still wins.
-- ============================================================================

create or replace function app.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new."updatedAt" is not distinct from old."updatedAt" then
    new."updatedAt" := now();
  end if;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  for t in
    select c.table_name
      from information_schema.columns c
      join information_schema.tables tb
        on tb.table_schema = c.table_schema
       and tb.table_name = c.table_name
     where c.table_schema = 'public'
       and tb.table_type = 'BASE TABLE'
       and c.column_name = 'updatedAt'
  loop
    execute format('drop trigger if exists touch_updated_at on public.%I', t);
    execute format(
      'create trigger touch_updated_at before update on public.%I '
      || 'for each row execute function app.touch_updated_at()',
      t
    );
  end loop;
end;
$$;
