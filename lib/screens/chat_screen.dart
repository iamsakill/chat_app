import 'package:chat_app/screens/message_bubble.dart';
import 'package:chat_app/services.dart/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  ChatScreen({required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: Provider.of<DatabaseService>(
                context,
              ).getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(hintText: 'Type a message...'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              if (_messageController.text.trim().isNotEmpty) {
                await Provider.of<DatabaseService>(
                  context,
                  listen: false,
                ).sendMessage(
                  chatId: widget.chatId,
                  senderId: currentUserId,
                  text: _messageController.text.trim(),
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
