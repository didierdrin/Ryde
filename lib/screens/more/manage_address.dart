import 'package:flutter/material.dart';

import 'package:ryde_rw/screens/more/add_address.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/service/address_service.dart';

class ManageAddress extends ConsumerWidget {
  final List icons = [Icons.home, Icons.shop, Icons.escalator_warning_outlined];

  ManageAddress({super.key});

  String _getAddressType(int index) {
    switch (index) {
      case 0:
        return 'home';
      case 1:
        return 'office';
      case 2:
        return 'other';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List title = ['Home', "Office", "Other"];

    final user = ref.watch(userProvider);
    final addressesAsync = ref.watch(
      addressesProvider(user?.phoneNumber ?? ''),
    );

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: backgroundColor),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            color: backgroundColor,
            padding: EdgeInsetsDirectional.only(start: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Expanded(
                      child: Text(
                        "Manage Address",
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      "Pre-saved Address",
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                Spacer(),
                Expanded(
                  flex: 5,
                  child: Image.asset("assets/head_address.png"),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAddress(
                            addresses: addressesAsync.value ?? {},
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          width: 250,
                          child: Text(
                            "Add New Address",
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: addressesAsync.when(
                  data: (addresses) {
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (BuildContext context, int index) {
                        final addressType = _getAddressType(index);
                        final address = addresses[addressType];

                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddAddress(
                                  defaultIndex: index + 1,
                                  addresses: addresses,
                                ),
                              ),
                            );
                          },
                          horizontalTitleGap: 0,
                          leading: Icon(
                            icons[index],
                            color: primaryColor,
                            size: 22,
                          ),
                          minVerticalPadding: 10,
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 7),
                                Text(
                                  title[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  address?.addressString ??
                                      "No address saved",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 13.5,
                                        color: Color(0xffb3b3b3),
                                      ),
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading addresses',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}