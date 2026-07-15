import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, founder, admin }

/// Returns null for missing/unrecognized values rather than defaulting to
/// student — the router relies on `role == null` to detect "hasn't
/// completed onboarding yet" (see AuthRepository.createInitialProfile,
/// which writes `role: null` at signup).
UserRole? userRoleFromString(String? value) {
  if (value == null) return null;
  for (final r in UserRole.values) {
    if (r.name == value) return r;
  }
  return null;
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole? role;

  // Student-only fields. Kept nullable rather than splitting into a
  // separate collection — the profile is small and always read together,
  // so a single document avoids an extra round trip on every profile view.
  final List<String> skills;
  final String? bio;
  final List<String> portfolioLinks;
  final String? resumeUrl;
  final List<String> savedOpportunityIds;

  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role,
    this.skills = const [],
    this.bio,
    this.portfolioLinks = const [],
    this.resumeUrl,
    this.savedOpportunityIds = const [],
    required this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      role: userRoleFromString(map['role'] as String?),
      skills: List<String>.from(map['skills'] ?? const []),
      bio: map['bio'],
      portfolioLinks: List<String>.from(map['portfolioLinks'] ?? const []),
      resumeUrl: map['resumeUrl'],
      savedOpportunityIds: List<String>.from(map['savedOpportunityIds'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role?.name,
      'skills': skills,
      'bio': bio,
      'portfolioLinks': portfolioLinks,
      'resumeUrl': resumeUrl,
      'savedOpportunityIds': savedOpportunityIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    List<String>? skills,
    String? bio,
    List<String>? portfolioLinks,
    String? resumeUrl,
    List<String>? savedOpportunityIds,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      savedOpportunityIds: savedOpportunityIds ?? this.savedOpportunityIds,
      createdAt: createdAt,
    );
  }
}
