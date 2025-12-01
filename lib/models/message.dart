class Message {
  final String text, order, user, sender;
  final bool isRead;
  final DateTime time;

  Message({
    required this.text,
    required this.order,
    required this.user,
    required this.sender,
    required this.isRead,
    required this.time,
  });

  factory Message.fromJson(Map<String, dynamic> data) {
    return Message(
      text: data['text'],
      order: data['order'],
      user: data['user'],
      sender: data['sender'],
      isRead: data['isRead'],
      time: data['time'].toDate(),
    );
  }
}
