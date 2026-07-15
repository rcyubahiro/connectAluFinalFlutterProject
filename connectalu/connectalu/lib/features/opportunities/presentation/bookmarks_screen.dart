import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/opportunity_providers.dart';
import '../../../models/opportunity_model.dart';
import 'widgets/opportunity_card.dart';

final _bookmarkedOpportunitiesProvider =
    FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null || profile.savedOpportunityIds.isEmpty) return [];
  final repo = ref.watch(opportunityRepositoryProvider);
  final results = await Future.wait(
    profile.savedOpportunityIds.map((id) => repo.fetchById(id)),
  );
  return results.whereType<Opportunity>().toList();
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(_bookmarkedOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved opportunities')),
      body: bookmarksAsync.when(
        data: (opps) {
          if (opps.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No saved opportunities yet.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: opps.length,
            itemBuilder: (_, i) => OpportunityCard(opportunity: opps[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
