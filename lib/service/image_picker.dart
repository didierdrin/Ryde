import 'package:image_picker/image_picker.dart';

class FilePickerService {
  static final _imagePicker = ImagePicker();

  static Future<XFile?> pickImageWithCompression() async {
    return await _imagePicker.pickImage(source: ImageSource.gallery);
  }

  static Future<XFile?> captureImageWithCamera() async {
    return await _imagePicker.pickImage(source: ImageSource.camera);
  }
}



