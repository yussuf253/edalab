import { randomUUID } from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { Request, Router } from 'express';
import { z } from 'zod';

import { env } from '../config/env';
import { asyncHandler } from '../utils/async-handler';

const router = Router();

const uploadScopeSchema = z.enum([
  'user_avatar',
  'pro_avatar',
  'store',
  'product',
  'provider',
  'doctor',
  'restaurant',
  'prescription',
  'generic',
]);

const uploadMediaSchema = z.object({
  scope: uploadScopeSchema,
  ownerId: z.string().trim().min(1).max(120).optional().nullable(),
  fileName: z.string().trim().min(1).max(180).optional().nullable(),
  mimeType: z.string().trim().max(120).optional().nullable(),
  dataBase64: z.string().min(24),
});

function fileExtensionFromMimeType(mimeType: string | null | undefined) {
  const normalized = mimeType?.trim().toLowerCase();
  switch (normalized) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    case 'image/heif':
      return 'heif';
    case 'image/avif':
      return 'avif';
    default:
      return null;
  }
}

function fileExtensionFromName(fileName: string | null | undefined) {
  const extension = path
    .extname(fileName?.trim() ?? '')
    .replace('.', '')
    .toLowerCase();
  return extension.length > 0 ? extension : null;
}

function decodedBase64Payload(dataBase64: string) {
  const payload = dataBase64.trim();
  const base64Data = payload.includes(',')
    ? payload.substring(payload.indexOf(',') + 1)
    : payload;
  return Buffer.from(base64Data, 'base64');
}

function sanitizedBaseFileName(name: string | null | undefined) {
  const trimmed = name?.trim();
  if (!trimmed) return null;
  const safe = trimmed
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return safe.length > 0 ? safe : null;
}

function sanitizePathSegment(value: string | null | undefined, fallback: string) {
  const trimmed = value?.trim();
  if (!trimmed) return fallback;
  const safe = trimmed
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return safe.length > 0 ? safe : fallback;
}

function bucketForScope(scope: z.infer<typeof uploadScopeSchema>) {
  if (scope === 'user_avatar' || scope === 'pro_avatar') {
    return env.SUPABASE_STORAGE_BUCKET_AVATARS.trim() || 'avatars';
  }
  if (scope === 'prescription') {
    return env.SUPABASE_STORAGE_BUCKET_PRESCRIPTIONS.trim() || 'prescriptions';
  }
  return env.SUPABASE_STORAGE_BUCKET_MEDIA.trim() || 'media';
}

function objectPrefixForScope(
  scope: z.infer<typeof uploadScopeSchema>,
  ownerSegment: string,
) {
  switch (scope) {
    case 'user_avatar':
      return `users/${ownerSegment}/avatars`;
    case 'pro_avatar':
      return `pros/${ownerSegment}/avatars`;
    case 'store':
      return `stores/${ownerSegment}`;
    case 'product':
      return `products/${ownerSegment}`;
    case 'provider':
      return `providers/${ownerSegment}`;
    case 'doctor':
      return `doctors/${ownerSegment}`;
    case 'restaurant':
      return `restaurants/${ownerSegment}`;
    case 'prescription':
      return `pharmacy/${ownerSegment}`;
    case 'generic':
      return `generic/${ownerSegment}`;
  }
}

function buildPublicUrl(req: Request, relativePath: string) {
  const configuredPublicBase = env.PUBLIC_BASE_URL?.trim();
  if (configuredPublicBase) {
    return `${configuredPublicBase.replace(/\/+$/g, '')}${relativePath}`;
  }

  const forwardedProto = req
    .get('x-forwarded-proto')
    ?.split(',')[0]
    ?.trim();
  const forwardedHost = req
    .get('x-forwarded-host')
    ?.split(',')[0]
    ?.trim();
  const host = forwardedHost || req.get('host');
  const protocol = (forwardedProto || req.protocol || 'https')
    .trim()
    .toLowerCase();

  if (!host) return relativePath;
  return `${protocol}://${host}${relativePath}`;
}

async function uploadToSupabaseStorage(params: {
  bucket: string;
  objectPath: string;
  mimeType: string | null | undefined;
  buffer: Buffer;
}) {
  const supabaseUrl = env.SUPABASE_URL?.trim();
  const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!supabaseUrl || !serviceRoleKey) return false;

  const encodedObjectPath = params.objectPath
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');
  const uploadUrl =
    `${supabaseUrl.replace(/\/+$/g, '')}/storage/v1/object/${encodeURIComponent(params.bucket)}/${encodedObjectPath}`;

  const response = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      apikey: serviceRoleKey,
      'Content-Type': params.mimeType?.trim() || 'application/octet-stream',
      'x-upsert': 'true',
    },
    body: new Uint8Array(params.buffer),
  });

  if (!response.ok) {
    const rawBody = await response.text().catch(() => '');
    throw new Error(
      `Supabase media upload failed (${response.status}): ${rawBody.slice(0, 300)}`,
    );
  }

  return true;
}

router.post(
  '/upload',
  asyncHandler(async (req, res) => {
    const body = uploadMediaSchema.parse(req.body);
    const fileBuffer = decodedBase64Payload(body.dataBase64);
    if (!fileBuffer || fileBuffer.length === 0) {
      return res.status(400).json({ error: 'Invalid image payload.' });
    }
    if (fileBuffer.length > 20 * 1024 * 1024) {
      return res
        .status(413)
        .json({ error: 'Image is too large. Max size is 20MB.' });
    }

    const extFromMime = fileExtensionFromMimeType(body.mimeType);
    const extFromName = fileExtensionFromName(body.fileName);
    const extension = (extFromMime || extFromName || 'jpg').replace(
      /[^a-z0-9]/gi,
      '',
    ) || 'jpg';
    const baseName = sanitizedBaseFileName(body.fileName) ?? randomUUID();
    const fileName = `${baseName}-${Date.now()}.${extension}`;

    const ownerSegment = sanitizePathSegment(body.ownerId, 'unscoped');
    const bucket = bucketForScope(body.scope);
    const objectPrefix = objectPrefixForScope(body.scope, ownerSegment);
    const objectPath = `${objectPrefix}/${fileName}`;

    let publicUrl: string;
    let storedPath: string;
    try {
      const uploaded = await uploadToSupabaseStorage({
        bucket,
        objectPath,
        mimeType: body.mimeType,
        buffer: fileBuffer,
      });

      if (uploaded) {
        const encodedObjectPath = objectPath
          .split('/')
          .map((segment) => encodeURIComponent(segment))
          .join('/');
        publicUrl = buildPublicUrl(
          req,
          `/uploads/supabase/${encodeURIComponent(bucket)}/${encodedObjectPath}`,
        );
        storedPath = `supabase://${bucket}/${objectPath}`;
      } else {
        const absolutePath = path.resolve(
          process.cwd(),
          'uploads',
          bucket,
          ...objectPath.split('/'),
        );
        await fs.mkdir(path.dirname(absolutePath), { recursive: true });
        await fs.writeFile(absolutePath, fileBuffer);
        storedPath = `/uploads/${bucket}/${objectPath}`;
        publicUrl = buildPublicUrl(req, storedPath);
      }
    } catch (error) {
      console.error('[MEDIA_UPLOAD] Failed to upload image.', error);
      return res.status(503).json({
        error:
          'Image upload is temporarily unavailable. Please try again shortly.',
      });
    }

    res.status(201).json({
      scope: body.scope,
      bucket,
      fileName,
      objectPath,
      path: storedPath,
      url: publicUrl,
      mimeType: body.mimeType ?? null,
      sizeBytes: fileBuffer.length,
      uploadedAt: new Date().toISOString(),
    });
  }),
);

export default router;
