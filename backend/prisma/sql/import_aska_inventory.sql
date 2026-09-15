-- ============================================================
-- Import Pharmacie Aska's real inventory (medecines.csv, 184 items)
-- into the Medicine table.
--
-- Source: root medecines.csv exported from the pharmacy's POS system.
--   - sell_price is in DJF
--   - items with qty=0 or status='low' are imported but flagged
--     inStock=false so they don't appear orderable
--   - zero/missing sell_price defaults to 5.00 DJF placeholder
--     (25 items had no price — review them in the verify query)
--   - categoryId is NULL for all rows: the CSV has no category data
--     (the app falls back to 'General' for uncategorized medicines)
--   - requiresPrescription is keyword-based (antibiotics, chronic
--     disease meds etc.) — review before enabling Rx enforcement
--
-- Idempotent: upserts on id. Run in Supabase SQL Editor or psql.
-- ============================================================

INSERT INTO "Medicine" (
  "id", "pharmacyId", "categoryId", "name", "description", "price",
  "originalPrice", "unit", "dosage", "packageSize", "requiresPrescription",
  "rating", "reviewCount", "imageUrlsJson", "tagsJson", "featuresJson",
  "badge", "inStock", "metadata", "updatedAt"
) VALUES
  (
    'phx-aska-csv-amoxicare-sirop-250mg', 'phx-pharmacie-aska', NULL,
    'amoxicare sirop 250mg',
    'Stocked at Pharmacie Aska (in stock).',
    650.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "0082793b-353c-494d-9e87-0356900c13da", "productCode": "N1-1788632147843771", "barcode": "P0100000168", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cutacnyl-gel-5', 'phx-pharmacie-aska', NULL,
    'Cutacnyl gel 5%',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "00d4cba9-895c-494c-b395-b5b17739ec3f", "productCode": "N1-1788545549995097", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-upsa-c-1000mg', 'phx-pharmacie-aska', NULL,
    'UPSA-C 1000mg',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "01195bc2-ee44-4b7b-925c-49d69656953a", "productCode": "N1-1788545549945600", "stockQty": 11, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-feroglobin-capsules', 'phx-pharmacie-aska', NULL,
    'Feroglobin capsules',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "01828021-8c74-4566-aa8c-f3efcef98eb3", "productCode": "N1-1788545549927484", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fungazone-sirop', 'phx-pharmacie-aska', NULL,
    'Fungazone sirop',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "02b294ef-1f75-44dd-92ea-c1b1ac9576cc", "productCode": "N1-1788545550316875", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cutacnyl-gel-10', 'phx-pharmacie-aska', NULL,
    'Cutacnyl gel 10%',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "02f3c2bc-1bf6-46f3-a04e-a93e5ce4563b", "productCode": "N1-1788545549995097-2", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-parogencyl-nouvelle-formule-75ml', 'phx-pharmacie-aska', NULL,
    'Parogencyl nouvelle formule 75ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "036fcfde-4b9b-4821-9e75-cfe7603b6853", "productCode": "N1-1788545550292627", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-vogal-nd-sirop-0-4', 'phx-pharmacie-aska', NULL,
    'Vogalènd sirop 0,4%',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    900.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "07d2151e-72de-41c2-b067-5d86d62d6458", "productCode": "N1-1788545549364560", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-navidoxine-25mg', 'phx-pharmacie-aska', NULL,
    'Navidoxine 25mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "09aa2580-a59a-4f3b-aaa3-2b2b789273ec", "productCode": "N1-1788545549952886", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nospa-40mg-b20', 'phx-pharmacie-aska', NULL,
    'Nospa 40mg B20',
    'Stocked at Pharmacie Aska (in stock).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "0a55a2b4-9062-4f05-9817-b5ec0bc8379e", "productCode": "N1-1789315564708000", "barcode": "P0100000173", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-s-sinna-sweetener-1200-tablets', 'phx-pharmacie-aska', NULL,
    'Süsinna sweetener 1200 tablets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "0e64cb6a-3101-4786-9446-6766a8009c21", "productCode": "N1-1788545550000084-1", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-toco-500mg', 'phx-pharmacie-aska', NULL,
    'Toco 500mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    900.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "0e834124-5e45-43ce-82b9-e745443fb92c", "productCode": "N1-1788545549991847", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fucidine-creme', 'phx-pharmacie-aska', NULL,
    'fucidine creme',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "0f58285e-4f85-454e-93b0-0583b2e93e81", "productCode": "N1-1788630078102798", "barcode": "P0100000165", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-doliprane-300mg', 'phx-pharmacie-aska', NULL,
    'Doliprane 300mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    550.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "10bc095f-b8f5-4e47-81ba-3152dd09c931", "productCode": "N1-1788545550282347", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-glucose-5', 'phx-pharmacie-aska', NULL,
    'Glucose 5%',
    'Stocked at Pharmacie Aska (in stock).',
    500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "147f5b87-0801-49ba-b26b-1cfdb190a1b9", "productCode": "N1-1788545549997091-1", "stockQty": 19, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-p-diasure-sachets-80mg', 'phx-pharmacie-aska', NULL,
    'Pédiasure sachets 80mg',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "14a2b87d-661a-4a82-8a66-53eefb93f010", "productCode": "N1-1788545550314880", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-acide-folique-5mg', 'phx-pharmacie-aska', NULL,
    'Acide folique 5mg',
    'Stocked at Pharmacie Aska (in stock).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "15107286-b44b-4216-8ba3-f243268071dc", "productCode": "N1-1788545549941332", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ferbasi-200ml', 'phx-pharmacie-aska', NULL,
    'Ferbasi 200ml',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1589bb18-7225-48d3-adeb-c5827cd8e7b9", "productCode": "N1-1788545549358560", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-insumed-seringue-0-3ml', 'phx-pharmacie-aska', NULL,
    'Insumed seringue 0,3ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "15e8b264-b4bc-484e-b7fa-81ed53de58ed", "productCode": "N1-1788545549383480", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-neurobion-comprim-s', 'phx-pharmacie-aska', NULL,
    'Neurobion comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1620cdea-27fa-45e8-b515-8a81e28958af", "productCode": "N1-1788545549954950", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nrc-cannula', 'phx-pharmacie-aska', NULL,
    'NRC cannula',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "16304df4-43ee-42b5-b2ff-7fd5a308ba03", "productCode": "N1-1788545550251303", "stockQty": 79, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-maxidrol-collyre', 'phx-pharmacie-aska', NULL,
    'Maxidrol collyre',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "16700f48-9ee3-4927-8b63-61b3a049114f", "productCode": "N1-1788545549994097-1", "stockQty": 13, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ascabiol-solution', 'phx-pharmacie-aska', NULL,
    'Ascabiol solution',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "17ec9849-8ded-47f0-88c8-463cdbbdfb1f", "productCode": "N1-1788545550315876", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-oflocet-auriculaire-1-5mg', 'phx-pharmacie-aska', NULL,
    'Oflocet auriculaire 1,5mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "19cad82a-f5ea-44aa-ba95-0c230278dd81", "productCode": "N1-1788545549967617", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-oroken-oral-40mg-5ml', 'phx-pharmacie-aska', NULL,
    'Oroken oral 40mg/5ml',
    'Stocked at Pharmacie Aska (in stock).',
    2000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1bf46456-915f-47c7-b39d-997514ca947e", "productCode": "N1-1788545549347588", "stockQty": 21, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-hemax-4000-ui', 'phx-pharmacie-aska', NULL,
    'Hemax 4000 UI',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1c82cd26-e11a-4a36-8f17-1f89efc62566", "productCode": "N1-1788545550289343", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ns-sodium-500ml', 'phx-pharmacie-aska', NULL,
    'NS sodium 500ml',
    'Stocked at Pharmacie Aska (in stock).',
    500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1cdc1dfe-6c37-4c76-a0a0-a3c49e3bfc0c", "productCode": "N1-1788545549999085-2", "stockQty": 30, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ketum-100mg', 'phx-pharmacie-aska', NULL,
    'Ketum 100mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1d031576-b08d-43ac-ab53-e7812a12e20d", "productCode": "N1-1788545549950313", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nurabol-sirop-2mg-5ml-125ml', 'phx-pharmacie-aska', NULL,
    'Nurabol sirop 2mg/5ml 125ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1e395cf5-fe4a-4461-bc30-d7a4d621c9a5", "productCode": "N1-1788545549935341", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-efferalgan-300mg', 'phx-pharmacie-aska', NULL,
    'Efferalgan 300mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1eb7b069-6e26-4f44-b461-4600ce06015f", "productCode": "N1-1788551313698255", "barcode": "P0100000163", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ringer-l-injection-500ml', 'phx-pharmacie-aska', NULL,
    'Ringer L injection 500ml',
    'Stocked at Pharmacie Aska (in stock).',
    500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1ed3972f-2466-415b-9cbf-b55bbee1c0b3", "productCode": "N1-1788545549998088", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fortal', 'phx-pharmacie-aska', NULL,
    'Fortal',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1f8ce815-6ea8-4eb0-b2e0-71000ecb02d5", "productCode": "N1-1788545550307891", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-indocollyre-0-1', 'phx-pharmacie-aska', NULL,
    'Indocollyre 0,1%',
    'Stocked at Pharmacie Aska (in stock).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "1fe83b24-93df-433a-8348-bc9e4060fccd", "productCode": "N1-1788545549972499", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-clamoxyl-500mg-g-lules', 'phx-pharmacie-aska', NULL,
    'Clamoxyl 500mg gélules',
    'Stocked at Pharmacie Aska (in stock).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "22ae127a-b726-41d4-ad17-7d5ab1d9bdd0", "productCode": "N1-1788545549963550", "stockQty": 36, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cooper-serum-physiologique-nasal', 'phx-pharmacie-aska', NULL,
    'Cooper serum physiologique nasal',
    'Stocked at Pharmacie Aska (in stock).',
    40.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "231577bf-9632-4c64-a9bb-c7095892aeb3", "productCode": "N1-1788545549355560-1", "stockQty": 93, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-seretide', 'phx-pharmacie-aska', NULL,
    'Seretide',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2250.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "233a6254-9033-43ee-a36e-a130a6666208", "productCode": "N1-1788545550321080", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-neopred-20mg', 'phx-pharmacie-aska', NULL,
    'Neopred 20mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1450.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "24216adc-1dd3-4c80-aa20-d3a01537deaf", "productCode": "N1-1788545549943675", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-brufen-400mg', 'phx-pharmacie-aska', NULL,
    'Brufen 400mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "24698555-09b0-45cb-a04d-3c525bba8a1f", "productCode": "N1-1788545549981492", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pervital-sirop', 'phx-pharmacie-aska', NULL,
    'pervital sirop',
    'Stocked at Pharmacie Aska (in stock).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "267b44e9-9acf-4b51-9fe5-22849145e127", "productCode": "N1-1788630194029284", "barcode": "P0100000166", "stockQty": 15, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-flucon-collyre', 'phx-pharmacie-aska', NULL,
    'Flucon collyre',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "27273d20-651e-4f34-b6a9-567fa8476f6b", "productCode": "N1-1788545549994097", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-augmentin-adultes-500mg', 'phx-pharmacie-aska', NULL,
    'Augmentin adultes 500mg',
    'Stocked at Pharmacie Aska (in stock).',
    1800.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "27b009fb-0a0f-4460-a2c6-64506f9614c6", "productCode": "N1-1788545549965953", "stockQty": 19, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-seringue-5ml', 'phx-pharmacie-aska', NULL,
    'Seringue 5ml',
    'Stocked at Pharmacie Aska (in stock).',
    70.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "2bc8a954-6fbd-40bc-b50d-cbe6fd5df361", "productCode": "N1-1789318292747000", "barcode": "P0100000182", "stockQty": 18, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-efferalgan-80mg', 'phx-pharmacie-aska', NULL,
    'Efferalgan 80mg',
    'Stocked at Pharmacie Aska (in stock).',
    650.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "2d52dbbf-4fa0-4210-ac89-dab9c7387ad2", "productCode": "N1-1788545550288300", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-bactrim-sirop-200-40mg', 'phx-pharmacie-aska', NULL,
    'Bactrim sirop 200/40mg',
    'Stocked at Pharmacie Aska (in stock).',
    1350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "2d8d3fd0-b220-4591-9f19-b43275161a2d", "productCode": "N1-1788547995776461", "barcode": "P0100000159", "stockQty": 18, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ibuprof-ne-400mg', 'phx-pharmacie-aska', NULL,
    'Ibuprofène 400mg',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "2f852399-6353-4dda-abb6-9958e8e99c57", "productCode": "N1-1788545549982999", "stockQty": 35, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pervital-20-comprim-s', 'phx-pharmacie-aska', NULL,
    'Pervital 20 comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "30520bf6-e3e4-489b-82e0-2645b4d0eef1", "productCode": "N1-1788545549887319", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-finast-ride-viatris-comprim-s', 'phx-pharmacie-aska', NULL,
    'Finastéride Viatris comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "341674d7-e4da-4cc7-ad26-5e1601977163", "productCode": "N1-1788545549374503", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-dakin-250ml', 'phx-pharmacie-aska', NULL,
    'Dakin 250ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "346116b5-2a26-4eb3-9b92-8f37405315e9", "productCode": "N1-1788545549999085", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-aspirin-100mg', 'phx-pharmacie-aska', NULL,
    'Aspirin 100mg',
    'Stocked at Pharmacie Aska (in stock).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "346745dd-afa0-4407-a1a4-df9a8c3eeb0c", "productCode": "N1-1788545549988865", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-efferalgan-500mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Efferalgan 500mg comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    650.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "34915e69-6a88-42fa-b900-ad380fdae6b4", "productCode": "N1-1788545549391460", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-on-call-plus-appareil', 'phx-pharmacie-aska', NULL,
    'On Call Plus appareil',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "3491764b-4c67-457e-9c64-69fe3301d3ef", "productCode": "N1-1788545550312887", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-wellbaby-sirop-150ml', 'phx-pharmacie-aska', NULL,
    'Wellbaby sirop 150ml',
    'Stocked at Pharmacie Aska (in stock).',
    1450.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "3573bcfc-ef38-46a8-9a89-8b5d81c54b7e", "productCode": "N1-1789315114702000", "barcode": "P0100000172", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-healax-cream-100g', 'phx-pharmacie-aska', NULL,
    'Healax cream 100g',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "370b9607-0092-445e-ad0b-fbeaa8038e46", "productCode": "N1-1788545549385475", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-test-de-grossess', 'phx-pharmacie-aska', NULL,
    'test de grossess',
    'Stocked at Pharmacie Aska (in stock).',
    200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "384c5e59-1e85-4b9b-a230-b38377d19b0b", "productCode": "N1-1788632617667561", "barcode": "P0100000169", "stockQty": 42, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cortancyl-20mg-comprim', 'phx-pharmacie-aska', NULL,
    'Cortancyl 20mg comprimé',
    'Stocked at Pharmacie Aska (in stock).',
    1400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "38dde21c-56a3-4f3f-8c31-8d5a6a66fd6c", "productCode": "N1-1789316091421000", "barcode": "P0100000176", "stockQty": 5, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-otipax-ph-nazone-auriculaire', 'phx-pharmacie-aska', NULL,
    'Otipax phénazone auriculaire',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "3ac101dc-25d4-4512-b2c5-8f852cba5e4b", "productCode": "N1-1788545549969940-1", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-azitro-500mg-comprim', 'phx-pharmacie-aska', NULL,
    'Azitro 500mg comprimé',
    'Stocked at Pharmacie Aska (in stock).',
    950.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "3cf06a43-2106-4baf-b875-1fd362394c72", "productCode": "N1-1789316550615000", "barcode": "P0100000177", "stockQty": 3, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cetirizine-10mg-comprim', 'phx-pharmacie-aska', NULL,
    'Cetirizine 10mg comprimé',
    'Stocked at Pharmacie Aska (in stock).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "41cd0364-c2af-4324-b031-fff2a51e71a9", "productCode": "N1-1789317740726000", "barcode": "P0100000180", "stockQty": 4, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pediakid-sirop-22-vitamines', 'phx-pharmacie-aska', NULL,
    'Pediakid sirop 22 vitamines',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "41d68509-65cd-419e-9c1b-44e7ab4673d3", "productCode": "N1-1788545549382484", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-broncathiol-adult-5', 'phx-pharmacie-aska', NULL,
    'Broncathiol adult 5%',
    'Stocked at Pharmacie Aska (in stock).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "446438cf-a6e9-4828-9ed5-fd3400dd5379", "productCode": "N1-1788548733341993", "barcode": "P0100000160", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-flomozine-cr-me', 'phx-pharmacie-aska', NULL,
    'Flomozine crème',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1450.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "44aa8b9d-3889-43bb-9b87-a3ad5e82306c", "productCode": "N1-1788545550323083", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-maxidex-0-1-collyre', 'phx-pharmacie-aska', NULL,
    'Maxidex 0,1% collyre',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4592a1ce-3840-4abe-b803-7c1374d7a890", "productCode": "N1-1788545549993468", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-helpha-12ml', 'phx-pharmacie-aska', NULL,
    'Helpha 12ml',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "48bb301e-2b62-42b1-8ae9-485c05df60eb", "productCode": "N1-1788545550279014", "stockQty": 95, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-dorco-toothbrush-12-pi-ces', 'phx-pharmacie-aska', NULL,
    'Dorco toothbrush 12 pièces',
    'Stocked at Pharmacie Aska (in stock).',
    400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "494174c1-6993-450d-947b-a2e86a9248d0", "productCode": "N1-1788545550296657", "stockQty": 9, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-kop', 'phx-pharmacie-aska', NULL,
    'KOP',
    'Stocked at Pharmacie Aska (in stock).',
    100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "49a68c8f-7a8e-4e22-8c3e-be7d84ac438a", "productCode": "N1-1788545550000084-2", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-flexdol-comprim-s', 'phx-pharmacie-aska', NULL,
    'Flexdol comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4ac9ad8f-43af-404a-b694-33b3bbbbe120", "productCode": "N1-1788545549997091-2", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-decontractyl-boite-de-50', 'phx-pharmacie-aska', NULL,
    'Decontractyl boite de 50',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4b30f6c7-f6e2-4171-8887-90c85743cade", "productCode": "N1-1788545549947632", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-disten-300-380mg-50-comprim-s', 'phx-pharmacie-aska', NULL,
    'Disten 300/380mg 50 comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4b7ed26a-26eb-4dd9-9a90-a6c32158e8dd", "productCode": "N1-1788545549936389", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-gynanfort-vaginal-10-ovules', 'phx-pharmacie-aska', NULL,
    'Gynanfort vaginal 10 ovules',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4da2f5ea-e7b2-4b39-a559-fa0f33261fe5", "productCode": "N1-1788545549996094-1", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-advilmed-sirop-enfants-nourrissons-20mg', 'phx-pharmacie-aska', NULL,
    'Advilmed sirop enfants/nourrissons 20mg',
    'Stocked at Pharmacie Aska (in stock).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4e8256a4-b562-46ff-b2e7-af8cd4822aa0", "productCode": "N1-1788545549997091", "stockQty": 3, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-biafine', 'phx-pharmacie-aska', NULL,
    'Biafine',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    950.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4ef3f604-3c04-42b8-b032-7ffb63f38789", "productCode": "N1-1788545550303629", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fluocaril-145mg-6-13-ans', 'phx-pharmacie-aska', NULL,
    'Fluocaril 145mg 6-13 ans',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "4f956f74-3cd2-46bf-8af8-8455bfa06a1d", "productCode": "N1-1788545550294636", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-c-rulyse-5g-auriculaire', 'phx-pharmacie-aska', NULL,
    'Cérulyse 5g auriculaire',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "537fdb12-9d42-436f-9611-0ca0572bd444", "productCode": "N1-1788545549971103", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-babaysoin', 'phx-pharmacie-aska', NULL,
    'babaysoin',
    'Stocked at Pharmacie Aska (in stock).',
    40.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "5491bb81-61ba-4cce-9fd9-58e95f8a7072", "productCode": "N1-1788685016406488", "barcode": "P0100000171", "stockQty": 88, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-eau-oxyg-n-e-250ml', 'phx-pharmacie-aska', NULL,
    'Eau oxygénée 250ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    650.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "549a0582-31f8-4c48-bcb5-e18e34c2b6ec", "productCode": "N1-1788545549999085-1", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-sedorrho-de-cr-me', 'phx-pharmacie-aska', NULL,
    'Sedorrhoïde crème',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "5abee3f2-1151-42c4-bc38-e7f2e76fa11a", "productCode": "N1-1788545550324076-1", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-maalox-sachet', 'phx-pharmacie-aska', NULL,
    'Maalox sachet',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "5e2f8c04-0db0-4c4c-902c-5a5b9da74994", "productCode": "N1-1788545549350578", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-humex-0-30g-oral', 'phx-pharmacie-aska', NULL,
    'Humex 0,30g oral',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "5e735fd9-6a62-4b06-880d-6a66038da21c", "productCode": "N1-1788545549372521", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-seringue-10ml', 'phx-pharmacie-aska', NULL,
    'Seringue 10ml',
    'Stocked at Pharmacie Aska (in stock).',
    70.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "649a075f-149d-493c-99ef-43a3ad34a7d9", "productCode": "N1-1789318553493000", "barcode": "P0100000183", "stockQty": 99, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tanganil500-comprim-s', 'phx-pharmacie-aska', NULL,
    'Tanganil500 comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1550.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6770e8c3-0738-4c4f-8098-691e833c9079", "productCode": "N1-1788545549990656", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-novomix-flexpen', 'phx-pharmacie-aska', NULL,
    'Novomix FlexPen',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "67870d8e-651f-4b70-b7da-da93d65d251b", "productCode": "N1-1788545550285353", "stockQty": 25, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-duphaston-cp-10mg', 'phx-pharmacie-aska', NULL,
    'Duphaston CP 10mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "687d6c08-11a4-4cbb-b18e-005e945d2500", "productCode": "N1-1788545550302610", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-omeprazole-cristers-20mg', 'phx-pharmacie-aska', NULL,
    'Omeprazole Cristers 20mg',
    'Stocked at Pharmacie Aska (in stock).',
    1300.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "696fcc53-c2e8-4e76-9108-bafd6f734f91", "productCode": "N1-1788545549938382", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-amoxicare-sirop-125mg', 'phx-pharmacie-aska', NULL,
    'amoxicare sirop 125mg',
    'Stocked at Pharmacie Aska (in stock).',
    600.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6a9bf1c6-b81b-4af4-a524-8fd590cf545e", "productCode": "N1-1788632105419025", "barcode": "P0100000167", "stockQty": 20, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-albencare-comprim-s-400mg', 'phx-pharmacie-aska', NULL,
    'Albencare comprimés 400mg',
    'Stocked at Pharmacie Aska (in stock).',
    2350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6ae5ae76-c9d7-4795-95a4-3c49799eb35c", "productCode": "N1-1788545549376511", "stockQty": 6, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-janumet-50-850mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Janumet 50/850mg comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6b183a43-b842-46d3-b7f3-deb8e463d374", "productCode": "N1-1788545549383480-1", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-sodium-chloride-0-9-500ml', 'phx-pharmacie-aska', NULL,
    'Sodium chloride 0,9% 500ml',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6d53e9f3-9f42-4188-a62c-45968859a682", "productCode": "N1-1788545549998088-1", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-zentel-comprim-s-400mg', 'phx-pharmacie-aska', NULL,
    'Zentel comprimés 400mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    900.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "6dc8530b-e579-4dfa-a855-28e75fde91de", "productCode": "N1-1788545549366525", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-sensodyne-75ml', 'phx-pharmacie-aska', NULL,
    'Sensodyne 75ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1150.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "705564f8-e2d4-47d0-a618-ef958041ed09", "productCode": "N1-1788545550293675", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-rovamycine-sachets', 'phx-pharmacie-aska', NULL,
    'Rovamycine sachets',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "71ed4458-84f7-4506-adc9-47f2f937bf8f", "productCode": "N1-1788545550305632", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tributine-150mg-20-sachets', 'phx-pharmacie-aska', NULL,
    'Tributine 150mg 20 sachets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "74a725c8-70e6-425c-9c3c-7f0a4e169f92", "productCode": "N1-1788545549993158", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nozinan-25mg-comprim-s-2', 'phx-pharmacie-aska', NULL,
    'Nozinan 25mg comprimés 2',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "74b0746c-3399-4b63-a492-81a1a6eb3413", "productCode": "N1-1788545550306604", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-bactrim-comprim-s-400-80mg', 'phx-pharmacie-aska', NULL,
    'Bactrim comprimés 400/80mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "74d3d06e-8757-4c82-92cc-c8b5008ca18e", "productCode": "N1-1788545549960192", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-feroglobin-b12-sirop', 'phx-pharmacie-aska', NULL,
    'Feroglobin B12 sirop',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "758e73c0-b660-43be-8014-a696bab04cd9", "productCode": "N1-1788545549926476", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-amaryl-3mg', 'phx-pharmacie-aska', NULL,
    'Amaryl 3mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "76e26f06-231d-4b9a-8b4e-c1bd3e01bd4e", "productCode": "N1-1788545549991066", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-claril-500mg', 'phx-pharmacie-aska', NULL,
    'Claril 500mg',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "774ce529-46c4-448b-b458-192c055822a7", "productCode": "N1-1788545549992197", "stockQty": 9, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-flagyl-sirop-125mg', 'phx-pharmacie-aska', NULL,
    'Flagyl sirop 125mg',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "78d5f1b2-7db7-452e-b5fb-938cba82764f", "productCode": "N1-1788545549364560-1", "stockQty": 14, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-chibroxine-collyre-0-3', 'phx-pharmacie-aska', NULL,
    'Chibroxine collyre 0,3%',
    'Stocked at Pharmacie Aska (in stock).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "79eea309-ed4b-4e80-b302-5e98151c2dcb", "productCode": "N1-1788545549994097-2", "stockQty": 9, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-hydravit-10mg', 'phx-pharmacie-aska', NULL,
    'Hydravit 10mg',
    'Stocked at Pharmacie Aska (in stock).',
    200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7ae8a5c0-0206-4f31-ab97-fec7f49efca6", "productCode": "N1-1788545549344611", "stockQty": 32, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-trimetabol-oral-150ml', 'phx-pharmacie-aska', NULL,
    'Trimetabol oral 150ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7bf51fbb-8500-484f-8612-0680aba01246", "productCode": "N1-1788545549346580", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-glucophage-850mg', 'phx-pharmacie-aska', NULL,
    'Glucophage 850mg',
    'Stocked at Pharmacie Aska (in stock).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7c72357c-6c67-4ead-802c-10485e3d785e", "productCode": "N1-1788545549988152", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-duphalac-10g-15ml-20-sachets', 'phx-pharmacie-aska', NULL,
    'Duphalac 10g/15ml 20 sachets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1150.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7c784e08-d069-4a20-82a4-9f22aef7e28f", "productCode": "N1-1788545549978516", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-crosscal-50mg', 'phx-pharmacie-aska', NULL,
    'Crosscal 50mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7dabddb1-d835-435c-b80d-cc12e27ed446", "productCode": "N1-1788545549957628", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-mixtard-30-100ml', 'phx-pharmacie-aska', NULL,
    'Mixtard 30 100ml',
    'Stocked at Pharmacie Aska (in stock).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7f4689d0-3708-484a-886d-f4c232e22097", "productCode": "N1-1788545550283314", "stockQty": 54, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fucidine-2-pommade', 'phx-pharmacie-aska', NULL,
    'Fucidine 2% pommade',
    'Stocked at Pharmacie Aska (in stock).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "7fb3c1e1-9bdb-4b1f-a0bd-7aac54e05742", "productCode": "N1-1788545549386471", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-diamicron-mr-60mg', 'phx-pharmacie-aska', NULL,
    'Diamicron MR 60mg',
    'Stocked at Pharmacie Aska (in stock).',
    1800.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "80318e34-edc7-454f-ba72-1d7f68322a4a", "productCode": "N1-1788545549991475", "stockQty": 14, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ery-500mg-comprim-s-20', 'phx-pharmacie-aska', NULL,
    'Ery 500mg comprimés 20',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "80c25552-2493-4c92-8418-7f38479a747d", "productCode": "N1-1788545549392456", "stockQty": 21, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-doliprane-1000mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Doliprane 1000mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8222d167-2065-4564-8a0b-6af4182f8f32", "productCode": "N1-1788545549989392", "stockQty": 6, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-vogal-ne-sirop-0-1', 'phx-pharmacie-aska', NULL,
    'Vogalène sirop 0,1%',
    'Stocked at Pharmacie Aska (in stock).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "845c6731-ad07-446c-aeaf-726888a2d4c7", "productCode": "N1-1788545549359546", "stockQty": 12, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-polygynax-ovules', 'phx-pharmacie-aska', NULL,
    'Polygynax ovules',
    'Stocked at Pharmacie Aska (in stock).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "89a32db3-c849-441f-9718-37bd8a8e1659", "productCode": "N1-1788545550327659", "stockQty": 6, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ciprofloxacine-500mg-comprim', 'phx-pharmacie-aska', NULL,
    'Ciprofloxacine 500mg comprimé',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8b017f6d-2ecf-4e76-b47d-9425bc00cb38", "productCode": "N1-1789317101900000", "barcode": "P0100000179", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-affinit-adulte', 'phx-pharmacie-aska', NULL,
    'Affinité adulte',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8db9094a-172d-4df1-af80-e326f638c068", "productCode": "N1-1788545550327007", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tardyferon-80mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Tardyferon 80mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    1250.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8df0c68c-73c1-4644-b1d6-641f006ac25e", "productCode": "N1-1788545549388485", "stockQty": 11, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-oxalair-125-microgrammes-120-doses', 'phx-pharmacie-aska', NULL,
    'Oxalair 125 microgrammes 120 doses',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8e032b65-7bb5-4366-83fa-b51e7dd45b03", "productCode": "N1-1788545550298620", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-norodol-5mg', 'phx-pharmacie-aska', NULL,
    'Norodol 5mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "8e5108bb-1ff2-4faa-acfd-e53ab9de0208", "productCode": "N1-1788545549996094", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-trialgic-comprim-s', 'phx-pharmacie-aska', NULL,
    'Trialgic comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    800.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9082fac9-0335-4745-8e12-e8e3ed3d3423", "productCode": "N1-1788545549384477", "stockQty": 27, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tamsulosine-viatris-0-4mg', 'phx-pharmacie-aska', NULL,
    'Tamsulosine Viatris 0,4mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "90fbf8b6-0f4e-4b39-aef4-11c2c3b68a11", "productCode": "N1-1788545549992844", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-alvityl-sirop-11-vitamines', 'phx-pharmacie-aska', NULL,
    'Alvityl sirop 11 vitamines',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9113014b-8ace-4d7b-8d5e-35d6f72a152d", "productCode": "N1-1788545549930519", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-astaph-sirop-250mg', 'phx-pharmacie-aska', NULL,
    'Astaph sirop 250mg',
    'Stocked at Pharmacie Aska (in stock).',
    1350.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9193d67f-98bb-4db4-9955-1590747b9c50", "productCode": "N1-1788547686235871", "barcode": "P0100000158", "stockQty": 6, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-omeprazole-injectable-40mg', 'phx-pharmacie-aska', NULL,
    'Omeprazole injectable 40mg',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "93b570d7-4dc2-42ea-b28d-ed2ea236fb59", "productCode": "N1-1789318130341000", "barcode": "P0100000181", "stockQty": 15, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-clotri-denk-1-cream-20g', 'phx-pharmacie-aska', NULL,
    'Clotri-denk 1% cream 20g',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "945b0cde-b90d-4f9a-9ddb-53f219828582", "productCode": "N1-1788545549990245", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nevixal-0-1', 'phx-pharmacie-aska', NULL,
    'Nevixal 0,1%',
    'Stocked at Pharmacie Aska (in stock).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "96c8181b-773b-4ffa-a3a6-50a1a6889284", "productCode": "N1-1788545550328236", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-acyclovir-200mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Acyclovir 200mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    2200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "96d85407-f877-4d6a-9dd0-211765dc6bbf", "productCode": "N1-1788545550300615", "stockQty": 4, "stockStatus": "instock", "lowStockThreshold": 2}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-apo-zopiclone-cp-500mg', 'phx-pharmacie-aska', NULL,
    'Apo-zopiclone CP 500mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "997340f9-2133-49ae-ae52-46604c114e2e", "productCode": "N1-1788545550318867", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-maxilase-sirop', 'phx-pharmacie-aska', NULL,
    'Maxilase sirop',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9ab94a97-8ad1-4218-8ef0-21c6da84705c", "productCode": "N1-1788545550324076", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tegretol-cp-200mg', 'phx-pharmacie-aska', NULL,
    'Tegretol CP 200mg',
    'Stocked at Pharmacie Aska (in stock).',
    1400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9b694855-0db6-499e-9277-6fe7df32be7e", "productCode": "N1-1788545550320862-1", "stockQty": 13, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-coveram-10-10mg', 'phx-pharmacie-aska', NULL,
    'Coveram 10/10mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2250.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9bf77517-bc52-4694-a932-0d85699ff8e6", "productCode": "N1-1788545549399484", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-rabirchamber-small', 'phx-pharmacie-aska', NULL,
    'Rabirchamber Small',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9e48f439-6de3-4222-8a61-90501c5025c0", "productCode": "N1-1788545550297663", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-astaph-sirop-125mg', 'phx-pharmacie-aska', NULL,
    'Astaph sirop 125mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "9f81e325-8afa-4af1-95ed-f3a9d44a45fa", "productCode": "N1-1788545549354558", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-doliprane-150mg-suppositoire-8-12kg', 'phx-pharmacie-aska', NULL,
    'Doliprane 150mg suppositoire 8-12kg',
    'Stocked at Pharmacie Aska (in stock).',
    650.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a0782ab3-98b3-4dc8-a825-0d786257570a", "productCode": "N1-1788545550280313", "stockQty": 9, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-h-licidine-sans-sucre-oral', 'phx-pharmacie-aska', NULL,
    'Hélicidine sans sucre oral',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1450.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a11ecabf-5110-41e8-9767-3ab9ab2da880", "productCode": "N1-1788545549345580-1", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-perfuseur', 'phx-pharmacie-aska', NULL,
    'Perfuseur',
    'Stocked at Pharmacie Aska (in stock).',
    100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a2227618-dd05-4a6e-9108-a34b937705c1", "productCode": "N1-1789316769785000", "barcode": "P0100000178", "stockQty": 12, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-otofa-rifamycine-auriculaire', 'phx-pharmacie-aska', NULL,
    'Otofa rifamycine auriculaire',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a30a1ddb-ad73-4fac-aea8-4c0a7c5cd6de", "productCode": "N1-1788545549968920", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nexium-40mg-comprimes', 'phx-pharmacie-aska', NULL,
    'nexium 40mg  comprimes',
    'Stocked at Pharmacie Aska (in stock).',
    1750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a6d94f05-895a-4bd0-985b-42fb09bd0d29", "productCode": "N1-1788627010182121", "barcode": "P0100000164", "stockQty": 11, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-dynamogen-ampoul-buvable-packet', 'phx-pharmacie-aska', NULL,
    'Dynamogen ampoul buvable packet',
    'Stocked at Pharmacie Aska (in stock).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a8add4dc-b815-42ab-929d-a1ce04dc7fa3", "productCode": "N1-1788550840062494", "barcode": "P0100000162", "stockQty": 4, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-atarax-25mg', 'phx-pharmacie-aska', NULL,
    'Atarax 25mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a9d7a3cc-15b7-459b-88ee-b142b9c0ba93", "productCode": "N1-1788545549369517-1", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-ofrivid-10ml-collyre', 'phx-pharmacie-aska', NULL,
    'Ofrivid 10ml collyre',
    'Stocked at Pharmacie Aska (in stock).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "a9dc7dab-d35e-4f9d-970e-dcefdf285f66", "productCode": "N1-1788545549993784", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-augmentin-enfant-sirop-100mg', 'phx-pharmacie-aska', NULL,
    'Augmentin enfant sirop 100mg',
    'Stocked at Pharmacie Aska (in stock).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "aa8a0d95-7869-4665-aeb0-be687f908b14", "productCode": "N1-1788545549349581", "stockQty": 11, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-cotareg-80-12-5mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Cotareg 80/12.5mg comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ab8c68b9-b176-48c5-82c5-dfeaca529329", "productCode": "N1-1788545549369517", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-doliprane-500mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Doliprane 500mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "acbf77e7-0bfd-4478-b58a-6e379f7207ae", "productCode": "N1-1788545549984220", "stockQty": 28, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-parogencyl-menthe-75ml', 'phx-pharmacie-aska', NULL,
    'Parogencyl menthe 75ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1150.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "adeb6328-a493-4233-987f-903826000b61", "productCode": "N1-1788545550290295", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-fervex-adultes-8-sachets', 'phx-pharmacie-aska', NULL,
    'Fervex adultes 8 sachets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ae7b18ed-2014-40cc-bce1-f54545550ab5", "productCode": "N1-1788545549979910", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-rl-sodium-500ml', 'phx-pharmacie-aska', NULL,
    'RL sodium 500ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "b1189167-a7f9-48d4-9fcb-bb28b0c92444", "productCode": "N1-1788545549998088-2", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-bemiks-ampoul-le', 'phx-pharmacie-aska', NULL,
    'Bemiks ampoul LE',
    'Stocked at Pharmacie Aska (in stock).',
    300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "b2909ad9-10c4-48af-87dd-2ba1a948aa9b", "productCode": "N1-1788678590797915", "barcode": "P0100000170", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-azithro-sirop-200mg-5ml', 'phx-pharmacie-aska', NULL,
    'Azithro sirop 200mg/5ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1000.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "b4b5b835-e038-41eb-9227-0187251e39fc", "productCode": "N1-1788545550317872", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-smecta-sachets', 'phx-pharmacie-aska', NULL,
    'Smecta sachets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ba01d56a-0e93-4064-917f-455c6e91cb64", "productCode": "N1-1788545550311930", "stockQty": 2, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-mag-2-comprim-s', 'phx-pharmacie-aska', NULL,
    'Mag 2 comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "baee3f7e-38cd-403a-b73f-f2fcc4a1aea0", "productCode": "N1-1788545549387468", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nuravit-sirop-125ml', 'phx-pharmacie-aska', NULL,
    'Nuravit sirop 125ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "bc0e89ee-05a5-42af-a5e4-73ac49c8eb62", "productCode": "N1-1788545549933512", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-flagyl-500mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Flagyl 500mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    1100.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "bdbfa3b1-ef0e-4aa5-a1b1-48904d2f9541", "productCode": "N1-1788545549962301", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-d-contractyl-m-ph-sine-comprim-s', 'phx-pharmacie-aska', NULL,
    'Décontractyl méphésine comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "bfdb54b1-ef15-46bb-af85-a91ac48b91e9", "productCode": "N1-1788545549365528", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-phenergan-sirop-adultes', 'phx-pharmacie-aska', NULL,
    'Phenergan sirop adultes',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "c163d79d-c9c3-49c7-9029-cd69f4d1a80e", "productCode": "N1-1788545550325761", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-insulin-glargine-3ml', 'phx-pharmacie-aska', NULL,
    'Insulin glargine 3ml',
    'Stocked at Pharmacie Aska (in stock).',
    600.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "c73f889d-874c-41ea-b6dd-6b2ff72616eb", "productCode": "N1-1788545550286308", "stockQty": 7, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-tributine-250ml-suspension-buvable', 'phx-pharmacie-aska', NULL,
    'Tributine 250ml suspension buvable',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "c76fc06e-76bb-42a0-a559-aa3300aeea87", "productCode": "N1-1788545549977258", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-parodontax-bain-de-bouche-500ml', 'phx-pharmacie-aska', NULL,
    'Parodontax bain de bouche 500ml',
    'Stocked at Pharmacie Aska (in stock).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "c9f2d4ee-870b-4320-b5a1-49064e71d3dd", "productCode": "N1-1788550248818768", "barcode": "P0100000161", "stockQty": 5, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-on-call-plus-bandelettes', 'phx-pharmacie-aska', NULL,
    'On Call Plus bandelettes',
    'Stocked at Pharmacie Aska (in stock).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ca675deb-8bc1-4790-b1de-d6f3254967e3", "productCode": "N1-1788545550313881", "stockQty": 12, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-difal-50mg-comprim', 'phx-pharmacie-aska', NULL,
    'Difal 50mg comprimé',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "cdcccbbc-0fa5-42f6-bb69-df03231c52ec", "productCode": "N1-1788545549368521", "stockQty": 10, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-voltaren-emulgel-1', 'phx-pharmacie-aska', NULL,
    'Voltaren Emulgel 1%',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "cef91e36-9821-45a4-972d-5fadaa6a827b", "productCode": "N1-1788545550326378", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-parac-tamol-infusion-100ml', 'phx-pharmacie-aska', NULL,
    'Paracétamol infusion 100ml',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "d03604e3-6e72-462e-a2b6-a4bfa31a82e4", "productCode": "N1-1788545549999085-3", "stockQty": 15, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-omeprazole-viatris-20mg', 'phx-pharmacie-aska', NULL,
    'Omeprazole Viatris 20mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1400.00, NULL, NULL, NULL, NULL,
    TRUE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Prescription"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "d33900f8-af92-4715-80c8-96ecdde9f4bd", "productCode": "N1-1788545549940366", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nexium-20mg-28-comprim-s', 'phx-pharmacie-aska', NULL,
    'Nexium 20mg 28 comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    1500.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "d34d6582-6847-488d-83e4-490ed4ed1da0", "productCode": "N1-1788545549937341", "stockQty": 12, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-duphalac-sirop-200ml', 'phx-pharmacie-aska', NULL,
    'Duphalac sirop 200ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    850.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "d4435392-3c23-454d-94e1-e43c13668ba6", "productCode": "N1-1788545549975573", "stockQty": 3, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-glucophage-500mg', 'phx-pharmacie-aska', NULL,
    'Glucophage 500mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "d6948457-3806-49f4-a846-383a094c1449", "productCode": "N1-1788545549989821", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-alvityl-12-vitamines-40-comprim-s', 'phx-pharmacie-aska', NULL,
    'Alvityl 12 vitamines 40 comprimés',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "dd5407fb-3dc7-4909-afcc-825fb0a581c1", "productCode": "N1-1788545549929475", "barcode": "P0100000039", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-prednisone-5mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Prednisone 5mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    800.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ddeddc06-472f-440f-8fa9-ee3ae2d68bd9", "productCode": "N1-1789315977153000", "barcode": "P0100000175", "stockQty": 5, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-mag-2-ampoule', 'phx-pharmacie-aska', NULL,
    'mag 2 ampoule',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1900.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "df82c8f6-a379-4e07-850a-f2bfd2cd4a14", "productCode": "N1-1789321403004000", "barcode": "P0100000184", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nozinan-25mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Nozinan 25mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "df988ebc-c0fd-45bc-9aa0-bcd372c49f15", "productCode": "N1-1788545549995097-1", "stockQty": 19, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-betastene-0-05-gouttes', 'phx-pharmacie-aska', NULL,
    'Betastene 0,05% gouttes',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "e16c1faf-03ce-4b7e-bdca-f62e745e56e2", "productCode": "N1-1788545550310895", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-nozinan-100mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Nozinan 100mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    2300.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "e4af2c3f-2a0c-46b2-9019-d12f751a3176", "productCode": "N1-1788545549995097-3", "stockQty": 13, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-betadine-dermique-125ml', 'phx-pharmacie-aska', NULL,
    'Betadine dermique 125ml',
    'Stocked at Pharmacie Aska (in stock).',
    750.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "e5099630-f199-441a-9951-108ced452158", "productCode": "N1-1788545550000084", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-oroken-sirop-100mg-5ml', 'phx-pharmacie-aska', NULL,
    'Oroken sirop 100mg/5ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    3000.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "e7a7183d-6aeb-4835-afcb-c41a4edd58be", "productCode": "N1-1788545550319869", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-janumet-50-1000mg', 'phx-pharmacie-aska', NULL,
    'Janumet 50/1000mg',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    2800.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "ed92014f-9110-4038-8e4a-fa6e655db178", "productCode": "N1-1788545549974286", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-parac-tamol-500mg-g-lules', 'phx-pharmacie-aska', NULL,
    'Paracétamol 500mg gélules',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    400.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f04c6302-911b-4ba4-a826-ac22734098c9", "productCode": "N1-1788545549985392", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-gpract-20mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'GPRact 20mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f09248dd-9087-439e-a462-355d667ba58a", "productCode": "N1-1788545550301633", "stockQty": 14, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pevaryl-cr-me-1', 'phx-pharmacie-aska', NULL,
    'Pevaryl crème 1%',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1200.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f10308e5-8565-4d8b-9dd0-f18251386099", "productCode": "N1-1788545550322082", "stockQty": 4, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-gaviscon-buvable-24-sachets', 'phx-pharmacie-aska', NULL,
    'Gaviscon buvable 24 sachets',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    1700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f18746b0-9366-4537-8e1a-0489ef7a58ad", "productCode": "N1-1788545549931472", "stockQty": 5, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pole-ecbu', 'phx-pharmacie-aska', NULL,
    'pole ECBU',
    'Stocked at Pharmacie Aska (in stock).',
    100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f33164cd-f2d6-4759-b084-90e68b0ac0a9", "productCode": "N1-1788545550001081-1", "stockQty": 26, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-efferalgan-sirop-3', 'phx-pharmacie-aska', NULL,
    'Efferalgan sirop 3%',
    'Stocked at Pharmacie Aska (in stock).',
    700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f7805607-4b87-4191-a37b-3d06e1a17dbe", "productCode": "N1-1788545549348572", "stockQty": 27, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-pantoprazole-20mg-comprim-s', 'phx-pharmacie-aska', NULL,
    'Pantoprazole 20mg comprimés',
    'Stocked at Pharmacie Aska (in stock).',
    1700.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "f98d1c82-2d2f-4db7-b783-df2ff1e99313", "productCode": "N1-1789315684449000", "barcode": "P0100000174", "stockQty": 3, "stockStatus": "instock", "lowStockThreshold": 0}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-gelphore-sirop-125ml', 'phx-pharmacie-aska', NULL,
    'Gelphore sirop 125ml',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "fa18629c-d881-43f5-abab-72604c19fa23", "productCode": "N1-1788545549987005", "stockQty": 1, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-dynamogen-ampoul-20-pcs-buval-3mg', 'phx-pharmacie-aska', NULL,
    'Dynamogen ampoul 20 pcs buval 3mg',
    'Stocked at Pharmacie Aska (in stock).',
    100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "faec0ed7-51d2-4abf-a032-c39075ca5380", "productCode": "N1-1788545549350578-1", "stockQty": 20, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-magn-sie-poudre', 'phx-pharmacie-aska', NULL,
    'Magnésie poudre',
    'Stocked at Pharmacie Aska (in stock).',
    1600.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "fbe40869-3f3e-432a-809d-33eb5ec7218f", "productCode": "N1-1788545550308897", "stockQty": 6, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-polygynax-capsule-vaginal', 'phx-pharmacie-aska', NULL,
    'Polygynax capsule vaginal',
    'Stocked at Pharmacie Aska (in stock).',
    5.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "fbe7bc36-04f2-4ddc-9583-0e950794a1d3", "productCode": "N1-1788545549992525", "stockQty": 8, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-broncathiol-sirop-enfant-2', 'phx-pharmacie-aska', NULL,
    'Broncathiol sirop enfant 2%',
    'Stocked at Pharmacie Aska (in stock).',
    1100.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, TRUE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "fc8b0e0c-19b4-46c2-bb43-5fcdd12f7c91", "productCode": "N1-1788545549340597", "stockQty": 11, "stockStatus": "instock", "lowStockThreshold": 5}'::jsonb,
    NOW()
  ),
  (
    'phx-aska-csv-zentel-sirop-0-4g', 'phx-pharmacie-aska', NULL,
    'Zentel sirop 0,4g',
    'Stocked at Pharmacie Aska (low stock / limited availability).',
    900.00, NULL, NULL, NULL, NULL,
    FALSE, 0, 0,
    '[]'::jsonb, '["Pharmacie Aska", "Ali Sabieh", "Over the counter"]'::jsonb, '[]'::jsonb,
    NULL, FALSE, '{"source": "pharmacie_aska_inventory_csv", "sourceBusiness": "Pharmacie Aska", "sourceRowId": "fed1fcbb-f98f-491d-bd0a-7f48686e2958", "productCode": "N1-1788545549367551", "stockQty": 0, "stockStatus": "low", "lowStockThreshold": 5}'::jsonb,
    NOW()
  )
ON CONFLICT ("id") DO UPDATE SET
  "pharmacyId"           = EXCLUDED."pharmacyId",
  "categoryId"           = EXCLUDED."categoryId",
  "name"                 = EXCLUDED."name",
  "description"          = EXCLUDED."description",
  "price"                = EXCLUDED."price",
  "requiresPrescription" = EXCLUDED."requiresPrescription",
  "imageUrlsJson"        = EXCLUDED."imageUrlsJson",
  "tagsJson"             = EXCLUDED."tagsJson",
  "featuresJson"         = EXCLUDED."featuresJson",
  "inStock"              = EXCLUDED."inStock",
  "metadata"             = EXCLUDED."metadata",
  "updatedAt"            = NOW();

-- Clear any category guesses from an earlier run of this script:
UPDATE "Medicine"
SET "categoryId" = NULL, "updatedAt" = NOW()
WHERE "pharmacyId" = 'phx-pharmacie-aska'
  AND "metadata"->>'source' = 'pharmacie_aska_inventory_csv';

-- ── Verify ──────────────────────────────────────────────────
SELECT
  COUNT(*)                                                            AS total_imported,
  COUNT(*) FILTER (WHERE "inStock")                                   AS in_stock,
  COUNT(*) FILTER (WHERE "requiresPrescription")                      AS rx_only,
  COUNT(*) FILTER (WHERE "price" = 5.00)                              AS placeholder_price
FROM "Medicine"
WHERE "pharmacyId" = 'phx-pharmacie-aska'
  AND "metadata"->>'source' = 'pharmacie_aska_inventory_csv';

-- Items still missing a price (review these):
SELECT "name", "price", "metadata"->>'stockQty' AS qty
FROM "Medicine"
WHERE "pharmacyId" = 'phx-pharmacie-aska'
  AND "metadata"->>'source' = 'pharmacie_aska_inventory_csv'
  AND "price" = 5.00
ORDER BY "name";
