import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/opportunity_model.dart';
import '../../../models/startup_model.dart';
import '../providers/opportunity_providers.dart';

/// Reached only from a verified startup's dashboard. As defense in depth,
/// this screen also re-checks `startup.isVerified` before allowing submit —
/// the real enforcement lives in Firestore security rules (an unverified
/// founder's write would be rejected server-side regardless of UI state).
class PostOpportunityScreen extends ConsumerStatefulWidget {
  final Startup startup;
  const PostOpportunityScreen({super.key, required this.startup});

  @override
  ConsumerState<PostOpportunityScreen> createState() =>
      _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends ConsumerState<PostOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  OpportunityCategory _category = OpportunityCategory.engineering;
  CommitmentType _commitment = CommitmentType.flexible;
  bool _submitting = false;

  Future<void> _submit() async {
    if (!widget.startup.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your startup must be verified before posting.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(opportunityRepositoryProvider).createOpportunity(
            Opportunity(
              id: '',
              startupId: widget.startup.id,
              startupName: widget.startup.name,
              startupLogoUrl: widget.startup.logoUrl,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              category: _category,
              skillsRequired: skills,
              commitment: _commitment,
              status: OpportunityStatus.open,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Opportunity posted!')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post an opportunity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Role title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Description & responsibilities'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skillsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Skills required (comma separated)',
                  hintText: 'Flutter, Figma, copywriting...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OpportunityCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: OpportunityCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CommitmentType>(
                initialValue: _commitment,
                decoration: const InputDecoration(labelText: 'Commitment type'),
                items: CommitmentType.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _commitment = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post opportunity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
