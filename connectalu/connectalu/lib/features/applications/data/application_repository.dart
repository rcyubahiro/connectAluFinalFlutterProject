import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/application_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _db;
  ApplicationRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _apps => _db.collection('applications');

  /// applications is a top-level collection (not nested under opportunities)
  /// specifically so "all of my applications" is a single indexed query
  /// instead of a collection-group scan across every opportunity doc.
  Stream<List<Application>> watchMyApplications(String studentId) {
    return _apps
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Application.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Application>> watchApplicantsForOpportunity(String opportunityId) {
    return _apps
        .where('opportunityId', isEqualTo: opportunityId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Application.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<bool> hasApplied(String opportunityId, String studentId) async {
    final snap = await _apps
        .where('opportunityId', isEqualTo: opportunityId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Wrapped in a transaction alongside the opportunity's applicantCount
  /// bump, so the counter can never drift from actual application docs
  /// even under concurrent submissions.
  Future<void> submitApplication(Application application) async {
    await _db.runTransaction((tx) async {
      final appRef = _apps.doc();
      final oppRef = _db.collection('opportunities').doc(application.opportunityId);
      final oppSnap = await tx.get(oppRef);
      final currentCount = (oppSnap.data()?['applicantCount'] ?? 0) as int;

      tx.set(appRef, application.toMap());
      tx.update(oppRef, {'applicantCount': currentCount + 1});
    });
  }

  Future<void> updateStatus(String applicationId, ApplicationStatus newStatus) async {
    await _apps.doc(applicationId).update({
      'status': newStatus.name,
      'statusHistory': FieldValue.arrayUnion([
        StatusEvent(status: newStatus, timestamp: DateTime.now()).toMap(),
      ]),
    });
  }

  Future<void> scheduleInterview(
      String applicationId, DateTime scheduledAt) async {
    await _apps.doc(applicationId).update({
      'interviewScheduledAt': Timestamp.fromDate(scheduledAt),
      'status': ApplicationStatus.interview.name,
      'statusHistory': FieldValue.arrayUnion([
        StatusEvent(
                status: ApplicationStatus.interview,
                timestamp: DateTime.now())
            .toMap(),
      ]),
    });
  }
}
