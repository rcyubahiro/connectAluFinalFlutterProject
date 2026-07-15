import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db;
  NotificationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Stream<List<AppNotification>> watchForUser(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> markRead(String notificationId) async {
    await _col.doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _col
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
