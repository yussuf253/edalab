import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(5050),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  CORS_ORIGIN: z.string().default('*'),
  PUBLIC_BASE_URL: z.string().optional(),
  SUPABASE_URL: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_STORAGE_BUCKET_AVATARS: z.string().default('avatars'),
  SUPABASE_STORAGE_BUCKET_PRESCRIPTIONS: z.string().default('prescriptions'),
  SUPABASE_STORAGE_BUCKET_MEDIA: z.string().default('media'),
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional(),
  WAAFIPAY_STORE_ID: z.string().optional(),
  WAAFIPAY_HPP_KEY: z.string().optional(),
  WAAFIPAY_MERCHANT_UID: z.string().optional(),
  WAAFIPAY_PRODUCTION: z.coerce.boolean().default(true),
  WAAFIPAY_CALLBACK_HTML_REDIRECT: z.coerce.boolean().default(false),
});

export const env = envSchema.parse(process.env);
