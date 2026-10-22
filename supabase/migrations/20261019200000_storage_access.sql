-- ============================================================================
-- Direct-mode storage access (phase 3c)
-- ============================================================================
-- Before this, `/media/upload` ran on the backend with the service-role key
-- (RLS bypass) and every object was then served through the unauthenticated
-- `/uploads/supabase/:bucket/*` proxy in `src/index.ts`. So the three buckets
-- were de-facto world-readable, but nobody could reach them from a client.
--
-- Direct mode has to reproduce both halves from the app itself:
--   * writes  → INSERT/UPDATE policies on storage.objects for signed-in users
--   * reads   → public buckets, because the app normalises stored references
--               (`supabase://bucket/path`) to `/storage/v1/object/public/...`
--
-- The write grant matches today's authorisation exactly: `/media/upload`
-- required a valid session token, not bucket ownership or a scoped path.
-- ============================================================================

update storage.buckets
   set public = true
 where name in ('avatars', 'media', 'prescriptions');

-- Writes ---------------------------------------------------------------------
drop policy if exists media_insert on storage.objects;
create policy media_insert
  on storage.objects
  for insert to authenticated
  with check (bucket_id in ('avatars', 'media', 'prescriptions'));

drop policy if exists media_update on storage.objects;
create policy media_update
  on storage.objects
  for update to authenticated
  using (bucket_id in ('avatars', 'media', 'prescriptions'))
  with check (bucket_id in ('avatars', 'media', 'prescriptions'));

-- Reads ---------------------------------------------------------------------
-- Public buckets are served without consulting RLS, but an authenticated
-- client that calls `.download()`/`.list()` still needs an explicit SELECT.
drop policy if exists media_select on storage.objects;
create policy media_select
  on storage.objects
  for select to authenticated
  using (bucket_id in ('avatars', 'media', 'prescriptions'));

-- Grants (Supabase seeds these, but make the migration self-contained) -------
grant select, insert, update on storage.objects to authenticated;
