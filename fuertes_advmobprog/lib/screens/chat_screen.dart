import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/chat_service.dart';

// widgets
import '../widgets/custom_text.dart';

import 'chat_detail_screen.dart';

// ENHANCEMENT 1 and 2: the list of people to chat with, with a search box.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ENHANCEMENT 2: matches the typed text against the name, username or email.
  bool _matches(Map<String, dynamic> user) {
    if (_searchText.isEmpty) return true;

    final needle = _searchText.toLowerCase();
    final haystack = [
      user['firstName'],
      user['lastName'],
      user['username'],
      user['email'],
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(needle);
  }

  // The initial shown in the avatar, or a question mark for a blank name.
  String _initial(Map<String, dynamic> user) {
    final name = (user['firstName'] ?? user['username'] ?? '').toString();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                onChanged: (value) => setState(() => _searchText = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(Icons.search, size: 20.sp),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: Icon(Icons.cancel, size: 20.sp),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _Empty(
                      icon: Icons.error_outline,
                      text: 'Could not load the user list.',
                    );
                  }

                  final users = (snapshot.data ?? []).where(_matches).toList();

                  if (users.isEmpty) {
                    return _Empty(
                      icon: _searchText.isEmpty
                          ? Icons.person_off_outlined
                          : Icons.search_off,
                      text: _searchText.isEmpty
                          ? 'No one else has signed up yet.'
                          : 'No one matches "$_searchText".',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final name = [user['firstName'], user['lastName']]
                          .whereType<String>()
                          .join(' ')
                          .trim();

                      return Card(
                        margin: EdgeInsets.only(bottom: 8.h),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: CustomText(
                              text: _initial(user),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          title: CustomText(
                            text: name.isEmpty
                                ? (user['username'] ?? 'Unknown').toString()
                                : name,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle: CustomText(
                            text: (user['email'] ?? 'No email').toString(),
                            fontSize: 11.sp,
                            color: scheme.onSurfaceVariant,
                          ),
                          trailing: Icon(Icons.chevron_right, size: 20.sp),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(tappedUser: user),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared placeholder for the loading, error and no-results states.
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40.sp, color: scheme.onSurfaceVariant),
          SizedBox(height: 10.h),
          CustomText(
            text: text,
            fontSize: 13.sp,
            color: scheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
