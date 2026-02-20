import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/build_list.dart';
import 'package:ryde_rw/screens/more/change_language.dart';
import 'package:ryde_rw/screens/more/manage_address.dart';
import 'package:ryde_rw/screens/more/privacy_policy.dart';
import 'package:ryde_rw/screens/more/profile_simple.dart';
import 'package:ryde_rw/screens/more/support.dart';
import 'package:ryde_rw/screens/signin_signup.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/theme/style_text.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class More extends ConsumerWidget {
  final List<IconData> icons = [
    Icons.location_pin,
    Icons.email,
    Icons.clear_all_outlined,
    Icons.language,
    Icons.power_settings_new,
  ];

  final List<Widget> routes = [
    ManageAddress(),
    Support(),
    PrivacyPolicy(),
    ChangeLanguage(),
  ];

  More({super.key});

  Future<void> launchWhatsApp(BuildContext context) async {
    const String phone = '250780786039';
    final Uri url = Uri.parse('https://wa.me/$phone');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Failed to launch WhatsApp.')),
      );
    }
  }

  void _shareQRCodeStub(BuildContext context, String qrData) async {
    try {
      await Share.shareXFiles([XFile(qrData)], text: 'Ryde');
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
    try {
      final user = ref.watch(userProvider);
      
      if (user == null) {
        print('More: User is null, showing loading screen');
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading user data...'),
              ],
            ),
          ),
        );
      }

      print('More: User loaded successfully: ${user.id}');
    // final totalBalance = ref.watch(totalBalanceProvider(user.id));
    List<String> title = [
      "Manage Address",
      "Support",
      "Privacy Policy",
      "Change Language",
      "Logout",
    ];
    List<String> subtitle = [
      "Pre-saved Address",
      "Connect us for",
      "Know privacy",
      "Set your language",
      "Logout",
    ];

      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: ListView(
            children: [
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width,
              color: backgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Account",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 17),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileSimple(),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 170,
                                child: Text(
                                  user.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontSize: 20),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 5),
                                  Text("View Profile"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, size: 36, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Wallet Section
          Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    // SizedBox(
                    //   height: 50,
                    //   child: ListTile(
                    //     contentPadding: EdgeInsets.only(left: 26, right: 20),
                    //     horizontalTitleGap: 0,
                    //     onTap: () {
                    //       Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (context) => Wallet(
                    //               userId: user.id,
                    //             ),
                    //           ));
                    //     },
                    //     leading: Icon(
                    //       Icons.account_balance_wallet,
                    //       color: Colors.white,
                    //       size: 20,
                    //     ),
                    //     title: Row(
                    //       children: [
                    //         Text(
                    //           locale.wallet,
                    //           style: Theme.of(context)
                    //               .textTheme
                    //               .bodyLarge!
                    //               .copyWith(color: Colors.white, fontSize: 14),
                    //         ),
                    //         Spacer(),
                    //         Row(
                    //           children: [
                    //             SizedBox(
                    //                 width: 80,
                    //                 child: Text(
                    //                   "${region.currency} $totalBalance",
                    //                   style: TextStyle(color: Colors.white),
                    //                   overflow: TextOverflow.ellipsis,
                    //                 )),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               size: 25,
                    //               color: Colors.white,
                    //             )
                    //           ],
                    //         )
                    //       ],
                    //     ),
                    //     subtitle: Text(
                    //       locale.quickPayments,
                    //       style: Theme.of(context)
                    //           .textTheme
                    //           .bodyLarge!
                    //           .copyWith(color: Colors.white, fontSize: 12),
                    //     ),
                    //   ),
                    // ),
                    SizedBox(height: 25),
                    // Settings Options List
                 Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          itemCount: title.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              onTap: () {
                                try {
                                  if (index == title.length - 1) {
                                    showLogoutBottomSheet(context, ref);
                                  } else if (index == 1) {
                                    launchWhatsApp(context);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => routes[index],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('More: Error handling tap for index $index: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                }
                              },
                              horizontalTitleGap: 0,
                              leading: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Icon(
                                  icons[index],
                                  size: 20,
                                  color: primaryColor,
                                ),
                              ),
                              title: Text(
                                title[index],
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      color: Colors.black,
                                      fontSize: 13.5,
                                    ),
                              ),
                              subtitle: Text(
                                subtitle[index],
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      fontSize: 12,
                                      color: Color(0xffb3b3b3),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                  ],
                ),
              ),
            
Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white),
                child: BuildListTile(
                  isSelected: false,
                  icon: Icons.share,
                  image: 'assets/solar_cart-outline.png',
                  text: "Share App",
                  onTap: () async {
                    await shareApp("Share App");
                  },
                ),
              ),
            

        //  Container(
        //         width: MediaQuery.of(context).size.width,
        //         decoration: BoxDecoration(color: Colors.white),
        //         child: BuildListTile(
        //           isSelected: false,
        //           icon: Icons.qr_code_2,
        //           image: 'assets/solar_cart-outline.png',
        //           text: 'Mobile Money QR Code',
        //           onTap: () {
        //             showMobileNumberModal(context);
        //           },
        //         ),
        //       ),
            

            Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white),
                child: BuildListTile(
                  isSelected: true,
                  icon: Icons.delete_outline_outlined,
                  image: 'assets/solar_cart-outline.png',
                  text: 'Close Account',
                  onTap: () async {
                    showAccountDeletionBottomSheet(context, ref);
                  },
                ),
              ),
            
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('More: Critical error in build method: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 8),
              Text('Error: ${e.toString()}', style: TextStyle(fontSize: 12)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Trigger rebuild
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void showAccountDeletionBottomSheet(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      builder: (BuildContext context) {
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 60.0,
              ),
              const SizedBox(height: 16.0),
              Text("Account Deletion", style: AppStyles.headerTextStyle),
              const SizedBox(height: 10.0),
              Text(
                "You", //locale.youwont,
                textAlign: TextAlign.center,
                style: AppStyles.accountTextStyle,
              ),
              const SizedBox(height: 20.0),
              // Continue button
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await LocalStorage.removeToken();
                  await LocalStorage.removeUser();
                  ref.read(userProvider.notifier).setUser(null);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SigninSignup()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    "Continue", // "Continue"
                    style: AppStyles.accountTextStyle.copyWith(
                      color: const Color(0xFFF15C5A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Cancel button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    "Cancel",
                    style: AppStyles.accountTextStyle.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF101010),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }
}

