import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ryde_rw/models/message.dart';
import 'package:ryde_rw/service/chat_service.dart';
import 'package:ryde_rw/theme/colors.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatPage({super.key, required this.chatId, required this.otherUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              radius: 25,
              child: Icon(Icons.person),
            ),
            SizedBox(width: 14),
            Text(
              widget.otherUserId,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: ChatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('No messages yet'),
                    );
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.sender == currentUser?.uid;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Color(0xfff8f9fd)
                                : Color(0xffebf3f9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontSize: 13.5),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Color(0xfff8f9fd),
                      ),
                      child: TextFormField(
                        controller: _messageController,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: "Write your message",
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 13.5, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: primaryColor,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white, size: 22),
                        onPressed: () async {
                          if (_messageController.text.trim().isEmpty) return;

                          await ChatService.sendMessage(
                            widget.chatId,
                            _messageController.text.trim(),
                            currentUser!.uid,
                            widget.otherUserId,
                          );
                          _messageController.clear();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}