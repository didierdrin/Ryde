import 'dart:io';
import 'package:ryde_rw/firestore_stub.dart';

class PdfUploader {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String?> uploadFileAndReturnUrl(
      String userId, String field, File file) async {
    final fileName = "$field-${DateTime.now().millisecondsSinceEpoch}.pdf";
    try {
      final storageRef = _storage.ref().child("pdfs/$userId/$fileName");
      await storageRef.putFile(file);

      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}


