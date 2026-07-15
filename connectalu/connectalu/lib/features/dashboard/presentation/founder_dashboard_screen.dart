import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/application_model.dart';
import '../../../models/startup_model.dart';
import '../../applications/providers/application_providers.dart';
import '../../opportunities/presentation/post_opportunity_screen.dart';
import '../../opportunities/providers/opportunity_providers.dart';
import '../../startup/presentation/create_startup_screen.dart';
import '../../startup/providers/startup_providers.dart';

/// Founder's home base: startup verification status, their postings, and
/// a lightweight applicant funnel per opportunity (submitted → interview →
/// accepted). This is the piece that demonstrates "scalability thinking" —
/// counts are read off denormalized applicantCount + a cheap client-side
/// tally rather than an expensive aggregation query.
class FounderDashboardScreen extends ConsumerWidget {
  const FounderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupsAsync = ref.watch(myStartupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My startups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateStartupScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New startup'),
      ),
      body: startupsAsync.when(
        data: (startups) {
          if (startups.isEmpty) {
            return const Center(
                child: Text('Register your first startup to get started.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: startups.length,
            itemBuilder: (_, i) => _StartupSection(startup: startups[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StartupSection extends ConsumerWidget {
  final Startup startup;
  const _StartupSection({required this.startup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppsAsync = ref.watch(myStartupOpportunitiesProvider(startup.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(startup.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _VerificationBadge(status: startup.verificationStatus),
            ],
          ),
          const SizedBox(height: 12),
          if (startup.isVerified)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => PostOpportunityScreen(startup: startup)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Post an opportunity'),
            )
          else if (startup.verificationStatus == VerificationStatus.pending)
            Text('Your startup is under review. You can post once verified.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
          else
            Text(
                'Verification was declined: ${startup.rejectionReason ?? "no reason given"}',
                style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          const SizedBox(height: 16),
          oppsAsync.when(
            data: (opps) {
              if (opps.isEmpty) return const SizedBox.shrink();
              return Column(
                children: opps
                    .map((opp) => _OpportunityFunnelTile(
                          opportunityId: opp.id,
                          title: opp.title,
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _OpportunityFunnelTile extends ConsumerWidget {
  final String opportunityId;
  final String title;
  const _OpportunityFunnelTile(
      {required this.opportunityId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync =
        ref.watch(applicantsForOpportunityProvider(opportunityId));

    return InkWell(
      onTap: () => context.push(
          '/founder/opportunities/$opportunityId/applicants',
          extra: title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            applicantsAsync.when(
              data: (apps) {
                final submitted = apps.length;
                final interview = apps
                    .where((a) => a.status == ApplicationStatus.interview)
                    .length;
                final accepted = apps
                    .where((a) => a.status == ApplicationStatus.accepted)
                    .length;
                return Row(
                  children: [
                    _FunnelStat(label: 'Applied', value: submitted),
                    const SizedBox(width: 16),
                    _FunnelStat(label: 'Interview', value: interview),
                    const SizedBox(width: 16),
                    _FunnelStat(label: 'Accepted', value: accepted),
                  ],
                );
              },
              loading: () => const SizedBox(height: 20),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FunnelStat extends StatelessWidget {
  final String label;
  final int value;
  const _FunnelStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case VerificationStatus.verified:
        return const StatusChip(label: 'Verified', color: AppTheme.success);
      case VerificationStatus.pending:
        return const StatusChip(label: 'Pending review', color: Colors.orange);
      case VerificationStatus.rejected:
        return const StatusChip(label: 'Rejected', color: AppTheme.danger);
    }
  }
}
