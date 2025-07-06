import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/screens/chat_tile.dart';
import 'package:chat_app/services.dart/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart'; // Add this import

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<User?>();

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AuthScreen()),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          // Add profile button
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserSearchScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: Provider.of<DatabaseService>(
          context,
        ).getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Start a new conversation!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final chat = snapshot.data![index];
              return ChatTile(
                chat: chat,
                currentUserId: currentUser.uid,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: chat.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
