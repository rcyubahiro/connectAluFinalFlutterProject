import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/application_model.dart';
import '../../../models/opportunity_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/application_providers.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final Opportunity opportunity;
  const ApplyScreen({super.key, required this.opportunity});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _coverNoteCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;
    if (_coverNoteCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell them a bit more about why you\'re a good fit (20+ characters).')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(applicationRepositoryProvider).submitApplication(
            Application(
              id: '',
              opportunityId: widget.opportunity.id,
              opportunityTitle: widget.opportunity.title,
              startupId: widget.opportunity.startupId,
              startupName: widget.opportunity.startupName,
              studentId: profile.uid,
              studentName: profile.name,
              status: ApplicationStatus.submitted,
              coverNote: _coverNoteCtrl.text.trim(),
              resumeSnapshotUrl: profile.resumeUrl,
              statusHistory: [
                StatusEvent(status: ApplicationStatus.submitted, timestamp: DateTime.now()),
              ],
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Application submitted!')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply to ${widget.opportunity.title}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Why are you a good fit for this role at ${widget.opportunity.startupName}?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _coverNoteCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Share relevant experience, availability, and why this role excites you...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}
