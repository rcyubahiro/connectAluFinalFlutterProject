import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/application_model.dart';
import '../data/application_repository.dart';

final applicationRepositoryProvider =
    Provider<ApplicationRepository>((ref) => ApplicationRepository());

final myApplicationsProvider = StreamProvider.family<List<Application>, String>((ref, studentId) {
  return ref.watch(applicationRepositoryProvider).watchMyApplications(studentId);
});

final applicantsForOpportunityProvider =
    StreamProvider.family<List<Application>, String>((ref, opportunityId) {
  return ref.watch(applicationRepositoryProvider).watchApplicantsForOpportunity(opportunityId);
});

/// Keyed by a record so the UI can ask "has this student already applied
/// to this opportunity" — drives the disabled "Apply" button.
final hasAppliedProvider =
    FutureProvider.family<bool, ({String opportunityId, String studentId})>((ref, args) {
  return ref
      .watch(applicationRepositoryProvider)
      .hasApplied(args.opportunityId, args.studentId);
});
