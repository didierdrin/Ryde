import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:ryde_rw/theme/colors.dart';

class QRCodeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<ui.Image> loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = Uint8List.view(data.buffer);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Failed to load image from $assetPath: $e');
      rethrow;
    }
  }

  static Future<String> generateQRCodeImage(String qrData) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final qrFilePath = '${directory.path}/qr_code_custom_$timestamp.png';

      const qrSize = 500.0;
      const padding = 20.0;
      const textHeight = 50.0;
      const iconSize = 130.0;
      const iconSpacing = 30.0;
      const iconTextSpacing = 5.0;
      const additionalPadding = 30.0;

      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: ui.Color(0xFF00C853),
      );

      final qrImage = await qrPainter.toImage(500);
      final qrByteData = await qrImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final qrBytes = qrByteData!.buffer.asUint8List();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = Paint();

      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          qrSize + 2 * padding,
          qrSize +
              2 * padding +
              textHeight +
              iconSize +
              iconSpacing +
              additionalPadding,
        ),
        paint..color = ui.Color(0xFFFFFFFF),
      );

      final qrImageCodec = await ui.instantiateImageCodec(qrBytes);
      final qrImageFrame = await qrImageCodec.getNextFrame();
      canvas.drawImage(
        qrImageFrame.image,
        const Offset(padding, padding),
        Paint(),
      );

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(
        (qrSize + 2 * padding).toInt(),
        (qrSize + 2 * padding + additionalPadding).toInt(),
      );
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final file = File(qrFilePath);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      return qrFilePath;
    } catch (e) {
      debugPrint('Error generating QR Code: $e');
      rethrow;
    }
  }

  static Future<File> saveQRCodeToGalleryFromPath(String localFilePath) async {
    try {
      await Permission.storage.request();
      final directory = await getTemporaryDirectory();
      final appPicturesDirectory = Directory('${directory.path}/Pictures');

      if (!appPicturesDirectory.existsSync()) {
        appPicturesDirectory.createSync(recursive: true);
      }

      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${appPicturesDirectory.path}/$fileName';

      final localFile = File(localFilePath);
      final bytes = await localFile.readAsBytes();

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw 'Failed to save QR Code to gallery.';
    }
  }

  static Future<String> getQRCodeAsImageFile(String qrData) async {
    try {
      final directory = await getTemporaryDirectory();
      final qrFilePath = '${directory.path}/qr_code.png';

      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final image = await qrPainter.toImage(300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final file = File(qrFilePath);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      return qrFilePath;
    } catch (e) {
      throw Exception('Failed to generate QR code image: $e');
    }
  }

  static Future<void> generateAndStoreQRCode({
    required String userId,
    required String qrData,
  }) async {
    try {
      final qrFilePath = await _generateQRCodeImage(qrData);
      final qrImageUrl = await _uploadQRCodeImage(qrFilePath, userId);
      await _storeQRCodeInFirestore(userId, qrImageUrl);
    } catch (e) {
      throw Exception('Failed to generate QR Code: $e');
    }
  }

  static Future<String> _generateQRCodeImage(String qrData) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/qr_code.png';

    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
    );

    final image = await qrPainter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(filePath);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return filePath;
  }

  static Future<String> _uploadQRCodeImage(
    String filePath,
    String userId,
  ) async {
    final ref = _storage.ref().child('qrcodes/$userId.png');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  static Future<void> _storeQRCodeInFirestore(
    String userId,
    String qrImageUrl,
  ) async {
    await _firestore.collection('qrcodes').doc(userId).set({
      'qr_code_img_url': qrImageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'generatedBy': userId,
    });
  }

  static Stream<String?> getQRCodeStream(String userId) {
    return _firestore
        .collection('qrcodes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['qr_code_img_url'] as String?);
  }
}
