"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
const promises_1 = __importDefault(require("fs/promises"));
const path_1 = __importDefault(require("path"));
const env_1 = require("./config/env");
const routes_1 = __importDefault(require("./routes"));
const error_handler_1 = require("./middleware/error-handler");
const app = (0, express_1.default)();
app.set('trust proxy', 1);
app.use((req, res, next) => {
    const startedAt = Date.now();
    console.log(`[API] ${req.method} ${req.originalUrl}`);
    res.on('finish', () => {
        const durationMs = Date.now() - startedAt;
        console.log(`[API] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${durationMs}ms)`);
    });
    next();
});
app.use((0, cors_1.default)({
    origin: env_1.env.CORS_ORIGIN === '*' ? true : env_1.env.CORS_ORIGIN,
    credentials: true,
}));
app.use(express_1.default.json({ limit: '8mb' }));
app.get('/uploads/avatars/supabase/:userId/:fileName', async (req, res) => {
    const userId = (req.params.userId || '').trim();
    const fileName = (req.params.fileName || '').trim();
    const isSafeUserId = /^[a-zA-Z0-9-]+$/.test(userId);
    const isSafeFileName = /^[a-zA-Z0-9._-]+$/.test(fileName);
    if (!isSafeUserId || !isSafeFileName) {
        return res.status(400).end();
    }
    const supabaseUrl = env_1.env.SUPABASE_URL?.trim();
    const serviceRoleKey = env_1.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
    if (!supabaseUrl || !serviceRoleKey) {
        return res.status(404).end();
    }
    const bucket = env_1.env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars';
    const objectPath = `users/${userId}/${fileName}`;
    const encodedObjectPath = objectPath
        .split('/')
        .map((segment) => encodeURIComponent(segment))
        .join('/');
    const objectUrl = `${supabaseUrl.replace(/\/+$/g, '')}/storage/v1/object/${encodeURIComponent(bucket)}/${encodedObjectPath}`;
    try {
        const response = await fetch(objectUrl, {
            method: 'GET',
            headers: {
                Authorization: `Bearer ${serviceRoleKey}`,
                apikey: serviceRoleKey,
            },
        });
        if (!response.ok) {
            throw new Error(`Supabase avatar fetch failed with ${response.status}`);
        }
        const imageBytes = Buffer.from(await response.arrayBuffer());
        const contentType = response.headers.get('content-type') || 'application/octet-stream';
        res.setHeader('Content-Type', contentType);
        res.setHeader('Cache-Control', 'public, max-age=3600');
        return res.status(200).send(imageBytes);
    }
    catch (_) {
        const fallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220"><rect width="220" height="220" rx="44" fill="#E8F1FF"/><circle cx="110" cy="92" r="34" fill="#7AA3E8"/><path d="M44 193c12-33 38-54 66-54s54 21 66 54" fill="#7AA3E8"/></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
        res.setHeader('Cache-Control', 'public, max-age=3600');
        return res.status(200).send(fallbackSvg);
    }
});
app.get('/uploads/avatars/:fileName', async (req, res, next) => {
    const fileName = (req.params.fileName || '').trim();
    if (!fileName) {
        return next();
    }
    const avatarsDir = path_1.default.resolve(process.cwd(), 'uploads', 'avatars');
    const requestedPath = path_1.default.resolve(avatarsDir, fileName);
    if (!requestedPath.startsWith(avatarsDir)) {
        return res.status(400).end();
    }
    try {
        await promises_1.default.access(requestedPath);
        return res.sendFile(requestedPath);
    }
    catch (_) {
        const fallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220"><rect width="220" height="220" rx="44" fill="#E8F1FF"/><circle cx="110" cy="92" r="34" fill="#7AA3E8"/><path d="M44 193c12-33 38-54 66-54s54 21 66 54" fill="#7AA3E8"/></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
        res.setHeader('Cache-Control', 'public, max-age=3600');
        return res.status(200).send(fallbackSvg);
    }
});
app.use('/uploads', express_1.default.static(path_1.default.resolve(process.cwd(), 'uploads'), {
    maxAge: '7d',
}));
app.use('/api', routes_1.default);
app.use(error_handler_1.notFoundHandler);
app.use(error_handler_1.errorHandler);
app.listen(env_1.env.PORT, '0.0.0.0', () => {
    console.log(`EdaLab API running on http://0.0.0.0:${env_1.env.PORT}`);
});
process.on('unhandledRejection', (reason) => {
    console.error('[UNHANDLED REJECTION]', reason);
});
process.on('uncaughtException', (error) => {
    console.error('[UNCAUGHT EXCEPTION]', error);
});
