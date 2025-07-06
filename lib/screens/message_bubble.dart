import 'package:chat_app/models/message_model.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
