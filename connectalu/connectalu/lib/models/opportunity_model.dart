import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityCategory {
  engineering,
  design,
  marketing,
  operations,
  research,
  businessAnalysis,
  contentCreation,
  communityManagement,
}

enum OpportunityStatus { open, closed, filled }

enum CommitmentType { partTime, projectBased, flexible }

T _enumFromString<T>(List<T> values, String value, T fallback) {
  return values.firstWhere(
    (v) => (v as dynamic).name == value,
    orElse: () => fallback,
  );
}

class Opportunity {
  final String id;
  final String startupId;
  final String startupName; // denormalized for fast list rendering
  final String? startupLogoUrl; // denormalized
  final String title;
  final String description;
  final OpportunityCategory category;
  final List<String> skillsRequired;
  final CommitmentType commitment;
  final String location;
  final OpportunityStatus status;
  final int applicantCount;
  final DateTime createdAt;
  final DateTime? deadline;

  Opportunity({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.skillsRequired,
    required this.commitment,
    this.location = '',
    required this.status,
    this.applicantCount = 0,
    required this.createdAt,
    this.deadline,
  });

  /// Simple client-side relevance score against a student's declared skills.
  /// Used to rank the discovery feed — see OpportunityFeedScreen.
  int matchScore(List<String> studentSkills) {
    final normalizedRequired = skillsRequired.map((s) => s.toLowerCase()).toSet();
    final normalizedStudent = studentSkills.map((s) => s.toLowerCase()).toSet();
    return normalizedRequired.intersection(normalizedStudent).length;
  }

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      startupId: map['startupId'] ?? '',
      startupName: map['startupName'] ?? '',
      startupLogoUrl: map['startupLogoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: _enumFromString(
          OpportunityCategory.values, map['category'] ?? 'engineering', OpportunityCategory.engineering),
      skillsRequired: List<String>.from(map['skillsRequired'] ?? const []),
      commitment: _enumFromString(
          CommitmentType.values, map['commitment'] ?? 'flexible', CommitmentType.flexible),
      location: map['location'] ?? '',
      status: _enumFromString(OpportunityStatus.values, map['status'] ?? 'open', OpportunityStatus.open),
      applicantCount: map['applicantCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'startupLogoUrl': startupLogoUrl,
      'title': title,
      'description': description,
      'category': category.name,
      'skillsRequired': skillsRequired,
      'commitment': commitment.name,
      'location': location,
      'status': status.name,
      'applicantCount': applicantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
    };
  }
}
