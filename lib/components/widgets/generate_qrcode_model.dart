import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/service/qr_code_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

import 'package:ryde_rw/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

class MobileNumberModal extends ConsumerStatefulWidget {
  const MobileNumberModal({super.key});

  @override
  MobileNumberModalState createState() => MobileNumberModalState();
}

class MobileNumberModalState extends ConsumerState<MobileNumberModal> {
  final TextEditingController mobileController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // late AppLocalizations locale;
  bool _isLoading = false;
  String? _qrFilePath;
  String initialCountry = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider)!;
    phone = '';
    initialCountry = getCountryCode(user.momoPhoneNumber);
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  Future<void> shareQRCode(String qrData) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final qrFile = XFile(qrData);
      await Share.shareXFiles([qrFile], text: 'Here is my QR Code!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kGreen,
          content: Text('QR Code shared successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing QR Code')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> generateQrCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final qrData = 'tel:*182*1*1*$phone#';
    final qrFilePath = await QRCodeService.generateQRCodeImage(qrData);

    setState(() {
      _qrFilePath = qrFilePath;
      _isLoading = false;
    });
  }

  void resetState() {
    setState(() {
      _qrFilePath = null;
      phone = '';
      mobileController.clear();
    });
  }

  bool isValid() {
    return mobileController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // locale = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_qrFilePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'MY MOMO QR CODE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Image.file(
                      File(_qrFilePath!),
                      width: MediaQuery.of(context).size.width * 0.7,
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await shareQRCode(_qrFilePath!);
                      },
                      child: Icon(Icons.share, size: 30, color: kMainColor),
                    ),
                  ],
                ),
              )
            else
              Form(
                key: _formKey,
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Enter Mobile Money Number",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: IntlPhoneField(
                          cursorColor: kSimpleText,
                          controller: mobileController,
                          searchText: "Search Country",
                          invalidNumberMessage:
                              'Enter valid mobile money account',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: kMainColor),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: kRed),
                            ),
                          ),
                          initialCountryCode: initialCountry,
                          onChanged: (value) {
                            setState(() {
                              phone = value.number;
                              _qrFilePath = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.number.isEmpty) {
                              return 'Please enter a valid mobile money number';
                            } else if (value.number.length < 7) {
                              return 'Number must be at least 7 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: BottomBar(
                          isValid: isValid(),
                          onTap: () async {
                            await generateQrCode();
                          },
                          text: "Generate MOMO QR Code",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// void showMobileNumberModal(BuildContext context, WidgetRef ref) {
//   final modalKey = GlobalKey<MobileNumberModalState>();
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(
//         top: Radius.circular(20),
//       ),
//     ),
//     builder: (context) {
//       return MobileNumberModal(key: modalKey);
//     },
//   ).whenComplete(() {
//     modalKey.currentState?.resetState();
//   });
// }
