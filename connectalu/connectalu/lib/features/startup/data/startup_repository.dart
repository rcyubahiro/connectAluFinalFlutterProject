import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../models/startup_model.dart';

class StartupRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  StartupRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _startups => _db.collection('startups');

  /// Only verified startups are visible in general discovery contexts
  /// (e.g. "choose which startup you're viewing"). Enforced again in
  /// Firestore security rules — this query-side filter is a UX nicety,
  /// not the security boundary.
  Stream<List<Startup>> watchVerifiedStartups() {
    return _startups
        .where('verificationStatus', isEqualTo: VerificationStatus.verified.name)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Startup.fromMap(d.id, d.data())).toList());
  }

  /// A founder's own startups regardless of verification state, so they
  /// can see "pending" / "rejected" status on their own dashboard.
  Stream<List<Startup>> watchMyStartups(String founderId) {
    return _startups
        .where('founderIds', arrayContains: founderId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Startup.fromMap(d.id, d.data())).toList());
  }

  Future<Startup?> fetchStartup(String startupId) async {
    final doc = await _startups.doc(startupId).get();
    if (!doc.exists) return null;
    return Startup.fromMap(doc.id, doc.data()!);
  }

  Future<String> uploadVerificationDoc(String startupId, File file) async {
    final ref = _storage.ref('startup_verification/$startupId/${const Uuid().v4()}');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadLogo(String startupId, File file) async {
    final ref = _storage.ref('startup_logos/$startupId.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> createStartup({
    required String founderId,
    required String name,
    required String tagline,
    required String description,
    required List<String> verificationDocUrls,
    String? logoUrl,
  }) async {
    final doc = await _startups.add({
      'name': name,
      'tagline': tagline,
      'description': description,
      'logoUrl': logoUrl,
      'founderIds': [founderId],
      // Always created pending. Verification flips this via a Cloud
      // Function (admin-only), never directly from the client.
      'verificationStatus': VerificationStatus.pending.name,
      'verificationDocUrls': verificationDocUrls,
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  /// Admin-side action. In production this should be a callable Cloud
  /// Function (see functions/reviewStartup.js in this scaffold) so that
  /// the custom auth claim gets minted server-side. Exposed here too for
  /// completeness / local development against emulators.
  Future<void> setVerificationStatus(
    String startupId,
    VerificationStatus status, {
    String? rejectionReason,
  }) async {
    await _startups.doc(startupId).update({
      'verificationStatus': status.name,
      'rejectionReason': rejectionReason,
    });
  }
}
