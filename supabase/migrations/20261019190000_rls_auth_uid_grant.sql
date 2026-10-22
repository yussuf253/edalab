-- Addendum to 20261019180000_rls_baseline.sql
-- The apps filter rows with `.eq('auth_uid', <own supabase uid>)` on
-- public."User" and public."ProAccount". Column-level SELECT privileges apply
-- to WHERE-clause columns too, so auth_uid must be in the granted set.
-- It is the caller's own auth UUID (already known to them) — not sensitive.

grant select (auth_uid) on public."User" to authenticated;
grant select (auth_uid) on public."ProAccount" to authenticated;
