import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Raw FirebaseAuth stream — used only by the router to decide
/// authenticated vs unauthenticated. Screens should use userProfileProvider
/// instead, since that's the one with role/skills/etc.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The live Firestore-backed profile of whoever is currently signed in.
/// This is a StreamProvider (not FutureProvider) deliberately: profile
/// edits made from other devices/screens should reflect immediately,
/// and this doc is small and cheap to keep subscribed.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return repo.watchUserProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Convenience derived provider so UI can branch on role without
/// repeatedly null-checking the whole profile.
final isFounderProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.role == UserRole.founder;
});

/// Controller for auth actions (sign in / register / sign out) that screens
/// call into. Kept separate from the state providers above so widgets
/// watching profile/auth state don't rebuild on every button press.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signInWithEmail(email, password));
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cred = await _repo.registerWithEmail(email, password);
      await _repo.createInitialProfile(uid: cred.user!.uid, name: name, email: email);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  Future<void> completeOnboarding(UserRole role, {List<String> skills = const [], String? bio}) async {
    final uid = _repo.currentUser?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.completeOnboarding(uid: uid, role: role, skills: skills, bio: bio),
    );
  }

  Future<void> toggleSavedOpportunity(String opportunityId) async {
    final uid = _repo.currentUser?.uid;
    if (uid == null) return;
    final profile = await _repo.fetchUserProfile(uid);
    if (profile == null) return;
    final saved = [...profile.savedOpportunityIds];
    if (saved.contains(opportunityId)) {
      saved.remove(opportunityId);
    } else {
      saved.add(opportunityId);
    }
    await _repo.updateProfile(profile.copyWith(savedOpportunityIds: saved));
  }

  Future<void> signOut() => _repo.signOut();
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Fetches the FCM token and saves it to the user's Firestore doc so the
/// backend (or a Cloud Function) can send targeted push notifications.
/// Re-runs whenever auth state changes so the token is always fresh.
final fcmTokenSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;
  await FirebaseMessaging.instance.onTokenRefresh.first.timeout(
    Duration.zero,
    onTimeout: () => token,
  );
  await ref.read(authRepositoryProvider).saveMessagingToken(user.uid, token);
});
