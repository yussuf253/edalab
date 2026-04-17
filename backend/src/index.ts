import cors from 'cors';
import express from 'express';
import fs from 'fs/promises';
import path from 'path';
import { env } from './config/env';
import apiRoutes from './routes';
import { errorHandler, notFoundHandler } from './middleware/error-handler';

const app = express();
app.set('trust proxy', 1);

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
app.use(express.json({ limit: '8mb' }));
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
    const fallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220"><rect width="220" height="220" rx="44" fill="#E8F1FF"/><circle cx="110" cy="92" r="34" fill="#7AA3E8"/><path d="M44 193c12-33 38-54 66-54s54 21 66 54" fill="#7AA3E8"/></svg>`;
    res.setHeader('Content-Type', 'image/svg+xml; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.status(200).send(fallbackSvg);
  }
});
app.use(
  '/uploads',
  express.static(path.resolve(process.cwd(), 'uploads'), {
    maxAge: '7d',
  }),
);

app.use('/api', apiRoutes);
app.use(notFoundHandler);
app.use(errorHandler);

app.listen(env.PORT, '0.0.0.0', () => {
  console.log(`EdaLab API running on http://0.0.0.0:${env.PORT}`);
});

process.on('unhandledRejection', (reason) => {
  console.error('[UNHANDLED REJECTION]', reason);
});

process.on('uncaughtException', (error) => {
  console.error('[UNCAUGHT EXCEPTION]', error);
});
