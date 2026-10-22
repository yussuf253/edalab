// One-time migration: import legacy bcrypt-only accounts into Supabase Auth.
//
// Background: the Node backend keeps a bcrypt hash in public."User"/
// public."ProAccount" and only mirrored *new* signups into GoTrue. Accounts
// created before that integration have no auth.users row, so they cannot log
// in once the backend is disabled. GoTrue's admin import endpoint accepts
// bcrypt password hashes directly, so existing passwords keep working.
//
// Usage:  node tools/import-legacy-auth.mjs [--dry-run]
// Env:    SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DIRECT_URL (from backend/.env)
//
// Idempotent: skips emails that already exist in auth.users; safe to re-run.

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { PrismaClient } from '@prisma/client';

config();

const dryRun = process.argv.includes('--dry-run');
const url = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !serviceKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in backend/.env');
  process.exit(1);
}

const admin = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const prisma = new PrismaClient({
  datasources: { db: { url: process.env.DIRECT_URL || process.env.DATABASE_URL } },
});

async function collectTargets() {
  const users = await prisma.$queryRawUnsafe(`
    select id, email, "passwordHash" as hash, "firstName", "lastName", phone,
           'user' as kind
    from "User"
    where auth_uid is null
      and "passwordHash" is not null
      and "passwordHash" like '$2%'
  `);
  const pros = await prisma.$queryRawUnsafe(`
    select id, email, "passwordHash" as hash, "fullName", null as "firstName",
           null as "lastName", phone, 'pro' as kind
    from "ProAccount"
    where auth_uid is null
      and "passwordHash" is not null
      and "passwordHash" like '$2%'
  `);
  return [...users, ...pros];
}

async function importUser(target) {
  const displayName =
    target.kind === 'pro'
      ? target.fullName
      : [target.firstName, target.lastName].filter(Boolean).join(' ');

  // Admin create-user accepts `password_hash` (bcrypt) instead of a plaintext
  // `password`, which is exactly what a migration needs. (`?import=true` is the
  // *bulk* array endpoint and does not apply here.)
  const res = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: target.email,
      password_hash: target.hash,
      email_confirm: true, // legacy accounts predate email confirmation loops
      user_metadata: { displayName, phone: target.phone ?? null, kind: target.kind },
      app_metadata: { legacy_id: target.id, legacy_kind: target.kind },
    }),
  });

  if (res.status === 422) {
    const body = await res.text();
    if (/already.*(exists|registered)/i.test(body)) return 'exists';
  }
  if (!res.ok) {
    throw new Error(`${res.status} ${(await res.text()).slice(0, 200)}`);
  }
  const created = await res.json();
  return created?.id ?? 'created';
}

function linkAuthUid(kind, email, authId) {
  const table = kind === 'pro' ? '"ProAccount"' : '"User"';
  return prisma.$executeRawUnsafe(
    `update ${table} set auth_uid = $1::uuid where lower(email) = lower($2) and auth_uid is null`,
    authId,
    email,
  );
}

(async () => {
  const targets = await collectTargets();
  console.log(`${targets.length} legacy accounts need importing${dryRun ? ' (dry run)' : ''}`);

  let ok = 0, exists = 0, failed = 0;
  for (const t of targets) {
    if (dryRun) {
      console.log(`  [dry] ${t.kind} ${t.email}`);
      continue;
    }
    try {
      const result = await importUser(t);
      if (result === 'exists') {
        // Email is in GoTrue but auth_uid was null — resolve and link
        // (paginated: the default page size is 50).
        let match = null;
        for (let page = 1; page <= 10 && !match; page++) {
          const { data } = await admin.auth.admin.listUsers({ page, perPage: 100 });
          match = data?.users?.find(
            (u) => u.email?.toLowerCase() === t.email.toLowerCase(),
          );
          if (!data?.users?.length) break;
        }
        if (match) await linkAuthUid(t.kind, t.email, match.id);
        exists++;
        console.log(`  linked existing ${t.kind} ${t.email}`);
      } else {
        await linkAuthUid(t.kind, t.email, result);
        ok++;
        console.log(`  imported ${t.kind} ${t.email}`);
      }
    } catch (e) {
      failed++;
      console.error(`  FAILED ${t.kind} ${t.email}: ${e.message}`);
    }
  }

  if (!dryRun) {
    const [u, p] = await Promise.all([
      prisma.$queryRawUnsafe(`select count(*)::int as n from "User" where auth_uid is null`),
      prisma.$queryRawUnsafe(`select count(*)::int as n from "ProAccount" where auth_uid is null`),
    ]);
    console.log(`done: ${ok} imported, ${exists} linked, ${failed} failed`);
    console.log(`remaining unlinked: User=${u[0].n} ProAccount=${p[0].n}`);
  }
  await prisma.$disconnect();
})().catch((e) => {
  console.error('import failed:', e);
  process.exit(1);
});
