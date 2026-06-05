-- Seed script for car rental products
-- Insert sample cars into the `product` table used by the application.
-- Adjust schema names or column types if your `product` table differs.

INSERT INTO "Product" ("id", "moduleType", "name", "brand", "description", "price", "unit", "badge", "imageUrlsJson", "featuresJson", "tagsJson", "inStock", "metadata", "createdAt", "updatedAt") VALUES
('car-001', 'RIDE', 'Toyota Yaris', 'Economy', '2022 Toyota Yaris – fuel-efficient city car, perfect for daily errands or short trips around Djibouti City.', 6500, 'per day', 'Best Value', '["https://example.com/images/car-001-1.jpg"]', '["AC","Bluetooth","USB Charging","Backup Camera"]', '["Economy"]', true, '{"rentalCar": true, "type":"Economy", "seats":5, "transmission":"Automatic", "fuelType":"Petrol", "year":2022, "mileage":"Unlimited"}', now(), now())
ON CONFLICT ("id") DO UPDATE SET "name" = EXCLUDED."name";

INSERT INTO "Product" ("id", "moduleType", "name", "brand", "description", "price", "unit", "badge", "imageUrlsJson", "featuresJson", "tagsJson", "inStock", "metadata", "createdAt", "updatedAt") VALUES
('car-002', 'RIDE', 'Hyundai Tucson', 'SUV', '2023 Hyundai Tucson – spacious SUV with premium features. Great for families or longer journeys.', 12000, 'per day', 'Popular', '["https://example.com/images/car-002-1.jpg"]', '["AC","Sunroof","Bluetooth","GPS","Leather Seats"]', '["SUV"]', true, '{"rentalCar": true, "type":"SUV", "seats":5, "transmission":"Automatic", "fuelType":"Diesel", "year":2023, "mileage":"Unlimited"}', now(), now())
ON CONFLICT ("id") DO UPDATE SET "name" = EXCLUDED."name";

INSERT INTO "Product" ("id", "moduleType", "name", "brand", "description", "price", "unit", "badge", "imageUrlsJson", "featuresJson", "tagsJson", "inStock", "metadata", "createdAt", "updatedAt") VALUES
('car-003', 'RIDE', 'Toyota Hiace', 'Van', '2021 Toyota Hiace – 12-seat van for group travel, airport transfers, or cargo needs.', 18000, 'per day', NULL, '["https://example.com/images/car-003-1.jpg"]', '["AC","Large Cargo Space","Multiple Seats"]', '["Van"]', true, '{"rentalCar": true, "type":"Van", "seats":12, "transmission":"Manual", "fuelType":"Diesel", "year":2021, "mileage":"Unlimited"}', now(), now())
ON CONFLICT ("id") DO UPDATE SET "name" = EXCLUDED."name";

INSERT INTO "Product" ("id", "moduleType", "name", "brand", "description", "price", "unit", "badge", "imageUrlsJson", "featuresJson", "tagsJson", "inStock", "metadata", "createdAt", "updatedAt") VALUES
('car-004', 'RIDE', 'Toyota Land Cruiser', 'SUV', '2022 Toyota Land Cruiser – premium 4x4 for off-road adventures or executive transfers.', 25000, 'per day', 'Premium', '["https://example.com/images/car-004-1.jpg"]', '["AC","4WD","GPS","Leather Seats","Sunroof","Bluetooth"]', '["SUV"]', true, '{"rentalCar": true, "type":"SUV", "seats":7, "transmission":"Automatic", "fuelType":"Diesel", "year":2022, "mileage":"Unlimited"}', now(), now())
ON CONFLICT ("id") DO UPDATE SET "name" = EXCLUDED."name";

-- Note: Adjust the table name or JSON column handling for your Supabase/Postgres schema.
-- If your product table uses snake_case or different column names, update them accordingly.
