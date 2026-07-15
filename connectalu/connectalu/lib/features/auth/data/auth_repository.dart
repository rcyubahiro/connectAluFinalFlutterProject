import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../models/user_model.dart';

/// Every Firestore call related to auth/user documents lives here.
/// Nothing above this layer talks to FirebaseAuth or Firestore directly —
/// that's the seam that lets us swap backends or mock auth in tests.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<AppUser?> fetchUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(uid, snap.data()!) : null,
        );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    // First try a silent sign-in (uses existing Google session if available).
    GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
    // If there's no silent session, fall back to interactive account chooser.
    googleUser ??= await googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
          code: 'sign-in-cancelled', message: 'Sign in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    final user = userCredential.user;
    if (user != null) {
      final profileRef = _userDoc(user.uid);
      final profileSnap = await profileRef.get();

      if (!profileSnap.exists) {
        await profileRef.set({
          'name': googleUser.displayName ?? user.displayName ?? 'Google User',
          'email': googleUser.email.isNotEmpty ? googleUser.email : user.email ?? '',
          'photoUrl': googleUser.photoUrl ?? user.photoURL,
          'role': null,
          'skills': <String>[],
          'portfolioLinks': <String>[],
          'savedOpportunityIds': <String>[],
          'createdAt': Timestamp.now(),
        });
      }
    }

    return userCredential;
  }

  /// Called immediately after first registration, before role selection.
  Future<void> createInitialProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _userDoc(uid).set({
      'name': name,
      'email': email,
      'role': null, // set during onboarding role-selection step
      'skills': <String>[],
      'portfolioLinks': <String>[],
      'savedOpportunityIds': <String>[],
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> completeOnboarding({
    required String uid,
    required UserRole role,
    List<String> skills = const [],
    String? bio,
  }) async {
    await _userDoc(uid).update({
      'role': role.name,
      'skills': skills,
      'bio': bio,
    });
  }

  Future<void> updateProfile(AppUser user) async {
    await _userDoc(user.uid).update(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut().catchError((_) => null);
  }

  Future<void> saveMessagingToken(String uid, String token) async {
    await _userDoc(uid).update({'fcmToken': token});
  }
}
