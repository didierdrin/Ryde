import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ryde_rw/screens/chats/chat_page.dart';
import 'package:ryde_rw/service/chat_service.dart';
import 'package:ryde_rw/theme/colors.dart';

class Chats extends StatelessWidget {
  const Chats({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      print('Chats: Building chat screen');
      return Scaffold(
        backgroundColor: Colors.white,
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
        body: _buildSafeChatRooms(),
      );
    } catch (e, stackTrace) {
      print('Chats: Critical error in build method: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: Text('Chats'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 8),
              Text('Error: ${e.toString()}', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSafeChatRooms() {
    try {
      return ChatRooms();
    } catch (e, stackTrace) {
      print('Chats: Error building ChatRooms: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Error loading chats'),
            SizedBox(height: 8),
            Text('Please try again later'),
          ],
        ),
      );
    }
  }
}

class ChatRooms extends StatelessWidget {
  ChatRooms({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Center(child: Text('Please login to view chats'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ChatService.getChatRooms(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No chats yet', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        final chats = snapshot.data!;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          color: backgroundColor,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chat['id'],
                        otherUserId: otherUserId,
                      ),
                    ),
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
                    leading: CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      otherUserId,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontSize: 13.5),
                    ),
                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 12,
                            color: Color(0xffa8aeb2),
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
              // Archive functionality not implemented
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
