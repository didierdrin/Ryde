import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static Future<String> uploadImage(File image, String folderName) async {
    String downloadURL = '';
    var fileName = image.path.split('/').last;
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('$folderName/$fileName');

    try {
      await imageRef.putFile(File(image.path));
      downloadURL = await imageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      downloadURL = e.toString();
    } catch (e) {
      downloadURL = e.toString();
    }
    return downloadURL;
  }


  static Future<List<String>> uploadImagesList(
      List<File> images, String folderName) async {
    List<String> imagesUrl = [];
    for (int i = 0; i < images.length; i++) {
      var fileName = images[i].path.split('/').last;

      final reference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('$folderName/$fileName');
      firebase_storage.UploadTask uploadTask = reference.putFile(images[i]);
      uploadTask.snapshotEvents.listen((event) {});
      firebase_storage.TaskSnapshot snapshot =
          await uploadTask.whenComplete(() {});
      final imgUrl = await snapshot.ref.getDownloadURL();
      imagesUrl.add(imgUrl);
    }
    return imagesUrl;
  }


  static  Future<String?> uploadFileToFirebaseStorage(File file, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

}
