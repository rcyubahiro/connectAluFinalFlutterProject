import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/opportunity_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../providers/opportunity_providers.dart';
import 'widgets/opportunity_card.dart';

class OpportunityFeedScreen extends ConsumerWidget {
  const OpportunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final feedAsync = ref.watch(rankedOpportunityFeedProvider);
    final firstName = profile?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $firstName 👋',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Find meaningful ways to contribute.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const NotificationBell(),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.go('/account'),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        backgroundImage: profile?.photoUrl != null
                            ? CachedNetworkImageProvider(profile!.photoUrl!)
                            : null,
                        child: profile?.photoUrl == null
                            ? Text(
                                firstName.isNotEmpty ? firstName[0] : '?',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  color: Colors.grey.shade400, size: 20),
                              const SizedBox(width: 10),
                              Text('Search opportunities...',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: Colors.grey.shade600, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // ── Feed (async) ──
            SliverToBoxAdapter(
              child: feedAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Could not load opportunities',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('Check your connection and try again',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                ),
                data: (opps) => _FeedContent(opps: opps),
              ),
            ),

            // ── Browse by category ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Text('Browse by category',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryRow()),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Feed content (recommended card + recent list) ──
class _FeedContent extends ConsumerWidget {
  final List<Opportunity> opps;
  const _FeedContent({required this.opps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (opps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No opportunities yet',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recommended',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              GestureDetector(
                onTap: () => GoRouter.of(context).push('/search'),
                child: const Text('See all',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        // Featured card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _FeaturedCard(opportunity: opps.first),
        ),
        // Recent opportunities header
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Text('Recent opportunities',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
        ),
        // List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: opps.map((o) => OpportunityCard(opportunity: o)).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Featured gradient card ──
class _FeaturedCard extends ConsumerWidget {
  final Opportunity opportunity;
  const _FeaturedCard({required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final saved =
        profile?.savedOpportunityIds.contains(opportunity.id) ?? false;

    return GestureDetector(
      onTap: () => context.push('/opportunities/${opportunity.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B4B), Color(0xFF1A3A8F), Color(0xFFE8401C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1B4B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opportunity.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(authControllerProvider.notifier)
                      .toggleSavedOpportunity(opportunity.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 5),
                Text(opportunity.startupName,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: opportunity.skillsRequired.take(3).map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _commitmentLabel(opportunity.commitment),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(opportunity.createdAt),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _commitmentLabel(CommitmentType c) {
    switch (c) {
      case CommitmentType.partTime:
        return 'Part-time';
      case CommitmentType.projectBased:
        return 'Project-based';
      case CommitmentType.flexible:
        return 'Flexible';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'Posted ${diff.inDays}d ago';
    if (diff.inHours > 0) return 'Posted ${diff.inHours}h ago';
    return 'Just posted';
  }
}

// ── Category row ──
class _CategoryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = [
      (OpportunityCategory.design, Icons.design_services_outlined, 'Design',
          const Color(0xFFEEF0F8), const Color(0xFF0D1B4B)),
      (OpportunityCategory.engineering, Icons.people_outline, 'Engineering',
          const Color(0xFFEFF6FF), const Color(0xFF1A3A8F)),
      (OpportunityCategory.marketing, Icons.campaign_outlined, 'Marketing',
          const Color(0xFFFFF0ED), const Color(0xFFE8401C)),
      (OpportunityCategory.research, Icons.bar_chart_outlined, 'Data',
          const Color(0xFFEFFAF4), const Color(0xFF2E9E5B)),
      (OpportunityCategory.operations, Icons.more_horiz, 'Other',
          const Color(0xFFFFF4EF), const Color(0xFFF97316)),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final (cat, icon, label, bg, fg) = cats[i];
          return GestureDetector(
            onTap: () {
              ref.read(categoryFilterProvider.notifier).state = cat;
              context.push('/search');
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: fg, size: 24),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}
