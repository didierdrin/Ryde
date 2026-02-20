import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String tripId;
  final String otherPartyName;

  const ChatPage({super.key, required this.tripId, required this.otherPartyName});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getChatMessages(widget.tripId);
      final list = (res['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() {
        _messages = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    setState(() => _sending = true);
    _messageController.clear();
    try {
      final res = await ApiService.sendChatMessage(widget.tripId, text);
      final msg = res['message'] as Map<String, dynamic>?;
      if (msg != null && mounted) {
        setState(() {
          _messages = [..._messages, msg];
          _sending = false;
        });
      } else {
        if (mounted) setState(() => _sending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Icon(Icons.person, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherPartyName,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final senderId = m['senderId'] as String?;
                          final isMe = senderId == user.id;
                          final text = m['text'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xffebf3f9),
                                    child: Icon(Icons.person, size: 18, color: primaryColor),
                                  ),
                                if (!isMe) const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? primaryColor : const Color(0xffebf3f9),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      text,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 8),
                                if (isMe)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primaryColor.withOpacity(0.2),
                                    child: Icon(Icons.person, size: 18, color: primaryColor),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write your message',
                      filled: true,
                      fillColor: const Color(0xfff8f9fd),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(Icons.send, color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
