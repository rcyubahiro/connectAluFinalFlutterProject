import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/startup_providers.dart';

/// Founders fill this out to register a startup. It's created in
/// `pending` state and stays invisible to students until an admin
/// approves it — see StartupRepository.createStartup / setVerificationStatus.
class CreateStartupScreen extends ConsumerStatefulWidget {
  const CreateStartupScreen({super.key});

  @override
  ConsumerState<CreateStartupScreen> createState() =>
      _CreateStartupScreenState();
}

class _CreateStartupScreenState extends ConsumerState<CreateStartupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _verificationDoc;
  bool _submitting = false;

  Future<void> _pickDoc() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _verificationDoc = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please attach proof of ALU affiliation.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(startupRepositoryProvider);
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) return;

      // Startup doc needs an id before we can namespace the storage path,
      // so create it first with an empty doc list, then patch in the URL.
      // (In a production build this would be wrapped in a single Cloud
      // Function to avoid the brief window with no verification doc.)
      final startupId = await repo.createStartup(
        founderId: profile.uid,
        name: _nameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        verificationDocUrls: [],
      );
      await repo.uploadVerificationDoc(startupId, _verificationDoc!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Startup submitted for verification!')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register your startup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _InfoBanner(
                text:
                    'Your startup will be reviewed before it appears to students. '
                    "This keeps the platform trustworthy for everyone.",
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Startup name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taglineCtrl,
                decoration:
                    const InputDecoration(labelText: 'One-line tagline'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'What does your startup do?'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDoc,
                icon: const Icon(Icons.upload_file),
                label: Text(_verificationDoc == null
                    ? 'Attach proof of ALU affiliation'
                    : 'Document attached ✓'),
              ),
              const SizedBox(height: 4),
              Text(
                'E.g. club registration, staff endorsement letter, or Innovation Hub confirmation.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    : const Text('Submit for review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
