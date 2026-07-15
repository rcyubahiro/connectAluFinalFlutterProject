import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/startup_providers.dart';
import '../../opportunities/providers/opportunity_providers.dart';
import '../../opportunities/presentation/widgets/opportunity_card.dart';

class StartupProfileScreen extends ConsumerWidget {
  final String startupId;
  const StartupProfileScreen({super.key, required this.startupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupAsync = ref.watch(startupByIdProvider(startupId));
    final opportunitiesAsync =
        ref.watch(opportunitiesByStartupProvider(startupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Startup profile')),
      body: startupAsync.when(
        data: (startup) {
          if (startup == null) {
            return const Center(child: Text('Startup not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: startup.logoUrl != null
                        ? CachedNetworkImageProvider(startup.logoUrl!)
                        : null,
                    child: startup.logoUrl == null
                        ? const Icon(Icons.storefront)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(startup.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            if (startup.isVerified)
                              const Icon(Icons.verified,
                                  color: AppTheme.success, size: 18),
                          ],
                        ),
                        Text(startup.tagline,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(startup.description),
              const SizedBox(height: 24),
              Text('Open opportunities',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              opportunitiesAsync.when(
                data: (opps) => opps.isEmpty
                    ? Text('No open opportunities right now.',
                        style: TextStyle(color: Colors.grey.shade600))
                    : Column(
                        children: opps
                            .map((o) => OpportunityCard(opportunity: o))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load opportunities: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
