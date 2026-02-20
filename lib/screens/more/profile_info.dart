import 'dart:io';
import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/text_field.dart';
import 'package:ryde_rw/models/profiles_info.dart';
import 'package:ryde_rw/service/profiles_info_service.dart';
import 'package:ryde_rw/service/upload_file_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

import 'package:file_picker/file_picker.dart';

class ProfileInfo extends ConsumerStatefulWidget {
  const ProfileInfo({super.key});

  @override
  ProfileInfoState createState() => ProfileInfoState();
}

class ProfileInfoState extends ConsumerState<ProfileInfo> {
  final TextEditingController shortBioController = TextEditingController();
  final TextEditingController hobbiesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PdfUploader pdfUploader = PdfUploader();
  String? governmentIdUrl;
  String? governmentIdFileName;
  String? drivingLicenseUrl;
  String? drivingLicenseFileName;
  File? governmentIdFile;
  File? drivingLicenseFile;
  bool isFormValid = false;
  bool isGovernmentIdLoading = false;
  bool isDrivingLicenseLoading = false;

  @override
  void initState() {
    super.initState();
    loadVehicleData();
  }

  Future<void> loadVehicleData() async {
    final profileinfor = ref.read(profileinfoProvider);
    if (profileinfor != null) {
      setState(() {
        governmentIdUrl = profileinfor.governmentIdUrl;
        drivingLicenseUrl = profileinfor.drivingLicenseUrl;
        governmentIdFileName = profileinfor.governmentIdUrl;
        drivingLicenseFileName = profileinfor.drivingLicenseUrl;
        shortBioController.text = profileinfor.shortBio;
        hobbiesController.text = profileinfor.hobbies;
      });
    }
  }

  @override
  void dispose() {
    shortBioController.dispose();
    hobbiesController.dispose();
    super.dispose();
  }

  Future<void> pickFile(String field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (field == 'governmentId') {
          setState(() {
            isGovernmentIdLoading = true;
          });
          governmentIdFile = File(result.files.single.path!);
          governmentIdFileName = result.files.single.name;
          setState(() {
            isGovernmentIdLoading = false;
          });
        } else if (field == 'drivingLicense') {
          setState(() {
            isDrivingLicenseLoading = true;
          });
          drivingLicenseFile = File(result.files.single.path!);
          drivingLicenseFileName = result.files.single.name;
          setState(() {
            isDrivingLicenseLoading = false;
          });
        }
      });
    }
  }

  Future<void> uploadAllPdfs(String userId) async {
    if (governmentIdFile != null) {
      governmentIdUrl = await pdfUploader.uploadFileAndReturnUrl(
        userId,
        'governmentId',
        governmentIdFile!,
      );
    }
    if (drivingLicenseFile != null) {
      drivingLicenseUrl = await pdfUploader.uploadFileAndReturnUrl(
        userId,
        'drivingLicense',
        drivingLicenseFile!,
      );
    }
  }

  Future<void> saveProfileInfo(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isFormValid = true;
    });

    try {
      await uploadAllPdfs(userId);
      final profileInfo = ProfileInformation(
        userId: userId,
        shortBio: shortBioController.text,
        hobbies: hobbiesController.text,
        governmentIdUrl: governmentIdUrl,
        drivingLicenseUrl: drivingLicenseUrl,
        updatedAt: DateTime.now(),
      );

      await ProfilesInfoService.saveOrUpdateProfiles(profileInfo, ref);

      setState(() {
        isFormValid = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text("Profile info saved successfully!"),
        ),
      );
    } catch (e) {
      setState(() {
        isFormValid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text("Error saving profile info"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final user = ref.watch(userProvider)!;
    return ModalProgressHUD(
      inAsyncCall: isFormValid,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ListView(
            children: [
              const SizedBox(height: 20),
              Divider(thickness: 3, color: backgroundColor),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFieldInput(
                        controller: shortBioController,
                        labelText: "Short Bio",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Short Bio is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 5),
                      TextFieldInput(
                        controller: hobbiesController,
                        labelText: "Hobbies",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Hobbies are required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Government ID",
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(color: Colors.grey, fontSize: 13),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await pickFile('governmentId');
                            },
                            child: isGovernmentIdLoading
                                ? CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    governmentIdFileName != null
                                        ? "Change Government ID"
                                        : "Upload Government ID",
                                  ),
                          ),
                          if (governmentIdFileName != null)
                            Tooltip(
                              message: governmentIdFileName,
                              child: Icon(
                                Icons.insert_drive_file,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Driving License",
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(color: Colors.grey, fontSize: 13),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await pickFile('drivingLicense');
                            },
                            child: isDrivingLicenseLoading
                                ? CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    drivingLicenseFileName != null
                                        ? "Change Driving License"
                                        : "Upload Driving License",
                                  ),
                          ),
                          if (drivingLicenseFileName != null)
                            Tooltip(
                              message: drivingLicenseFileName,
                              child: Icon(
                                Icons.insert_drive_file,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Divider(thickness: 3, color: backgroundColor),
              const SizedBox(height: 60),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: BottomBar(
                textColor: kWhiteColor,
                onTap: () async {
                  await saveProfileInfo(user.id);
                },
                text: "Update Info",
              ),
            
          ),
        ],
      ),
    );
  }
}

