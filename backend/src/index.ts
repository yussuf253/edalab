  import cors from 'cors';
import express from 'express';
import fs from 'fs/promises';
import path from 'path';
import { env } from './config/env';
import apiRoutes from './routes';
import versionRouter from './routes/version.routes';
import { errorHandler, notFoundHandler } from './middleware/error-handler';
import http from 'http';
const app = express();
app.set('trust proxy', 1);
const avatarFallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220"><rect width="220" height="220" rx="44" fill="#E8F1FF"/><circle cx="110" cy="92" r="34" fill="#7AA3E8"/><path d="M44 193c12-33 38-54 66-54s54 21 66 54" fill="#7AA3E8"/></svg>`;

app.use(express.json());

// 👉 Mount the router with the correct prefix
// If your Flutter client uses baseUrl = https://your‑api.com/api
// then mount under '/api/version'
// app.use('/api/version', versionRouter);   // <-- removed duplicate mounting (handled later)

// Optional: health check
app.get('/api/health', (_, res) => res.send('OK'));

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));

app.use((req, res, next) => {
  const startedAt = Date.now();
  console.log(`[API] ${req.method} ${req.originalUrl}`);

  res.on('finish', () => {
    const durationMs = Date.now() - startedAt;
    console.log(
      `[API] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${durationMs}ms)`,
    );
  });

  next();
});

app.use(
  cors({
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN,
    credentials: true,
  }),
);
app.use(express.json({ limit: '50mb' }));
app.get('/uploads/supabase/:bucket/*', async (req, res) => {
  const bucket = (req.params.bucket || '').trim();
  const params = req.params as unknown as Record<
    string,
    string | string[] | undefined
  >;
  const wildcardRaw = params['0'];
  const wildcardParam = Array.isArray(wildcardRaw)
    ? (wildcardRaw[0] || '')
    : (wildcardRaw || '');
  const rawObjectPath = wildcardParam.trim();
  if (!bucket || !rawObjectPath) {
    return res.status(400).end();
  }
  if (!/^[a-z0-9_-]+$/i.test(bucket)) {
    return res.status(400).end();
  }

  const allowedBuckets = new Set([
    env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars',
    env.SUPABASE_STORAGE_BUCKET_PRESCRIPTIONS.trim() || 'prescriptions',
    env.SUPABASE_STORAGE_BUCKET_MEDIA.trim() || 'media',
  ]);
  if (!allowedBuckets.has(bucket)) {
    return res.status(404).end();
  }

  const objectPath = rawObjectPath.replace(/^\/+/g, '');
  const safeSegments = objectPath.split('/').filter((segment: string) => {
    return segment.length > 0 && /^[a-z0-9._-]+$/i.test(segment);
  });
  if (safeSegments.length === 0 || safeSegments.join('/') !== objectPath) {
    return res.status(400).end();
  }

  const supabaseUrl = env.SUPABASE_URL?.trim();
  const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    if (bucket === (env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars')) {
      res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      return res.status(200).send(avatarFallbackSvg);
    }
    return res.status(404).end();
  }

  const encodedObjectPath = safeSegments
    .map((segment: string) => encodeURIComponent(segment))
    .join('/');
  const objectUrl =
    `${supabaseUrl.replace(/\/+$/g, '')}/storage/v1/object/${encodeURIComponent(bucket)}/${encodedObjectPath}`;

  try {
    const response = await fetch(objectUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
      },
    });

    if (!response.ok) {
      throw new Error(`Supabase media fetch failed with ${response.status}`);
    }

    const bytes = Buffer.from(await response.arrayBuffer());
    const contentType =
      response.headers.get('content-type') || 'application/octet-stream';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.status(200).send(bytes);
  } catch (_) {
    if (bucket === (env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars')) {
      res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      return res.status(200).send(avatarFallbackSvg);
    }
    return res.status(404).end();
  }
});
app.get('/uploads/avatars/supabase/:userId/:fileName', async (req, res) => {
  const userId = (req.params.userId || '').trim();
  const fileName = (req.params.fileName || '').trim();
  if (!/^[a-z0-9-]+$/i.test(userId) || !/^[a-z0-9._-]+$/i.test(fileName)) {
    return res.status(400).end();
  }
  const bucket = env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars';
  return res.redirect(
    302,
    `/uploads/supabase/${encodeURIComponent(bucket)}/users/${encodeURIComponent(userId)}/${encodeURIComponent(fileName)}`,
  );
});
app.get('/uploads/avatars/:fileName', async (req, res, next) => {
  const fileName = (req.params.fileName || '').trim();
  if (!fileName) {
    return next();
  }

  const avatarsDir = path.resolve(process.cwd(), 'uploads', 'avatars');
  const requestedPath = path.resolve(avatarsDir, fileName);
  if (!requestedPath.startsWith(avatarsDir)) {
    return res.status(400).end();
  }

  try {
    await fs.access(requestedPath);
    return res.sendFile(requestedPath);
  } catch (_) {
    res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.status(200).send(avatarFallbackSvg);
  }
});
app.use(
  '/uploads',
  express.static(path.resolve(process.cwd(), 'uploads'), {
    maxAge: '7d',
  }),
);

// Mount version routes under '/api/version'
app.use('/api/version', versionRouter);
// Mount other API routes under '/api'
app.use('/api', apiRoutes);
app.use(notFoundHandler);
app.use(errorHandler);

const server = http.createServer(app);

// Start the server
server.listen(env.PORT, '0.0.0.0', () => {
  console.log(`EdaLab API running on http://0.0.0.0:${env.PORT}`);
});

process.on('unhandledRejection', (reason) => {
  console.error('[UNHANDLED REJECTION]', reason);
});

process.on('uncaughtException', (error) => {
  console.error('[UNCAUGHT EXCEPTION]', error);
});

