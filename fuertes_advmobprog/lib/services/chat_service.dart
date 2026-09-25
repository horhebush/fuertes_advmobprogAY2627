import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

// Reads the user list and the messages between two accounts out of Firestore.
class ChatService {
  // Getters rather than fields, for the same reason as in UserService: a field
  // initialiser would run at construction and throw before initializeApp.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  // ENHANCEMENT 1: every registered user except whoever is signed in.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUid = _firebaseAuth.currentUser?.uid;

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid)
          // The document id is the uid, so it is correct even for a profile
          // written before the uid field was stored.
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();
    });
  }

  // Sorting the two ids means both people land in the same room.
  String chatRoomId(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return ids.join('_');
  }

  // Writes a message into the room the two accounts share.
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUserId = _firebaseAuth.currentUser!.uid;
    final currentUserEmail = _firebaseAuth.currentUser!.email;

    final newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(currentUserId, receiverId))
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Live feed of that room, newest message last.
  Stream<QuerySnapshot> getMessage(String userId, String otherUserId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId(userId, otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Looks up an account by its email address.
  Future<String?> getUidByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }
}
