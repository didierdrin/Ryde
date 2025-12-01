import 'package:flutter/material.dart';

import 'package:ryde_rw/screens/chats/chat_page.dart';
import 'package:ryde_rw/theme/colors.dart';

class Chats extends StatelessWidget {
  const Chats({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Chats",
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ChatRooms(),
    );
  }
}

class ChatRooms extends StatelessWidget {
  final List imgs = [
    "assets/profiles/img1.png",
    "assets/profiles/img2.png",
    "assets/profiles/img3.png",
    "assets/profiles/img4.png",
    "assets/profiles/img1.png",
    "assets/profiles/img3.png",
    "assets/profiles/img4.png",
    "assets/profiles/img2.png",
  ];
  final List names = [
    "George Anderson",
    "Emili Williamson",
    "Mark Taylor",
    "Lisa Davis",
    "Deneil Haydon",
    "Emili Williamson",
    "Mark Taylor",
    "Lisa Davis",
  ];

  ChatRooms({super.key});

  @override
  Widget build(BuildContext context) {
    

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      color: backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 10),
        itemCount: 8,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatPage()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                leading: SizedBox(
                  height: 50,
                  child: Image.asset(imgs[index]),
                ),
                title: Text(
                  names[index],
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      "No",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12,
                        color: Color(0xffa8aeb2),
                      ),
                    ),
                    Spacer(),
                    Text(
                      "20 min",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                        color: Color(0xffcccccc),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Archive extends StatelessWidget {
  final List imgs = [
    "assets/profiles/img1.png",
    "assets/profiles/img2.png",
    "assets/profiles/img3.png",
    "assets/profiles/img4.png",
  ];
  final List names = [
    "George Anderson",
    "Emili Williamson",
    "Mark Taylor",
    "Lisa Davis",
  ];

  Archive({super.key});

  @override
  Widget build(BuildContext context) {
    // var locale = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      color: backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 10),
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatPage()),
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                leading: SizedBox(
                  height: 50,
                  child: Image.asset(imgs[index]),
                ),
                title: Text(
                  names[index],
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      "No", // locale!.no,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12,
                        color: Color(0xffa8aeb2),
                      ),
                    ),
                    Spacer(),
                    Text(
                      "20 min",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                        color: Color(0xffcccccc),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
