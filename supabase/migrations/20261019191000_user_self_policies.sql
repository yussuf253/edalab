-- Addendum to the RLS baseline, found during verification: the owner-policy
-- loop covered 14 user-owned tables but NOT public."User" itself, so a signed-in
-- customer could not read their own profile row (fetchUserProfile returned null).
--
-- Also adds a guarded self-insert so customers who sign up via GoTrue directly
-- (no backend) can provision their own profile row on first login. Constraints:
--   * auth_uid must be the caller's own auth UUID;
--   * id must equal that UUID (keeps FKs consistent for rows created this way;
--     pre-existing rows keep their cuids).

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
