DateTime _parseTime(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

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
      time: _parseTime(data['time']),
    );
  }
}

