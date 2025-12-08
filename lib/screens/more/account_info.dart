import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/text_field.dart';
import 'package:ryde_rw/service/image_picker.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class AccountInfo extends ConsumerStatefulWidget {
  const AccountInfo({super.key});

  @override
  AccountInfoState createState() => AccountInfoState();
}

class AccountInfoState extends ConsumerState<AccountInfo> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController momoPhoneController = TextEditingController();
  bool isLoading = false;
  XFile? profileImage;
  String initialCountry = '', phone = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    if (user == null) return;
    
    nameController.text = user.fullName ?? '';
    phoneController.text = user.phoneNumber;
    
    try {
      if (user.momoPhoneNumber.isNotEmpty && user.momoPhoneNumber.startsWith('+')) {
        momoPhoneController.text = getPhone(user.momoPhoneNumber);
        phone = user.momoPhoneNumber;
        initialCountry = getCountryCode(user.momoPhoneNumber);
      } else {
        momoPhoneController.text = '';
        phone = '';
        initialCountry = 'RW';
      }
    } catch (e) {
      momoPhoneController.text = '';
      phone = '';
      initialCountry = 'RW';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    momoPhoneController.dispose();
    super.dispose();
  }

  Future<XFile?> handleCrop(XFile img) async {
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: img.path,
      maxHeight: 512,
      maxWidth: 512,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Crop image", //AppLocalizations.of(context)!.cropImage,
          toolbarColor: kMainColor,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    );
    return croppedImage != null ? XFile(croppedImage.path) : null;
  }

  Future<void> handlePickImage() async {
    final img = await FilePickerService.pickImageWithCompression();
    if (img != null) {
      final cropImg = await handleCrop(img);
      if (cropImg != null) {
        setState(() {
          profileImage = cropImg;
        });
      }
    }
  }

  Future<void> handleUpdate() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    
    setState(() {
      isLoading = true;
    });
    try {
      final userData = {
        'fullName': nameController.text,
        'momoPhoneNumber': phone,
      };

      if (profileImage != null) {
        await UserService.updateUserWithFile(
          user.id,
          userData,
          file: File(profileImage!.path),
          fileField: 'profilePicture',
          storageFolder: 'user_profiles',
        );
      } else {
        await UserService.updateUser(user.id, userData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profile updated successfully'),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update profile'),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool isValid() {
    return isValidNumber(phone);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user data...'),
          ],
        ),
      );
    }
    
    isValid();

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: handlePickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: handlePickImage,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ClipOval(
                                    child: SizedBox.fromSize(
                                      size: const Size.fromRadius(50),
                                      child: profileImage != null
                                          ? Image.file(
                                              File(profileImage!.path),
                                              fit: BoxFit.cover,
                                            )
                                          : user.profilePicture != null
                                          ? CachedNetworkImage(
                                              imageUrl: user.profilePicture!,
                                              fit: BoxFit.cover,
                                              progressIndicatorBuilder:
                                                  (
                                                    context,
                                                    url,
                                                    progress,
                                                  ) => Center(
                                                    child: SizedBox(
                                                      height: 50,
                                                      width: 50,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            value: progress
                                                                .progress,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Image.asset(
                                                        'assets/1.png',
                                                      ),
                                            )
                                          : Image.asset(
                                              'assets/2.png',
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.7,
                                      ), // Semi-transparent background
                                      child: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors
                                            .grey, // Adjust icon color as needed
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextFieldInput(
                    labelText: "Full Name",
                    hintText: "Enter your full name",
                    showSuffixIcon: false,
                    controller: nameController,
                    onChanged: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Full name is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFieldInput(
                    readOnly: true,
                    labelText: "Phone Number",
                    hintText: "Enter your phone number",
                    showSuffixIcon: false,
                    controller: phoneController,
                    onChanged: (value) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Phone number is required";
                      } else if (value.length < 10) {
                        return "Enter a valid phone number";
                      }
                      return null;
                    },
                  ),
                  Text(
                    'Mobile money account',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10),
                  IntlPhoneField(
                    cursorColor: kSimpleText,
                    controller: momoPhoneController,
                    readOnly: isLoading,
                    searchText: "Search Country",
                    invalidNumberMessage: 'Enter valid mobile money account',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.number.isEmpty) {
                        return "Please enter a valid phone number";
                      } else if (value.number.length < 7) {
                        return "Please enter a valid phone number";
                      } else {
                        return null;
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        phone = value.completeNumber;
                      });
                    },
                    keyboardType: TextInputType.phone,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(fontSize: 17),
                    decoration: InputDecoration(
                      fillColor: kPrimary,
                      hoverColor: kOrange,
                      hintStyle: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: kGreyColor),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: kBlack),
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      focusColor: kBlack,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kMainColor),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(24),
                        ),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: kRed),
                      ),
                    ),
                    initialCountryCode: initialCountry,
                  ),
                  const SizedBox(height: 15),
                  BottomBar(
                      textColor: kWhiteColor,
                      isValid: isValid(),
                      onTap: () async {
                        if (isValid()) {
                          await handleUpdate();
                        }
                      },
                      text: "Update",
                    ),
                  
                ],
              ),
            ),
          ),
        ),
      
    );
  }
}

