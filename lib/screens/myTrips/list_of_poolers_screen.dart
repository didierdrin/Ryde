import 'package:flutter/material.dart';

import 'package:ryde_rw/shared/locations_shared.dart';

class ListOfPoolersScreen extends StatelessWidget {
  ListOfPoolersScreen({super.key});

  final List<PoolTakerRequest> _list = [
    PoolTakerRequest(
      image: 'assets/profiles/img1.png',
      rating: '4.5',
      title: 'George Enterson',
      subTitle: 'Bank of USA',
      seatCount: '1',
      amount: '\$3.50',
      pickup: 'Hemiltone Bridge',
      drop: 'World Trade Point',
    ),
    PoolTakerRequest(
      image: 'assets/profiles/img2.png',
      rating: '4.8',
      title: 'Samantha Smith',
      subTitle: 'Harvard law school',
      seatCount: '2',
      amount: '\$7.50',
      pickup: 'City Parle Point',
      drop: 'World Trade Point',
    ),
    PoolTakerRequest(
      image: 'assets/profiles/img3.png',
      rating: '4.7',
      title: 'Billie Anderson',
      subTitle: 'Florida University',
      seatCount: '1',
      amount: '\$5.50',
      pickup: 'Hemiltone Bridge',
      drop: 'World Trade Point',
    ),
    PoolTakerRequest(
      image: 'assets/profiles/img4.png',
      rating: '4.5',
      title: 'George Enterson',
      subTitle: 'Bank of USA',
      seatCount: '1',
      amount: '\$3.50',
      pickup: 'Hemiltone Bridge',
      drop: 'World Trade Point',
    ),
    PoolTakerRequest(
      image: 'assets/profiles/img5.png',
      rating: '4.8',
      title: 'Samantha Smith',
      subTitle: 'Harvard law school',
      seatCount: '2',
      amount: '\$7.50',
      pickup: 'City Parle Point',
      drop: 'World Trade Point',
    ),
    PoolTakerRequest(
      image: 'assets/profiles/img6.png',
      rating: '4.7',
      title: 'Billie Anderson',
      subTitle: 'Florida University',
      seatCount: '1',
      amount: '\$5.50',
      pickup: 'Hemiltone Bridge',
      drop: 'World Trade Point',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${"Available"} 25 Jun, 10:30 am',
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        margin: EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView.separated(
          padding: EdgeInsets.all(15),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                buildShowModalBottomSheet(theme, context, index);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.scaffoldBackgroundColor,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Image.asset(
                            _list[index].image,
                            height: 44,
                            width: 44,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Color(0xff69ca2f),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xffffae22),
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _list[index].rating,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontSize: 8,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _list[index].title,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              Text(
                                _list[index].amount,
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_sharp,
                                color: theme.primaryColor,
                                size: 12,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _list[index].subTitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_taxi,
                                    size: 18,
                                    color: theme.hintColor.withOpacity(0.1),
                                  ),
                                  SizedBox(width: 6),
                                  CircleAvatar(radius: 2),
                                  SizedBox(width: 6),
                                  Row(
                                    children: List.generate(
                                      3,
                                      (listIndex) => Icon(
                                        Icons.account_circle,
                                        size: 18,
                                        color:
                                            (int.tryParse(
                                                      _list[index].seatCount,
                                                    ) ??
                                                    0) >
                                                listIndex
                                            ? theme.primaryColor
                                            : theme.hintColor.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.circle,
                                  color: Colors.grey[300],
                                  size: 5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                _list[index].pickup,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.grey[400],
                              size: 10,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[300],
                                size: 12,
                              ),
                              SizedBox(width: 10),
                              Text(
                                _list[index].drop,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemCount: _list.length,
        ),
      ),
    );
  }

  Future<dynamic> buildShowModalBottomSheet(
    ThemeData theme,
    BuildContext context,
    int index,
  ) {
    return showModalBottomSheet(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6),
          Center(
            child: Container(
              height: 4,
              width: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: theme.dividerColor,
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(_list[index].image, height: 44, width: 44),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _list[index].title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            _list[index].amount,
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_sharp,
                            color: theme.primaryColor,
                            size: 12,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _list[index].subTitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            '${_list[index].seatCount} ${"seats"}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 34),
          Divider(thickness: 3, height: 3),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Rating', 
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xff69ca2f),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Color(0xffffae22), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Ride with", //AppLocalizations.of(context)?.rideWith ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '314 people',
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Joined", //AppLocalizations.of(context)?.joined ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'in 2019',
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Divider(thickness: 3, height: 3, color: theme.dividerColor),
          SizedBox(height: 30),
          buildColumn(
            theme,
            "hobby", //AppLocalizations.of(context)?.hobby ?? '',
            "hobby details", //AppLocalizations.of(context)?.hobbyDetail ?? '',
          ),
          SizedBox(height: 28),
          buildColumn(
            theme,
            "bio", //AppLocalizations.of(context)?.bio ?? '',
            "bio details", // AppLocalizations.of(context)?.bioDetail ?? '',
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Column buildColumn(ThemeData theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
          ),
        ),
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            subtitle,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
