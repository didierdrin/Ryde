import 'package:ryde_rw/firestore_stub.dart';
import 'package:ryde_rw/models/message.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<Map<String, dynamic>>> getChatRooms(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  static Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  static Future<void> sendMessage(
      String chatId, String text, String sender, String user) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': sender,
      'user': user,
      'time': Timestamp.now(),
      'isRead': false,
      'order': '',
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    });
  }

  static Future<String> getOrCreateChat(
      String currentUserId, String otherUserId) async {
    final querySnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
    });

    return newChat.id;
  }
}
