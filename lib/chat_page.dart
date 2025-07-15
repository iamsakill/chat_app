import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart'; // Added for consistent error handling and user check

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherEmail;
  final String? otherUserName; // New: To display in app bar
  final String? otherUserProfilePic; // New: To display in app bar

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherEmail,
    this.otherUserName,
    this.otherUserProfilePic,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String chatId;

  @override
  void initState() {
    super.initState();
    // Create consistent chat ID for both users by sorting and joining
    final ids = [widget.currentUserId, widget.otherUserId]..sort();
    chatId = ids.join('_');
    _initChat();
  }

  // Dispose controllers when the widget is removed from the widget tree
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    // Ensure chat metadata exists
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [widget.currentUserId, widget.otherUserId],
      'lastMessage': '',
      'lastMessageSender': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true to avoid overwriting existing data
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: User not logged in or ID mismatch.')),
      );
      return;
    }

    // Create message data
    final messageData = {
      'text': text,
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'chatId': chatId,
    };

    try {
      // Add to messages collection
      await FirebaseFirestore.instance.collection('messages').add(messageData);
      print('Message added to Firestore successfully!');

      // Update chat metadata
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageSender': widget.currentUserId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      print('Chat document updated successfully!');

      _messageController.clear();
      // Scroll to bottom after sending message
      _scrollToBottom();
    } on FirebaseException catch (e) {
      print('Firebase Error sending message: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message (Firebase): ${e.message}')),
      );
    } catch (e) {
      print('General Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasProfilePic = widget.otherUserProfilePic != null && widget.otherUserProfilePic!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              // Use NetworkImage only if profile pic exists
              backgroundImage: hasProfilePic
                  ? NetworkImage(widget.otherUserProfilePic!) as ImageProvider<Object>
                  : null,
              // Provide onBackgroundImageError only if backgroundImage is provided
              onBackgroundImageError: hasProfilePic
                  ? (exception, stackTrace) {
                print('Error loading other user\'s network profile pic: $exception');
                // Optionally, trigger a rebuild to show the icon fallback if an image fails to load
                // setState(() { /* perhaps clear widget.otherUserProfilePic if it's mutable */ });
              }
                  : null, // Set to null if no backgroundImage
              // Show an Icon if no profile picture is available
              child: !hasProfilePic
                  ? Icon(
                Icons.person, // Or Icons.account_circle, Icons.group
                color: Theme.of(context).primaryColor,
                size: 24, // Adjust size as needed
              )
                  : null, // No child if backgroundImage is used
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName ?? widget.otherEmail.split('@').first), // Display name or email prefix
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () { /* Video call logic */ }),
          IconButton(icon: const Icon(Icons.call), onPressed: () { /* Audio call logic */ }),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () { /* More options */ }),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatId', isEqualTo: chatId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error fetching messages: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello! Your messages will appear here.'));
                }

                final messages = snapshot.data!.docs;
                // Ensure scrolling to bottom when new messages arrive
                // Use a slight delay to allow rendering before scrolling
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && _scrollController.position.extentAfter == 0) {
                    _scrollToBottom();
                  }
                });

                String? lastDate;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final messageTime = timestamp?.toDate();

                    String currentDate = '';
                    if (messageTime != null) {
                      currentDate = DateFormat('EEEE, MMMM d, yyyy').format(messageTime);
                    }

                    bool showDateSeparator = false;
                    if (lastDate == null || currentDate != lastDate) {
                      showDateSeparator = true;
                      lastDate = currentDate;
                    }

                    return Column(
                      children: [
                        if (showDateSeparator && messageTime != null) // Ensure messageTime is not null for separator
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Chip(
                              label: Text(
                                _formatDateSeparator(messageTime),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.grey[700],
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              isMe ? 60 : 12, // More margin for sender
                              4,
                              isMe ? 12 : 60, // Less margin for receiver
                              4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context).primaryColor // Sender's bubble color
                                  : Colors.grey[200], // Receiver's bubble color
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(4),
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                if (messageTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      DateFormat('h:mm a').format(messageTime),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      prefixIcon: Icon(Icons.sentiment_satisfied_alt, color: Colors.grey[600]), // Emoji icon
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, color: Colors.grey[600]), // Attachment icon
                          const SizedBox(width: 8),
                          Icon(Icons.camera_alt, color: Colors.grey[600]), // Camera icon
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'TODAY';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    } else {
      return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
    }
  }
}