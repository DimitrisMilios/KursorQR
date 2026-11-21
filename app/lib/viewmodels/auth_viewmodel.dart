import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/qr_link_repository.dart';

/// MVVM ViewModel managing authentication, email verification, and GDPR erasure.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required AuthRepository authRepository,
    required QrLinkRepository qrLinkRepository,
  })  : _authRepo = authRepository,
        _qrLinkRepo = qrLinkRepository {
    _user = _authRepo.currentUser;
    _authSub = _authRepo.authStateChanges().listen((user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  final AuthRepository _authRepo;
  final QrLinkRepository _qrLinkRepo;
  late final StreamSubscription<User?> _authSub;

  User? _user;
  bool _isInitializing = true;
  bool _isBusy = false;
  String? _errorMessage;
  String? _infoMessage;

  User? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isSignedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(() async {
      await _authRepo.signInWithGoogle();
    });
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _authRepo.signInWithEmail(email: email, password: password);
    });
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _authRepo.signUpWithEmail(email: email, password: password);
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _runAuthAction(
      () async {
        await _authRepo.sendPasswordResetEmail(email);
        _infoMessage = 'Password reset link sent to ${email.trim()}.';
      },
    );
  }

  Future<bool> resendVerificationEmail() async {
    return _runAuthAction(
      () async {
        await _authRepo.sendEmailVerification();
        _infoMessage = 'Verification email sent! Check your inbox and spam folder.';
      },
    );
  }

  Future<bool> checkEmailVerificationStatus() async {
    return _runAuthAction(
      () async {
        final refreshed = await _authRepo.reloadAndRefreshUser();
        _user = refreshed;
        if (refreshed != null && !refreshed.emailVerified) {
          _infoMessage =
              'Email not verified yet. Please click the link we sent to ${refreshed.email ?? 'your inbox'}.';
        }
      },
    );
  }

  Future<void> signOut() async {
    _errorMessage = null;
    _infoMessage = null;
    await _authRepo.signOut();
  }

  /// GDPR Art. 17 Right to Erasure: wipes all user QR links, quota ledger,
  /// and Firebase Auth account.
  Future<bool> deleteAccountAndAllData() async {
    final current = _user;
    if (current == null) return false;

    return _runAuthAction(() async {
      await _qrLinkRepo.deleteAllUserData(current.uid);
      await _authRepo.deleteCurrentUserAccount();
    });
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _errorMessage =
            'For security, please sign out and sign back in right before deleting your account.';
      } else {
        _errorMessage = e.message ?? 'Authentication error (${e.code}).';
      }
      return false;
    } catch (e) {
      _errorMessage = 'Operation failed: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
