import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/application_model.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/presentation/chat_screen.dart';
import '../providers/application_providers.dart';

/// Founder's view of everyone who applied to a given opportunity. Status
/// changes here are what drives the student-facing timeline in
/// MyApplicationsScreen — same document, two views.
class ApplicantListScreen extends ConsumerWidget {
  final String opportunityId;
  final String opportunityTitle;
  const ApplicantListScreen(
      {super.key, required this.opportunityId, required this.opportunityTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync =
        ref.watch(applicantsForOpportunityProvider(opportunityId));

    return Scaffold(
      appBar: AppBar(title: Text('Applicants — $opportunityTitle')),
      body: applicantsAsync.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text('No applicants yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ApplicantTile(application: apps[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ApplicantTile extends ConsumerWidget {
  final Application application;
  const _ApplicantTile({required this.application});

  Future<void> _pickInterviewTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    final scheduled =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ref
        .read(applicationRepositoryProvider)
        .scheduleInterview(application.id, scheduled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Interview scheduled for ${DateFormat('MMM d, h:mm a').format(scheduled)}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Messaging only unlocks once a founder has moved a candidate to the
    // interview stage — keeps chat scoped to serious conversations rather
    // than becoming a general-purpose inbox.
    final canMessage = application.status == ApplicationStatus.interview ||
        application.status == ApplicationStatus.accepted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(application.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              StatusChip(
                label: application.status.name,
                color: application.status == ApplicationStatus.rejected
                    ? AppTheme.danger
                    : AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(application.coverNote,
              maxLines: 3, overflow: TextOverflow.ellipsis),
          if (application.interviewScheduledAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Interview: ${DateFormat('MMM d, h:mm a').format(application.interviewScheduledAt!)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ApplicationStatus>(
                  initialValue: application.status,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Update status'),
                  items: ApplicationStatus.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (newStatus) async {
                    if (newStatus == null) return;
                    if (newStatus == ApplicationStatus.interview) {
                      await _pickInterviewTime(context, ref);
                    } else {
                      ref
                          .read(applicationRepositoryProvider)
                          .updateStatus(application.id, newStatus);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    color:
                        canMessage ? AppTheme.primary : Colors.grey.shade300),
                onPressed: canMessage
                    ? () async {
                        final chatId = await ref
                            .read(chatRepositoryProvider)
                            .getOrCreateThread(
                              otherUserId: application.studentId,
                              otherUserName: application.studentName,
                              opportunityId: application.opportunityId,
                              opportunityTitle: application.opportunityTitle,
                            );
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  otherUserName: application.studentName),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
