import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/media/upload` — the backend used its service-role key to write into
/// Supabase Storage. In direct mode the app writes the object itself with its
/// own session, so the bucket's storage policy is what authorizes it.
void register() {
  GatewayRouter.post('/media/upload', _upload);
}

const List<String> _scopes = [
  'user_avatar',
  'pro_avatar',
  'store',
  'product',
  'provider',
  'doctor',
  'restaurant',
  'prescription',
  'generic',
];

const int _maxBytes = 20 * 1024 * 1024;

String _bucketForScope(String scope) {
  if (scope == 'user_avatar' || scope == 'pro_avatar') return 'avatars';
  if (scope == 'prescription') return 'prescriptions';
  return 'media';
}

String _objectPrefix(String scope, String owner) {
  switch (scope) {
    case 'user_avatar':
      return 'users/$owner/avatars';
    case 'pro_avatar':
      return 'pros/$owner/avatars';
    case 'store':
      return 'stores/$owner';
    case 'product':
      return 'products/$owner';
    case 'provider':
      return 'providers/$owner';
    case 'doctor':
      return 'doctors/$owner';
    case 'restaurant':
      return 'restaurants/$owner';
    case 'prescription':
      return 'pharmacy/$owner';
    default:
      return 'generic/$owner';
  }
}

String? _extensionFromMime(String? mimeType) {
  switch (mimeType?.trim().toLowerCase()) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
    case 'image/heif':
      return 'heic';
    case 'image/avif':
      return 'avif';
    default:
      return null;
  }
}

String? _extensionFromName(String? fileName) {
  final trimmed = fileName?.trim() ?? '';
  final dot = trimmed.lastIndexOf('.');
  if (dot < 0 || dot == trimmed.length - 1) return null;
  final extension = trimmed.substring(dot + 1).toLowerCase();
  return extension.isEmpty ? null : extension;
}

/// Collapses a mime/name derived extension to the backend's `[a-z0-9]` rule,
/// defaulting to `jpg` exactly like `media.routes.ts` did.
String _normalizeExtension(String? raw) {
  final cleaned = (raw ?? '').replaceAll(RegExp(r'[^a-z0-9]'), '');
  return cleaned.isEmpty ? 'jpg' : cleaned;
}

String? _safeBaseName(String? fileName) {
  final trimmed = fileName?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  var safe = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (safe.isEmpty) return null;
  return safe.length > 180 ? safe.substring(0, 180) : safe;
}

String _safeSegment(String value, String fallback) {
  var safe = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return safe.isEmpty ? fallback : safe;
}

Uint8List _decodeBase64(String raw) {
  final payload = raw.trim();
  final comma = payload.indexOf(',');
  final data = comma >= 0 ? payload.substring(comma + 1) : payload;
  return base64Decode(data);
}

Future<dynamic> _upload(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};
  final scope = body['scope']?.toString().trim() ?? '';
  if (!_scopes.contains(scope)) {
    throw const GatewayError('Unsupported upload scope.');
  }

  final raw = body['dataBase64']?.toString();
  if (raw == null || raw.length < 24) {
    throw const GatewayError('Invalid image payload.');
  }

  late Uint8List bytes;
  try {
    bytes = _decodeBase64(raw);
  } catch (_) {
    throw const GatewayError('Invalid image payload.');
  }
  if (bytes.isEmpty) throw const GatewayError('Invalid image payload.');
  if (bytes.length > _maxBytes) {
    throw const GatewayError('Image is too large. Max size is 20MB.', status: 413);
  }

  final mimeType = body['mimeType']?.toString().trim();
  final fileName = body['fileName']?.toString().trim();

  final extension = _normalizeExtension(
    _extensionFromMime(mimeType) ?? _extensionFromName(fileName),
  );

  final baseName = _safeBaseName(fileName) ??
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final objectFileName = '$baseName-$stamp.$extension';

  final ownerSegment = _safeSegment(body['ownerId']?.toString() ?? '', 'unscoped');
  final bucket = _bucketForScope(scope);
  final objectPath = '${_objectPrefix(scope, ownerSegment)}/$objectFileName';

  try {
    await SupabaseGateway.client.storage.from(bucket).uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        contentType: mimeType ?? 'image/jpeg',
        upsert: false,
      ),
    );
  } on StorageException catch (error) {
    final message = error.message.trim();
    if (message.toLowerCase().contains('row-level security')) {
      throw GatewayError(
        'You do not have permission to upload here.',
        status: 403,
      );
    }
    throw GatewayError(
      message.isEmpty
          ? 'Image upload is temporarily unavailable. Please try again shortly.'
          : message,
      status: 503,
    );
  }

  final publicUrl = SupabaseGateway.client.storage
      .from(bucket)
      .getPublicUrl(objectPath);

  return <String, dynamic>{
    'scope': scope,
    'bucket': bucket,
    'fileName': objectFileName,
    'objectPath': objectPath,
    'path': 'supabase://$bucket/$objectPath',
    'url': publicUrl,
    'mimeType': mimeType,
    'sizeBytes': bytes.length,
    'uploadedAt': DateTime.now().toUtc().toIso8601String(),
  };
}

