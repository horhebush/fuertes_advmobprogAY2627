import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/chat_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: the message thread, redesigned.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.tappedUser});

  final Map<String, dynamic> tappedUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String? _currentUserId;
  bool _isSending = false;

  String get _otherUserId => (widget.tappedUser['uid'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // The thread needs both uids before it can find the room.
  Future<void> _loadCurrentUser() async {
    final userData = await UserService().getUserData();
    if (!mounted) return;
    setState(() => _currentUserId = (userData['uid'] ?? '').toString());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Sends what is typed, showing a sending state until Firestore accepts it.
  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(_otherUserId, text);
      _messageController.clear();
      _messageFocus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(text: 'Failed to send: $e', fontSize: 12.sp),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Keeps the newest message in view once the list has grown.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = [widget.tappedUser['firstName'], widget.tappedUser['lastName']]
        .whereType<String>()
        .join(' ')
        .trim();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: name.isEmpty
              ? (widget.tappedUser['username'] ?? 'Chat').toString()
              : name,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _currentUserId == null
                  ? const Center(child: CircularProgressIndicator())
                  : _messages(),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  // The live thread between the two accounts.
  Widget _messages() {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessage(_currentUserId!, _otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'Could not load the messages.',
              fontSize: 13.sp,
              color: scheme.onSurfaceVariant,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 38.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 10.h),
                CustomText(
                  text: 'No messages yet. Say hello.',
                  fontSize: 13.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        }

        _scrollToEnd();

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMine = data['senderId'] == _currentUserId;

            return _Bubble(
              text: (data['message'] ?? '').toString(),
              timestamp: data['timestamp'],
              isMine: isMine,
              // The last of my messages is the one still in flight.
              isSending: isMine && _isSending && index == docs.length - 1,
            );
          },
        );
      },
    );
  }

  // The text box and the send button.
  Widget _composer() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocus,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  color: scheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Swaps to a spinner while the message is on its way.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSending
                ? SizedBox(
                    key: const ValueKey('sending'),
                    width: 42.w,
                    height: 42.w,
                    child: Padding(
                      padding: EdgeInsets.all(10.r),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    key: const ValueKey('send'),
                    onPressed: _send,
                    icon: Icon(Icons.send, size: 20.sp),
                    tooltip: 'Send',
                  ),
          ),
        ],
      ),
    );
  }
}

// One chat bubble, which fades and slides in as it arrives.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isMine,
    required this.isSending,
    this.timestamp,
  });

  final String text;
  final bool isMine;
  final bool isSending;
  final dynamic timestamp;

  // 24-hour clock, because that is what the rest of the app uses.
  String get _time {
    if (timestamp is! Timestamp) return '';
    final date = (timestamp as Timestamp).toDate();
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((isMine ? 18 : -18) * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMine ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.r).copyWith(
              bottomRight: isMine ? Radius.zero : Radius.circular(16.r),
              bottomLeft: isMine ? Radius.circular(16.r) : Radius.zero,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: text.isEmpty ? '[empty]' : text,
                fontSize: 14.sp,
                color: isMine ? scheme.onPrimary : scheme.onSurface,
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: isSending ? 'sending...' : _time,
                    fontSize: 9.sp,
                    color: (isMine ? scheme.onPrimary : scheme.onSurfaceVariant)
                        .withValues(alpha: 0.75),
                  ),
                  // A tick once Firestore has the message.
                  if (isMine && !isSending) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.done_all,
                      size: 12.sp,
                      color: scheme.onPrimary.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
