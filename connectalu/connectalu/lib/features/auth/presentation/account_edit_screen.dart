import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../../models/user_model.dart';

class AccountEditScreen extends ConsumerStatefulWidget {
  const AccountEditScreen({super.key});

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  List<String> _portfolioLinks = [];
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _init(AppUser profile) {
    if (_initialized) return;
    _nameCtrl.text = profile.name;
    _bioCtrl.text = profile.bio ?? '';
    _skillsCtrl.text = profile.skills.join(', ');
    _portfolioLinks = List<String>.from(profile.portfolioLinks);
    _initialized = true;
  }

  void _addLink() {
    final link = _linkCtrl.text.trim();
    if (link.isEmpty) return;
    setState(() {
      _portfolioLinks.add(link);
      _linkCtrl.clear();
    });
  }

  Future<void> _save(AppUser profile) async {
    setState(() => _saving = true);
    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(authRepositoryProvider).updateProfile(
            profile.copyWith(
              name: _nameCtrl.text.trim(),
              bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
              skills: skills,
              portfolioLinks: _portfolioLinks,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          _init(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Bio')),
                const SizedBox(height: 12),
                TextField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skills (comma separated)',
                    hintText: 'Flutter, UI design, copywriting...',
                  ),
                ),
                const SizedBox(height: 20),
                Text('Portfolio links',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ..._portfolioLinks.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.link,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(e.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13))),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.grey),
                            onPressed: () => setState(
                                () => _portfolioLinks.removeAt(e.key)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _linkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add link',
                          hintText: 'https://github.com/yourname',
                        ),
                        onSubmitted: (_) => _addLink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _addLink,
                        icon: const Icon(Icons.add)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(profile),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
