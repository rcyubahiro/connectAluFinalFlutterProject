import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;

import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegistering) {
      controller.register(
          _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      controller.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, st) {
          // Clear any existing banners so they don't stack.
          ScaffoldMessenger.of(context).clearMaterialBanners();
          // Log raw error for easier debugging.
          debugPrint('Auth error: ${err.toString()}');
          debugPrint('Stack: $st');
          final message = _friendlyError(err);
          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.surface,
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).clearMaterialBanners(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset('assets/images/logo.svg', height: 72),
                  const SizedBox(height: 12),
                  Text(
                    'ConnectALU',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Internships & opportunities within the ALU ecosystem',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  if (_isRegistering) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'ALU email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimum 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isRegistering ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 8),
                  if (!kIsWeb && !(Platform.isWindows || Platform.isLinux || Platform.isMacOS))
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Continue with Google'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isRegistering = !_isRegistering),
                    child: Text(_isRegistering
                        ? 'Already have an account? Sign in'
                        : 'New to ConnectALU? Create an account'),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).go('/admin/login'),
                    child: Text('Admin? Sign in here',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object err) {
    // Handle Google Sign-In web errors gracefully
    final s = err.toString();
    if (s.contains('ClientID not set')) {
      return 'Google Sign-In not configured on web. Use email/password to sign up.';
    }
    if (s.contains('configuration-not-found')) {
      return 'Firebase web configuration incomplete. Try signing up with email/password.';
    }

    // Handle Firebase Auth exceptions explicitly for reliable error codes.
    if (err is fb_auth.FirebaseAuthException) {
      switch (err.code) {
        case 'user-not-found':
        case 'wrong-password':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'sign-in-cancelled':
          return 'Sign in cancelled.';
        default:
          return '${err.code}: ${err.message ?? 'Something went wrong. Please try again.'}';
      }
    }

    // Firestore errors (e.g., permission denied) -> show a friendly message.
    if (err is fb_store.FirebaseException) {
      if (err.code == 'permission-denied') {
        return 'Permission denied (firestore). Ensure your security rules allow authenticated users to write to /users/{uid}.';
      }
      return '${err.code}: ${err.message ?? 'A data error occurred. Please try again.'}';
    }

    // Fallback to string matching for other exception types.
    final k = err.toString();
    if (k.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }

    return 'Error: $k';
  }
}
