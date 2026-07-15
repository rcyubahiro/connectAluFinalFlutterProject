import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/application_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/application_providers.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  int _tabIndex = 0;

  static const _tabs = ['Applied', 'Interview', 'Accepted', 'All'];

  List<Application> _filter(List<Application> apps) {
    switch (_tabIndex) {
      case 0:
        return apps
            .where((a) =>
                a.status == ApplicationStatus.submitted ||
                a.status == ApplicationStatus.inReview)
            .toList();
      case 1:
        return apps
            .where((a) => a.status == ApplicationStatus.interview)
            .toList();
      case 2:
        return apps
            .where((a) => a.status == ApplicationStatus.accepted)
            .toList();
      default:
        return apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    final applicationsAsync = ref.watch(myApplicationsProvider(profile.uid));

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('My Applications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Tab bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _tabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey.shade200),
                    ),
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // ── List ──
          Expanded(
            child: applicationsAsync.when(
              data: (apps) {
                final filtered = _filter(apps);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No applications here yet.',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ApplicationCard(application: filtered[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application application;
  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);
    final statusLabel = _statusLabel(application.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.opportunityTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(application.startupName,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Applied ${_timeAgo(application.createdAt)}',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                    if (application.interviewScheduledAt != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.event,
                              size: 11, color: AppTheme.success),
                          const SizedBox(width: 2),
                          Text(
                            DateFormat('MMM d').format(
                                application.interviewScheduledAt!),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.inReview:
        return AppTheme.warning;
      case ApplicationStatus.interview:
        return AppTheme.primary;
      case ApplicationStatus.accepted:
        return AppTheme.success;
      case ApplicationStatus.rejected:
        return AppTheme.danger;
    }
  }

  String _statusLabel(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.inReview:
        return 'Under Review';
      case ApplicationStatus.interview:
        return 'Shortlisted';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Closed';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} week(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    return 'today';
  }
}
