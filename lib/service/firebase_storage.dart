import 'dart:convert';
import 'dart:io';

/// Image upload: converts to base64 data URL (no Firebase).
/// Store the returned string in Neon/API as needed.
class FirebaseStorageService {
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
    List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image, folderName);
      urls.add(url);
    }
    return urls;
  }

  static Future<String?> uploadFileToFirebaseStorage(File file, String path) async {
    try {
      return await uploadImage(file, path);
    } catch (e) {
      return null;
    }
  }
}
