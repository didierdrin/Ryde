import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryde_rw/theme/colors.dart';

class FilePickerOptionsModal extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

  const FilePickerOptionsModal({
    super.key,
    required this.onPickImage,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Choose an Option",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: kGreyColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: kBlackColor.withOpacity(0.2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.image, color: Colors.blue, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Choose from Photos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.blue.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onPickFile,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: kBlackColor.withOpacity(0.2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.file_copy, color: Colors.green, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Choose from File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.green.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

