import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/startup_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/startup_repository.dart';

final startupRepositoryProvider = Provider<StartupRepository>((ref) => StartupRepository());

final verifiedStartupsProvider = StreamProvider<List<Startup>>((ref) {
  return ref.watch(startupRepositoryProvider).watchVerifiedStartups();
});

/// Startups belonging to the signed-in founder, including pending/rejected —
/// drives the founder's own dashboard so they can track verification status.
final myStartupsProvider = StreamProvider<List<Startup>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return Stream.value([]);
  return ref.watch(startupRepositoryProvider).watchMyStartups(profile.uid);
});

final startupByIdProvider = FutureProvider.family<Startup?, String>((ref, startupId) {
  return ref.watch(startupRepositoryProvider).fetchStartup(startupId);
});
