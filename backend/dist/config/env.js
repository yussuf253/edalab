"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const zod_1 = require("zod");
dotenv_1.default.config();
const envSchema = zod_1.z.object({
    NODE_ENV: zod_1.z.enum(['development', 'test', 'production']).default('development'),
    PORT: zod_1.z.coerce.number().default(5050),
    DATABASE_URL: zod_1.z.string().min(1, 'DATABASE_URL is required'),
    JWT_SECRET: zod_1.z.string().min(16, 'JWT_SECRET must be at least 16 characters'),
    JWT_EXPIRES_IN: zod_1.z.string().default('7d'),
    CORS_ORIGIN: zod_1.z.string().default('*'),
    PUBLIC_BASE_URL: zod_1.z.string().optional(),
    SUPABASE_URL: zod_1.z.string().optional(),
    SUPABASE_SERVICE_ROLE_KEY: zod_1.z.string().optional(),
    SUPABASE_STORAGE_BUCKET_AVATARS: zod_1.z.string().default('avatars'),
    SUPABASE_STORAGE_BUCKET_PRESCRIPTIONS: zod_1.z.string().default('prescriptions'),
    SUPABASE_STORAGE_BUCKET_MEDIA: zod_1.z.string().default('media'),
    FIREBASE_PROJECT_ID: zod_1.z.string().optional(),
    FIREBASE_CLIENT_EMAIL: zod_1.z.string().optional(),
    FIREBASE_PRIVATE_KEY: zod_1.z.string().optional(),
    FIREBASE_SERVICE_ACCOUNT_JSON: zod_1.z.string().optional(),
    WAAFIPAY_STORE_ID: zod_1.z.string().optional(),
    WAAFIPAY_HPP_KEY: zod_1.z.string().optional(),
    WAAFIPAY_MERCHANT_UID: zod_1.z.string().optional(),
    WAAFIPAY_PRODUCTION: zod_1.z.coerce.boolean().default(true),
    WAAFIPAY_CALLBACK_HTML_REDIRECT: zod_1.z.coerce.boolean().default(false),
    DEEP_LINK_URL: zod_1.z.string().optional(),
});
exports.env = envSchema.parse(process.env);
