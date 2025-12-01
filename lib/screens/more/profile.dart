import 'dart:io';
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
    }
  }

  void _showQRBottomSheet(BuildContext context, String qrFilePath) {
    showBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Code',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              Image.file(
                File(qrFilePath),
                width: 200,
                height: 200,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => shareQRCode(context, qrFilePath),
                child: Text('Share QR Code'),
              ),
            ],
          ),
        );
      },
    );
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
                            SizedBox(height: 10),
                            Text(
                              "Everything about you",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final qrData =
                                'tel:*182*1*1*${removeCountryCode(user.momoPhoneNumber)}#';
                            final qrFilePath =
                                await QRCodeService.generateQRCodeImage(qrData);
                            _showQRBottomSheet(context, qrFilePath);
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
                  ),
                  SizedBox(height: 20),
                  TabBar(tabs: tabs),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            AccountInfo(),
            MyVehicleTab(), //MyVehicle(),
          ],
        ),
      ),
    );
  }
}