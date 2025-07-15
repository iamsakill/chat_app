import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

import 'auth_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final searchController = TextEditingController();
  String searchQuery = '';
  final currentUser = FirebaseAuth.instance.currentUser!;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    currentUserId = currentUser.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality here or integrate with search bar
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert), // More options like settings
            onPressed: () {
              // Show a menu with Profile and Logout options
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                    MediaQuery.of(context).size.width - 100, // X position
                    kToolbarHeight, // Y position
                    0, // Right offset
                    0 // Bottom offset
                ),
                items: [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('Profile'),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ).then((value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                } else if (value == 'logout') {
                  logout();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CALLS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // CHATS Tab (Inbox)
          Column(
            children: [
              // Search Bar within the Chats tab
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search chats or start new chat by email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: searchQuery.isEmpty
                    ? _buildChatList() // Display existing chats
                    : _buildUserSearchResults(), // Display user search results
              ),
            ],
          ),
          // STATUS Tab (Placeholder)
          const Center(child: Text('Status updates will appear here.')),
          // CALLS Tab (Placeholder)
          const Center(child: Text('Call history will appear here.')),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading messages'));
        }

        final chats = snapshot.data?.docs ?? [];

        if (chats.isEmpty) {
          return const Center(child: Text("No chats found. Start a new conversation!"));
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(chat['participants']);
            participants.remove(currentUserId);
            final partnerId = participants.first;
            final lastMessage = chat['lastMessage'];
            final isMe = chat['lastMessageSender'] == currentUserId;
            final timestamp = chat['lastMessageTime'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(partnerId)
                  .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Unknown user'),
                  );
                }

                final partnerData = userSnap.data!.data() as Map<String, dynamic>;
                final partnerEmail = partnerData['email'] ?? 'Unknown Email';
                final partnerName = partnerData['name'] ?? partnerEmail.split('@').first;
                final partnerProfilePic = partnerData['profile_pic'] as String?;


                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: partnerProfilePic != null && partnerProfilePic.isNotEmpty
                        ? NetworkImage(partnerProfilePic) as ImageProvider
                        : const AssetImage('assets/default_avatar.png'), // Use default avatar
                  ),
                  title: Text(partnerName),
                  subtitle: Text(
                    isMe ? 'You: $lastMessage' : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTime(timestamp?.toDate()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        currentUserId: currentUserId,
                        otherUserId: partnerId,
                        otherEmail: partnerEmail, // Still passing email for title
                        otherUserName: partnerName,
                        otherUserProfilePic: partnerProfilePic,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('email_search', arrayContains: searchQuery) // Search by email_search array
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Exclude the current user from search results
          return data['email'] != currentUser.email &&
              doc.id != currentUserId;
        }).toList() ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No users found matching your search.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final email = user['email'] ?? 'No Email';
            final uid = users[index].id;
            final name = user['name'] ?? email.split('@').first;
            final profilePic = user['profile_pic'] as String?;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: profilePic != null && profilePic.isNotEmpty
                    ? NetworkImage(profilePic) as ImageProvider
                    : const AssetImage('assets/default_avatar.png'),
              ),
              title: Text(name),
              subtitle: Text(email),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    currentUserId: currentUserId,
                    otherUserId: uid,
                    otherEmail: email,
                    otherUserName: name,
                    otherUserProfilePic: profilePic,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to a new screen to select a contact to chat with,
        // or clear the search bar and show it for new chat.
        // For now, we'll just clear the search bar to allow new chats.
        if (searchQuery.isNotEmpty) {
          setState(() {
            searchController.clear();
            searchQuery = '';
          });
        } else {
          // Potentially navigate to a "New Chat" screen or simply focus search
          _tabController.animateTo(0); // Go to chats tab
          FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
          // You might want to implement a dedicated "New Chat" screen here
          // where users can browse contacts or search to start a new chat.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Type an email in the search bar to start a new chat!')),
          );
        }
      },
      child: const Icon(Icons.message),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    // If message is from today, show time (e.g., 10:30 AM)
    if (DateTime.now().difference(time).inDays == 0) {
      return DateFormat('h:mm a').format(time);
    }
    // If message is from yesterday, show "Yesterday"
    else if (DateTime.now().difference(time).inDays == 1) {
      return 'Yesterday';
    }
    // If message is from within the last week, show weekday (e.g., Mon)
    else if (DateTime.now().difference(time).inDays < 7) {
      return DateFormat('EEE').format(time); // EEE for short weekday name
    }
    // Otherwise, show date (e.g., 12/07/2025)
    else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}