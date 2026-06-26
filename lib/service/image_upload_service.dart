import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Image upload via base64 data URLs (stored in Neon/API profile fields).
class ImageUploadService {
  static Future<String> uploadImage(File image, String folderName) async {
    try {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final ext = image.path.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'gif'
              ? 'image/gif'
              : ext == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg';
      return 'data:$mime;base64,$base64';
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<String>> uploadImagesList(
      List<File> images, String folderName) async {
    final urls = <String>[];
    for (final image in images) {
      urls.add(await uploadImage(image, folderName));
    }
    return urls;
  }

  static Future<String?> uploadFile(File file, String path) async {
    try {
      return await uploadImage(file, path);
    } catch (_) {
      return null;
    }
  }
}
