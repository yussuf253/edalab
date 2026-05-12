import 'dart:convert';
import 'dart:typed_data';

import '../network/api_client.dart';

enum MediaUploadScope {
  userAvatar,
  proAvatar,
  store,
  product,
  provider,
  doctor,
  restaurant,
  prescription,
  generic,
}

extension on MediaUploadScope {
  String get apiValue {
    switch (this) {
      case MediaUploadScope.userAvatar:
        return 'user_avatar';
      case MediaUploadScope.proAvatar:
        return 'pro_avatar';
      case MediaUploadScope.store:
        return 'store';
      case MediaUploadScope.product:
        return 'product';
      case MediaUploadScope.provider:
        return 'provider';
      case MediaUploadScope.doctor:
        return 'doctor';
      case MediaUploadScope.restaurant:
        return 'restaurant';
      case MediaUploadScope.prescription:
        return 'prescription';
      case MediaUploadScope.generic:
        return 'generic';
    }
  }
}

class UploadedMedia {
  const UploadedMedia({
    required this.url,
    this.path,
    this.fileName,
    this.bucket,
    this.objectPath,
  });

  final String url;
  final String? path;
  final String? fileName;
  final String? bucket;
  final String? objectPath;
}

class MediaUploadService {
  static Future<UploadedMedia> uploadImage({
    required MediaUploadScope scope,
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
    String? ownerId,
  }) async {
    final payload = <String, dynamic>{
      'scope': scope.apiValue,
      'dataBase64': base64Encode(bytes),
      if (fileName != null && fileName.trim().isNotEmpty) 'fileName': fileName,
      if (mimeType != null && mimeType.trim().isNotEmpty) 'mimeType': mimeType,
      if (ownerId != null && ownerId.trim().isNotEmpty) 'ownerId': ownerId,
    };

    final response = Map<String, dynamic>.from(
      await ApiClient.post('/media/upload', payload) as Map,
    );

    final uploadedUrl = response['url']?.toString().trim() ?? '';
    final normalizedUrl = ApiClient.normalizePublicUrl(uploadedUrl) ?? '';
    if (normalizedUrl.isEmpty) {
      throw Exception('Image upload returned an empty URL.');
    }

    return UploadedMedia(
      url: normalizedUrl,
      path: response['path']?.toString(),
      fileName: response['fileName']?.toString(),
      bucket: response['bucket']?.toString(),
      objectPath: response['objectPath']?.toString(),
    );
  }
}
