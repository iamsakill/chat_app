import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'text': text, 'timestamp': timestamp};
  }

  static MessageModel fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
