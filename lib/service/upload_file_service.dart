import 'dart:io';
import 'package:ryde_rw/service/image_upload_service.dart';

class PdfUploader {
  Future<String?> uploadFileAndReturnUrl(
      String userId, String field, File file) async {
    try {
      return await ImageUploadService.uploadFile(file, 'pdfs/$userId/$field');
    } catch (_) {
      return null;
    }
  }
}
