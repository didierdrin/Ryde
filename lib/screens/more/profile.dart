import 'dart:io';
// import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:animation_wrappers/Animations/faded_scale_animation.dart';
import 'package:animation_wrappers/Animations/faded_slide_animation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/screens/more/account_info.dart';
import 'package:ryde_rw/screens/more/myvehicle.dart';
import 'package:ryde_rw/service/qr_code_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

class MyProfile extends ConsumerWidget {
  const MyProfile({super.key});

  Future<void> shareQRCode(BuildContext context, String qrData) async {
    try {
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
    } finally {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    
    final List<Widget> tabs = <Widget>[
      Tab(text: "Account Info"),
      Tab(text: "My Vehicle"),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: backgroundColor,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(150),
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: backgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Profile",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Everything about you",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                            ),
                            SizedBox(width: 20),
                          ],
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final qrData =
                                'tel:*182*1*1*${removeCountryCode(user.momoPhoneNumber)}#';
                            final qrFilePath =
                                await QRCodeService.generateQRCodeImage(qrData);
                            showBottomSheet(context, qrFilePath);
                          },
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              FadedScaleAnimation(
                                scaleDuration: const Duration(
                                  milliseconds: 600,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  width: 90,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: SizedBox(
                                      height: 70,
                                      width: 50,
                                      child: Image.asset(
                                        'assets/qrcode.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    alignment: Alignment.topLeft,
                    child: TabBar(
                      indicatorWeight: 4.0,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: tabs,
                      isScrollable: true,
                      labelStyle: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                      labelColor: primaryColor,
                      indicatorColor: primaryColor,
                      unselectedLabelColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(children: [AccountInfo(), MyVehicleTab()]),
      ),
    );
  }

  void showBottomSheet(BuildContext context, String fileqrcode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'MY MOMO QR CODE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 30),
                    GestureDetector(
                      onTap: () async {
                        await shareQRCode(context, fileqrcode);
                      },
                      child: Container(
                        width: 22,
                        height: 23,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kMainColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.share_outlined,
                          color: kWhiteColor,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Image.file(
                  File(fileqrcode),
                  width: MediaQuery.sizeOf(context).width * 0.7,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
