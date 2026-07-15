import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/opportunity_model.dart';
import '../../../auth/providers/auth_providers.dart';

class OpportunityCard extends ConsumerWidget {
  final Opportunity opportunity;
  const OpportunityCard({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final saved =
        profile?.savedOpportunityIds.contains(opportunity.id) ?? false;

    return GestureDetector(
      onTap: () => context.push('/opportunities/${opportunity.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _logoColor(opportunity.startupName)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: opportunity.startupLogoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: opportunity.startupLogoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.storefront_outlined,
                      color: _logoColor(opportunity.startupName), size: 24),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opportunity.startupName,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _commitmentLabel(opportunity.commitment),
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12),
                      ),
                      if (opportunity.location.isNotEmpty) ...[
                        Text('  •  ',
                            style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 12)),
                        Text(
                          opportunity.location,
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Bookmark
            GestureDetector(
              onTap: () => ref
                  .read(authControllerProvider.notifier)
                  .toggleSavedOpportunity(opportunity.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? AppTheme.primary : Colors.grey.shade300,
                  size: 22,
                ),
              ),
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

  Color _logoColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF3B82F6),
      const Color(0xFF2E9E5B),
      const Color(0xFFFF6584),
      const Color(0xFFF97316),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
