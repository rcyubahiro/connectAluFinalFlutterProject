import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, verified, rejected }

VerificationStatus verificationFromString(String value) {
  return VerificationStatus.values.firstWhere(
    (v) => v.name == value,
    orElse: () => VerificationStatus.pending,
  );
}

class Startup {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String? logoUrl;
  final List<String> founderIds;
  final VerificationStatus verificationStatus;
  final List<String> verificationDocUrls;
  final String? rejectionReason;
  final DateTime createdAt;

  Startup({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    this.logoUrl,
    required this.founderIds,
    required this.verificationStatus,
    this.verificationDocUrls = const [],
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory Startup.fromMap(String id, Map<String, dynamic> map) {
    return Startup(
      id: id,
      name: map['name'] ?? '',
      tagline: map['tagline'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      founderIds: List<String>.from(map['founderIds'] ?? const []),
      verificationStatus: verificationFromString(map['verificationStatus'] ?? 'pending'),
      verificationDocUrls: List<String>.from(map['verificationDocUrls'] ?? const []),
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tagline': tagline,
      'description': description,
      'logoUrl': logoUrl,
      'founderIds': founderIds,
      'verificationStatus': verificationStatus.name,
      'verificationDocUrls': verificationDocUrls,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
