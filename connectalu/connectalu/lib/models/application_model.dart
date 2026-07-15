import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { submitted, inReview, interview, accepted, rejected }

ApplicationStatus applicationStatusFromString(String value) {
  return ApplicationStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ApplicationStatus.submitted,
  );
}

class StatusEvent {
  final ApplicationStatus status;
  final DateTime timestamp;

  StatusEvent({required this.status, required this.timestamp});

  factory StatusEvent.fromMap(Map<String, dynamic> map) {
    return StatusEvent(
      status: applicationStatusFromString(map['status']),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class Application {
  final String id;
  final String opportunityId;
  final String opportunityTitle; // denormalized
  final String startupId;
  final String startupName; // denormalized
  final String studentId;
  final String studentName; // denormalized
  final ApplicationStatus status;
  final String coverNote;
  final String? resumeSnapshotUrl;
  final List<StatusEvent> statusHistory;
  final DateTime createdAt;
  final DateTime? interviewScheduledAt;

  Application({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupId,
    required this.startupName,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.coverNote,
    this.resumeSnapshotUrl,
    required this.statusHistory,
    required this.createdAt,
    this.interviewScheduledAt,
  });

  factory Application.fromMap(String id, Map<String, dynamic> map) {
    return Application(
      id: id,
      opportunityId: map['opportunityId'] ?? '',
      opportunityTitle: map['opportunityTitle'] ?? '',
      startupId: map['startupId'] ?? '',
      startupName: map['startupName'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      status: applicationStatusFromString(map['status'] ?? 'submitted'),
      coverNote: map['coverNote'] ?? '',
      resumeSnapshotUrl: map['resumeSnapshotUrl'],
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      interviewScheduledAt:
          (map['interviewScheduledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'opportunityTitle': opportunityTitle,
      'startupId': startupId,
      'startupName': startupName,
      'studentId': studentId,
      'studentName': studentName,
      'status': status.name,
      'coverNote': coverNote,
      'resumeSnapshotUrl': resumeSnapshotUrl,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'interviewScheduledAt': interviewScheduledAt == null
          ? null
          : Timestamp.fromDate(interviewScheduledAt!),
    };
  }
}
