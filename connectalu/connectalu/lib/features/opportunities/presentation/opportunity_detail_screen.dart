import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../applications/presentation/apply_screen.dart';
import '../../applications/providers/application_providers.dart';
import '../providers/opportunity_providers.dart';
import '../../../models/opportunity_model.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  final String opportunityId;
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppAsync = ref.watch(opportunityByIdProvider(opportunityId));
    final profile = ref.watch(userProfileProvider).value;
    final alreadyAppliedAsync = profile == null
        ? const AsyncValue.data(false)
        : ref.watch(hasAppliedProvider(
            (opportunityId: opportunityId, studentId: profile.uid)));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Opportunity Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: oppAsync.when(
        data: (opp) {
          if (opp == null) {
            return const Center(child: Text('Opportunity not found.'));
          }
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opp.title,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/startups/${opp.startupId}'),
                                  child: Text(opp.startupName,
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Skill chips ──
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.skillsRequired
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: Text(s,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Meta info ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _MetaRow(
                            icon: Icons.schedule_outlined,
                            text: _commitmentLabel(opp.commitment),
                          ),
                          const Divider(height: 20),
                          _MetaRow(
                            icon: Icons.category_outlined,
                            text: opp.category.name,
                          ),
                          const Divider(height: 20),
                          _MetaRow(
                            icon: Icons.people_outline,
                            text: '${opp.applicantCount} applicants',
                          ),
                          if (opp.deadline != null) ...[
                            const Divider(height: 20),
                            _MetaRow(
                              icon: Icons.event_outlined,
                              text:
                                  'Deadline: ${_formatDate(opp.deadline!)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── About ──
                    const Text('About',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(opp.description,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                            fontSize: 13)),
                    const SizedBox(height: 20),

                    // ── Skills required ──
                    const Text('Skills required',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.skillsRequired
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(s,
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // ── Apply button pinned at bottom ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  color: AppTheme.surfaceLight,
                  child: alreadyAppliedAsync.when(
                    data: (applied) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: applied || opp.status != OpportunityStatus.open
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ApplyScreen(opportunity: opp)),
                                ),
                        child: Text(applied
                            ? 'Already applied'
                            : opp.status != OpportunityStatus.open
                                ? 'Closed'
                                : 'Apply Now'),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _commitmentLabel(CommitmentType c) {
    switch (c) {
      case CommitmentType.partTime:
        return 'Part-time (8–10 hrs/week)';
      case CommitmentType.projectBased:
        return 'Project-based';
      case CommitmentType.flexible:
        return 'Flexible hours';
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }
}
