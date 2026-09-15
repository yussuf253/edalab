-- ============================================================
-- Create Pharmacy + Medicine tables and migrate pharmacy data
-- out of the "Product" table.
--
-- Migration plan:
--   0. Create the "Pharmacy" and "Medicine" tables (matching the Prisma
--      schema) plus indexes and the OrderItem.medicineId column.
--   1. Create "Pharmacy" (one row per distinct sourceBusiness among
--      PHARMACY-typed products) — geo comes from the same lookup the API
--      used to hardcode; unknown pharmacies get NULL coordinates.
--   2. Create "Medicine" and copy every PHARMACY-typed product into it,
--      linking to its pharmacy via brand / metadata->>'sourceBusiness'.
--   3. Delete the migrated PHARMACY products (they are now medicines).
--      ProductCategory rows for pharmacy stay — medicines reference them
--      by categoryId.
--
-- Idempotent-ish: pharmacies upsert by id (deterministic slug), medicines
-- upsert by id (copied from the product id). Re-running after new pharmacy
-- products are added migrates those too. Run in Supabase SQL Editor or psql.
--
-- NOTE: column lists include "updatedAt" explicitly (no DB default exists
-- for Prisma @updatedAt columns).
-- ============================================================

-- ── 0a. "Pharmacy" table (matches schema.prisma) ────────────
CREATE TABLE IF NOT EXISTS "Pharmacy" (
  "id"           TEXT        NOT NULL,
  "name"         TEXT        NOT NULL,
  "slug"         TEXT        NOT NULL,
  "cityZone"     TEXT[]      NOT NULL DEFAULT ARRAY[]::text[],
  "description"  TEXT,
  "imageUrl"     TEXT,
  "address"      TEXT,
  "latitude"     DOUBLE PRECISION,
  "longitude"    DOUBLE PRECISION,
  "phone"        TEXT,
  "rating"       DECIMAL(3,2) NOT NULL DEFAULT 0,
  "reviewCount"  INTEGER     NOT NULL DEFAULT 0,
  "isOpen"       BOOLEAN     NOT NULL DEFAULT true,
  "active"       BOOLEAN     NOT NULL DEFAULT true,
  "metadata"     JSONB,
  "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"    TIMESTAMP(3) NOT NULL,

  CONSTRAINT "Pharmacy_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "Pharmacy_slug_key" ON "Pharmacy"("slug");
CREATE INDEX IF NOT EXISTS "Pharmacy_active_idx" ON "Pharmacy"("active");

-- ── 0b. "Medicine" table (matches schema.prisma) ────────────
CREATE TABLE IF NOT EXISTS "Medicine" (
  "id"                   TEXT        NOT NULL,
  "pharmacyId"           TEXT        NOT NULL,
  "categoryId"           TEXT,
  "name"                 TEXT        NOT NULL,
  "description"          TEXT        NOT NULL,
  "price"                DECIMAL(10,2) NOT NULL,
  "originalPrice"        DECIMAL(10,2),
  "unit"                 TEXT,
  "dosage"               TEXT,
  "packageSize"          TEXT,
  "requiresPrescription" BOOLEAN     NOT NULL DEFAULT false,
  "rating"               DECIMAL(3,2) NOT NULL DEFAULT 0,
  "reviewCount"          INTEGER     NOT NULL DEFAULT 0,
  "imageUrlsJson"        JSONB,
  "tagsJson"             JSONB,
  "featuresJson"         JSONB,
  "badge"                TEXT,
  "inStock"              BOOLEAN     NOT NULL DEFAULT true,
  "metadata"             JSONB,
  "createdAt"            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"            TIMESTAMP(3) NOT NULL,

  CONSTRAINT "Medicine_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Medicine_pharmacyId_idx" ON "Medicine"("pharmacyId");
CREATE INDEX IF NOT EXISTS "Medicine_categoryId_idx" ON "Medicine"("categoryId");

-- ── 0c. Foreign keys (idempotent via DO blocks) ─────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Medicine_pharmacyId_fkey'
  ) THEN
    ALTER TABLE "Medicine" ADD CONSTRAINT "Medicine_pharmacyId_fkey"
      FOREIGN KEY ("pharmacyId") REFERENCES "Pharmacy"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Medicine_categoryId_fkey'
  ) THEN
    ALTER TABLE "Medicine" ADD CONSTRAINT "Medicine_categoryId_fkey"
      FOREIGN KEY ("categoryId") REFERENCES "ProductCategory"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- ── 0d. OrderItem.medicineId column + FK ────────────────────
ALTER TABLE "OrderItem" ADD COLUMN IF NOT EXISTS "medicineId" TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'OrderItem_medicineId_fkey'
  ) THEN
    ALTER TABLE "OrderItem" ADD CONSTRAINT "OrderItem_medicineId_fkey"
      FOREIGN KEY ("medicineId") REFERENCES "Medicine"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- ── 1. Pharmacies: one row per distinct business name ───────
-- Deterministic id = 'phx-' || slugified business name, so re-runs upsert
-- instead of duplicating.
INSERT INTO "Pharmacy" (
  "id", "name", "slug", "cityZone", "description", "address",
  "latitude", "longitude", "rating", "reviewCount", "isOpen", "active",
  "metadata", "updatedAt"
)
SELECT
  'phx-' || lower(regexp_replace(b.business, '[^a-zA-Z0-9]+', '-', 'g')),
  b.business,
  lower(regexp_replace(b.business, '[^a-zA-Z0-9]+', '-', 'g')),
  -- Zone: any zone already tagged on the products, else ali_sabieh fallback
  -- is NOT applied (Djibouti-ville pharmacies must stay djibouti_ville).
  -- Empty-zone businesses get djibouti_ville (matches the import sources).
  CASE
    WHEN b.zones @> ARRAY['ali_sabieh']::text[] THEN ARRAY['ali_sabieh']::text[]
    ELSE ARRAY['djibouti_ville']::text[]
  END,
  NULL,           -- description
  NULL,           -- address (API geo table known values set below)
  NULL,           -- latitude  (set below)
  NULL,           -- longitude (set below)
  b.rating,
  b.review_count,
  TRUE,           -- isOpen
  TRUE,           -- active
  jsonb_build_object('migratedFrom', 'Product', 'migratedAt', NOW()),
  NOW()
FROM (
  SELECT
    COALESCE(
      NULLIF(p."metadata"->>'sourceBusiness', ''),
      NULLIF(p."brand", ''),
      'Unknown Pharmacy'
    ) AS business,
    AVG(p."rating")  AS rating,
    SUM(p."reviewCount") AS review_count,
    array_agg(DISTINCT p."cityZone") AS zones
  FROM "Product" p
  WHERE p."moduleType" = 'PHARMACY'
  GROUP BY 1
) b
ON CONFLICT ("id") DO UPDATE SET
  "name"        = EXCLUDED."name",
  "cityZone"    = EXCLUDED."cityZone",
  "rating"      = EXCLUDED."rating",
  "reviewCount" = EXCLUDED."reviewCount",
  "updatedAt"   = NOW();

-- ── 2. Known geo coordinates (from the old hardcoded lookup) ──
-- Ali Sabieh
UPDATE "Pharmacy" SET
  "address"   = 'Ali Sabieh Town Center',
  "latitude"  = 11.1559,
  "longitude" = 42.7125
WHERE "slug" = 'pharmacie-aska';

-- Djibouti City pharmacies (same coords the API hardcoded)
UPDATE "Pharmacy" SET "address" = 'Quartier 7, Djibouti City',
  "latitude" = 11.5858, "longitude" = 43.1457 WHERE "slug" = 'pharmacie-dawo';
UPDATE "Pharmacy" SET "address" = 'Plateau du Serpent, Djibouti City',
  "latitude" = 11.5897, "longitude" = 43.1483 WHERE "slug" = 'gpca';
UPDATE "Pharmacy" SET "address" = 'Riyadh District, Djibouti City',
  "latitude" = 11.5798, "longitude" = 43.1476 WHERE "slug" = 'pharmacie-riyadh';
UPDATE "Pharmacy" SET "address" = 'Djibouti Mall Area',
  "latitude" = 11.5625, "longitude" = 43.1498 WHERE "slug" = 'pharmacie-du-mall';
UPDATE "Pharmacy" SET "address" = 'La Plaine, Djibouti City',
  "latitude" = 11.5719, "longitude" = 43.1436 WHERE "slug" = 'grande-pharmacie-de-la-corne-d-afrique';
UPDATE "Pharmacy" SET "address" = 'Independence District, Djibouti City',
  "latitude" = 11.5727, "longitude" = 43.1452 WHERE "slug" = 'independence-pharmacy';
UPDATE "Pharmacy" SET "address" = 'Near Stadium, Djibouti City',
  "latitude" = 11.5809, "longitude" = 43.1443 WHERE "slug" = 'pharmacie-para';
UPDATE "Pharmacy" SET "address" = 'Central Djibouti City',
  "latitude" = 11.5752, "longitude" = 43.1462 WHERE "slug" = 'pharmacie-de-l-ocean-indien';
UPDATE "Pharmacy" SET "address" = 'Mer Rouge Area, Djibouti City',
  "latitude" = 11.5689, "longitude" = 43.1408 WHERE "slug" = 'pharmacie-de-la-mer-rouge';
UPDATE "Pharmacy" SET "address" = 'Rue d Ethiopie, La Plaine',
  "latitude" = 11.5668, "longitude" = 43.1439 WHERE "slug" = 'pharmacie-principale';
UPDATE "Pharmacy" SET "address" = 'Plateau du Serpent',
  "latitude" = 11.5846, "longitude" = 43.1524 WHERE "slug" = 'pharmacie-polyclinique-nawil';
UPDATE "Pharmacy" SET "address" = 'Avenue 26, Djibouti City',
  "latitude" = 11.5784, "longitude" = 43.1414 WHERE "slug" = 'pharmacie-avicenne';

-- ── 3. Medicines: copy PHARMACY products, link by business ──
INSERT INTO "Medicine" (
  "id", "pharmacyId", "categoryId", "name", "description", "price",
  "originalPrice", "unit", "dosage", "packageSize", "requiresPrescription",
  "rating", "reviewCount", "imageUrlsJson", "tagsJson", "featuresJson",
  "badge", "inStock", "metadata", "updatedAt"
)
SELECT
  p."id",
  ph."id",
  p."categoryId",
  p."name",
  p."description",
  p."price",
  p."originalPrice",
  p."unit",
  p."dosage",
  p."packageSize",
  p."requiresPrescription",
  p."rating",
  p."reviewCount",
  COALESCE(p."imageUrlsJson", '[]'::jsonb),
  COALESCE(p."tagsJson", '[]'::jsonb),
  COALESCE(p."featuresJson", '[]'::jsonb),
  p."badge",
  p."inStock",
  p."metadata",
  NOW()
FROM "Product" p
JOIN "Pharmacy" ph
  ON ph."name" = COALESCE(
    NULLIF(p."metadata"->>'sourceBusiness', ''),
    NULLIF(p."brand", ''),
    'Unknown Pharmacy'
  )
WHERE p."moduleType" = 'PHARMACY'
ON CONFLICT ("id") DO UPDATE SET
  "pharmacyId"           = EXCLUDED."pharmacyId",
  "categoryId"           = EXCLUDED."categoryId",
  "name"                 = EXCLUDED."name",
  "description"          = EXCLUDED."description",
  "price"                = EXCLUDED."price",
  "originalPrice"        = EXCLUDED."originalPrice",
  "unit"                 = EXCLUDED."unit",
  "dosage"               = EXCLUDED."dosage",
  "packageSize"          = EXCLUDED."packageSize",
  "requiresPrescription" = EXCLUDED."requiresPrescription",
  "rating"               = EXCLUDED."rating",
  "reviewCount"          = EXCLUDED."reviewCount",
  "imageUrlsJson"        = EXCLUDED."imageUrlsJson",
  "tagsJson"             = EXCLUDED."tagsJson",
  "featuresJson"         = EXCLUDED."featuresJson",
  "badge"                = EXCLUDED."badge",
  "inStock"              = EXCLUDED."inStock",
  "metadata"             = EXCLUDED."metadata",
  "updatedAt"            = NOW();

-- ── 4. Remove the migrated PHARMACY products ────────────────
-- Only delete products whose id actually exists as a Medicine now, so any
-- pharmacy product that failed to migrate stays visible (fail-safe).
DELETE FROM "Product" p
USING "Medicine" m
WHERE p."id" = m."id"
  AND p."moduleType" = 'PHARMACY';

-- ── 5. Verify ───────────────────────────────────────────────
-- Pharmacies and their medicine counts:
SELECT ph."name", ph."cityZone",
       COUNT(m."id") AS medicines,
       ph."latitude" IS NOT NULL AS has_geo
FROM "Pharmacy" ph
LEFT JOIN "Medicine" m ON m."pharmacyId" = ph."id"
GROUP BY ph."id", ph."name", ph."cityZone", ph."latitude"
ORDER BY ph."name";

-- Any PHARMACY products left behind (should be zero):
SELECT COUNT(*) AS leftover_pharmacy_products
FROM "Product"
WHERE "moduleType" = 'PHARMACY';
