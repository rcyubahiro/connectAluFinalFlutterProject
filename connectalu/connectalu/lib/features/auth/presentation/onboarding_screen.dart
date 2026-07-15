import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model.dart';
import '../providers/auth_providers.dart';

/// Shown once, right after signup, before the user can reach the rest
/// of the app. This is where the student/founder fork happens — the
/// router redirects here whenever profile.role is null.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  UserRole? _selectedRole;
  final _skillsCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How will you use ConnectALU?',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _RoleCard(
                title: "I'm a student",
                subtitle: 'Looking for internships and hands-on experience',
                icon: Icons.person_outline,
                selected: _selectedRole == UserRole.student,
                onTap: () => setState(() => _selectedRole = UserRole.student),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: "I'm a founder",
                subtitle: 'Running an ALU-affiliated startup, looking for help',
                icon: Icons.rocket_launch_outlined,
                selected: _selectedRole == UserRole.founder,
                onTap: () => setState(() => _selectedRole = UserRole.founder),
              ),
              const SizedBox(height: 24),
              if (_selectedRole == UserRole.student) ...[
                TextField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your skills (comma separated)',
                    hintText: 'Flutter, UI design, copywriting...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Short bio (optional)'),
                ),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedRole == null || authState.isLoading
                    ? null
                    : _finish,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finish() {
    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    ref.read(authControllerProvider.notifier).completeOnboarding(
          _selectedRole!,
          skills: skills,
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
          color: selected ? color.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
