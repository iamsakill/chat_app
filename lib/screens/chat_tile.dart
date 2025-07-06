import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  String _getPeerName() {
    return chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        _getPeerName(),
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}',
        style: TextStyle(color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
