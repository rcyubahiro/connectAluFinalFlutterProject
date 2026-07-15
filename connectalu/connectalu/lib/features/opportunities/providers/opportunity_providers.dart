import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/opportunity_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/opportunity_repository.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) => OpportunityRepository());

/// Filter state for the discovery screen. A simple StateProvider is enough
/// here — this is UI-local filter state, not domain state, so it doesn't
/// need a full StateNotifier.
final categoryFilterProvider = StateProvider<OpportunityCategory?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final openOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  return ref.watch(opportunityRepositoryProvider).watchOpenOpportunities(category: category);
});

/// The "smart feed": takes the raw open-opportunities stream and re-ranks
/// it by overlap with the current student's declared skills, then applies
/// the free-text search filter on top. This is where the platform earns
/// its "matching" positioning instead of being a plain reverse-chron list.
final rankedOpportunityFeedProvider = Provider<AsyncValue<List<Opportunity>>>((ref) {
  final oppsAsync = ref.watch(openOpportunitiesProvider);
  final profile = ref.watch(userProfileProvider).value;
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return oppsAsync.whenData((opps) {
    var filtered = opps;
    if (query.isNotEmpty) {
      filtered = filtered
          .where((o) =>
              o.title.toLowerCase().contains(query) ||
              o.startupName.toLowerCase().contains(query) ||
              o.skillsRequired.any((s) => s.toLowerCase().contains(query)))
          .toList();
    }

    final studentSkills = profile?.skills ?? const [];
    if (studentSkills.isEmpty) return filtered;

    final ranked = [...filtered];
    ranked.sort((a, b) => b.matchScore(studentSkills).compareTo(a.matchScore(studentSkills)));
    return ranked;
  });
});

final opportunitiesByStartupProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, startupId) {
  return ref.watch(opportunityRepositoryProvider).watchByStartup(startupId);
});

final myStartupOpportunitiesProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, startupId) {
  return ref.watch(opportunityRepositoryProvider).watchAllByStartupForFounder(startupId);
});

final opportunityByIdProvider = FutureProvider.family<Opportunity?, String>((ref, id) {
  return ref.watch(opportunityRepositoryProvider).fetchById(id);
});
