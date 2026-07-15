import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/opportunity_model.dart';

class OpportunityRepository {
  final FirebaseFirestore _db;
  OpportunityRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _opps => _db.collection('opportunities');

  /// Main discovery feed. Filters by status only (no composite index needed).
  /// Category filtering happens client-side in the provider layer for simplicity
  /// and to avoid index creation overhead. The dataset per status is small enough.
  Stream<List<Opportunity>> watchOpenOpportunities({OpportunityCategory? category}) {
    // Single-field filter only — no composite index required.
    // Sorting and category filtering happen client-side.
    return _opps
        .where('status', isEqualTo: OpportunityStatus.open.name)
        .limit(100)
        .snapshots()
        .map((snap) {
      var opps = snap.docs.map((d) => Opportunity.fromMap(d.id, d.data())).toList();
      opps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (category != null) {
        opps = opps.where((o) => o.category == category).toList();
      }
      return opps;
    });
  }

  Stream<List<Opportunity>> watchByStartup(String startupId) {
    return _opps
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snap) {
          final opps = snap.docs.map((d) => Opportunity.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return opps.where((o) => o.status == OpportunityStatus.open).toList();
        });
  }

  /// All postings (any status) for a founder's own management view.
  Stream<List<Opportunity>> watchAllByStartupForFounder(String startupId) {
    return _opps
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snap) {
          final opps = snap.docs.map((d) => Opportunity.fromMap(d.id, d.data())).toList();
          opps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return opps;
        });
  }

  Future<Opportunity?> fetchById(String id) async {
    final doc = await _opps.doc(id).get();
    if (!doc.exists) return null;
    return Opportunity.fromMap(doc.id, doc.data()!);
  }

  Future<String> createOpportunity(Opportunity opportunity) async {
    final doc = await _opps.add(opportunity.toMap());
    return doc.id;
  }

  Future<void> updateStatus(String id, OpportunityStatus status) async {
    await _opps.doc(id).update({'status': status.name});
  }

  /// Called from within a transaction when an application is submitted,
  /// so concurrent applicants never race on the counter.
  Future<void> incrementApplicantCount(String opportunityId) async {
    await _db.runTransaction((tx) async {
      final ref = _opps.doc(opportunityId);
      final snap = await tx.get(ref);
      final current = (snap.data()?['applicantCount'] ?? 0) as int;
      tx.update(ref, {'applicantCount': current + 1});
    });
  }
}
