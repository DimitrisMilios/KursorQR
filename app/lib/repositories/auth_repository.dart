import 'package:firebase_auth/firebase_auth.dart';

/// Repository encapsulating all Firebase Authentication operations.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    return _auth.signInWithPopup(provider);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates an Email/Password account and immediately dispatches an email
  /// verification link to prevent throwaway bot spam on the free Spark tier.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
    return credential;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reloads the Firebase Auth profile & refreshes the ID token so Firestore
  /// rules immediately see `email_verified == true`.
  Future<User?> reloadAndRefreshUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      await refreshed.getIdToken(true);
    }
    return refreshed;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Deletes the Firebase Auth account (GDPR Art. 17 Right to Erasure).
  /// May throw `FirebaseAuthException(code: 'requires-recent-login')`.
  Future<void> deleteCurrentUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}
