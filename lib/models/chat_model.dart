import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  static ChatModel fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants']),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }
}
