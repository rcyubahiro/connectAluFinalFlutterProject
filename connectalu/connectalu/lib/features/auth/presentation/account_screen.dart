import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../providers/auth_providers.dart';
import '../../../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/application_model.dart';
import '../../applications/providers/application_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  XFile? _pickedImage;
  bool _saving = false;

  Future<void> _pickImage(AppUser profile) async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    setState(() => _pickedImage = img);
    await _uploadAndSave(profile, img);
  }

  Future<void> _uploadAndSave(AppUser profile, XFile img) async {
    setState(() => _saving = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(
              '${profile.uid}-${DateTime.now().millisecondsSinceEpoch}.jpg');
      final snap =
          await storageRef.putFile(File(img.path)).whenComplete(() {});
      final url = await snap.ref.getDownloadURL();
      try {
        await fb_auth.FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      } catch (_) {}
      await ref.read(authRepositoryProvider).updateProfile(
            profile.copyWith(photoUrl: url),
          );
      if (mounted) setState(() => _pickedImage = null);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/account/edit'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile available'));
          }

          final appsAsync =
              ref.watch(myApplicationsProvider(profile.uid));
          final totalApps = appsAsync.value?.length ?? 0;
          final shortlisted = appsAsync.value
                  ?.where((a) => a.status == ApplicationStatus.interview)
                  .length ??
              0;
          final accepted = appsAsync.value
                  ?.where((a) => a.status == ApplicationStatus.accepted)
                  .length ??
              0;

          Widget avatar;
          if (_pickedImage != null) {
            avatar = CircleAvatar(
                radius: 44,
                backgroundImage: FileImage(File(_pickedImage!.path)));
          } else if (profile.photoUrl != null) {
            avatar = CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(profile.photoUrl!));
          } else {
            avatar = CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Text(
                profile.name.isNotEmpty ? profile.name[0] : '?',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              children: [
                // ── Avatar + name ──
                GestureDetector(
                  onTap: () => _pickImage(profile),
                  child: Stack(
                    children: [
                      avatar,
                      if (_saving)
                        const Positioned.fill(
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.black26,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(profile.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.bio!,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
                const SizedBox(height: 20),

                // ── Stats ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(value: '$totalApps', label: 'Applications'),
                      _divider(),
                      _Stat(value: '$shortlisted', label: 'Shortlisted'),
                      _divider(),
                      _Stat(value: '$accepted', label: 'Accepted'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Menu ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: 'My Profile',
                        onTap: () => context.push('/account/edit'),
                      ),
                      _MenuItem(
                        icon: Icons.psychology_outlined,
                        label: 'Skills & Interests',
                        onTap: () => context.push('/account/edit'),
                      ),
                      _MenuItem(
                        icon: Icons.bookmark_outline,
                        label: 'Saved Opportunities',
                        onTap: () => context.push('/bookmarks'),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.logout,
                        label: 'Logout',
                        labelColor: AppTheme.danger,
                        iconColor: AppTheme.danger,
                        showDivider: false,
                        onTap: () => ref
                            .read(authControllerProvider.notifier)
                            .signOut(),
                      ),
                    ],
                  ),
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

  Widget _divider() => Container(
      width: 1, height: 32, color: Colors.grey.shade200);
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon,
              color: iconColor ?? Colors.grey.shade600, size: 22),
          title: Text(label,
              style: TextStyle(
                  color: labelColor ?? const Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right,
              color: Colors.grey.shade300, size: 20),
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        if (showDivider)
          Divider(
              height: 1,
              indent: 52,
              endIndent: 16,
              color: Colors.grey.shade100),
      ],
    );
  }
}
