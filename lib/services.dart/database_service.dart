import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      print('Creating user in Firestore: ${user.uid}');
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      print('User created successfully');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<String> createChat(String currentUserId, String peerUserId) async {
    final chatId = _generateChatId(currentUserId, peerUserId);
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserId, peerUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return chatId;
  }

  String _generateChatId(String a, String b) {
    return a.hashCode <= b.hashCode ? '$a-$b' : '$b-$a';
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final message = MessageModel(
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('chats/$chatId/messages').add(message.toMap());

    // Update last message in chat
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
