import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  ChatRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _threads => _db.collection('chats');

  Stream<List<ChatThread>> watchMyThreads(String uid) {
    return _threads
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatThread.fromMap(d.id, d.data())).toList());
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _threads
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  /// Finds an existing thread between the two participants scoped to this
  /// opportunity, or creates one. Deterministic id (sorted uid pair +
  /// opportunity) avoids duplicate threads from double-taps/races.
  Future<String> getOrCreateThread({
    required String otherUserId,
    required String otherUserName,
    required String opportunityId,
    required String opportunityTitle,
  }) async {
    final me = _auth.currentUser!;
    final ids = [me.uid, otherUserId]..sort();
    final chatId = '${ids[0]}_${ids[1]}_$opportunityId';

    final doc = _threads.doc(chatId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set(ChatThread(
        id: chatId,
        participantIds: ids,
        participantNames: {
          me.uid: me.displayName ?? 'Me',
          otherUserId: otherUserName,
        },
        opportunityId: opportunityId,
        opportunityTitle: opportunityTitle,
      ).toMap());
    }
    return chatId;
  }

  Future<void> sendMessage(String chatId, String text) async {
    final me = _auth.currentUser!;
    final messageRef = _threads.doc(chatId).collection('messages').doc();
    await _db.runTransaction((tx) async {
      tx.set(messageRef, {
        'senderId': me.uid,
        'text': text,
        'timestamp': Timestamp.now(),
        'read': false,
      });
      tx.update(_threads.doc(chatId), {
        'lastMessage': text,
        'lastMessageAt': Timestamp.now(),
      });
    });
  }
}
