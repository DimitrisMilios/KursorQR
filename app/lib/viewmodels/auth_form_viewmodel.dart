import 'package:flutter/foundation.dart';

import 'auth_viewmodel.dart';

/// Pure MVVM ViewModel for the Sign-In / Create Account modal form.
/// Keeps all validation, password visibility, and submission flow out of views.
class AuthFormViewModel extends ChangeNotifier {
  AuthFormViewModel({
    required AuthViewModel authViewModel,
    bool initialIsSignUp = false,
  })  : _authViewModel = authViewModel,
        _isSignUp = initialIsSignUp {
    _authViewModel.clearMessages();
  }

  final AuthViewModel _authViewModel;

  bool _isSignUp;
  bool _obscurePassword = true;
  String _email = '';
  String _password = '';
  String? _emailError;
  String? _passwordError;

  bool get isSignUp => _isSignUp;
  bool get obscurePassword => _obscurePassword;
  String get email => _email;
  String get password => _password;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  bool get isBusy => _authViewModel.isBusy;
  String? get errorMessage => _authViewModel.errorMessage;
  String? get infoMessage => _authViewModel.infoMessage;

  void setSignUpMode(bool value) {
    if (_isSignUp == value) return;
    _isSignUp = value;
    _emailError = null;
    _passwordError = null;
    _authViewModel.clearMessages();
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
  }

  void setPassword(String value) {
    _password = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  static String? validateEmail(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String raw, {required bool isSignUp}) {
    if (raw.isEmpty) return 'Enter your password';
    if (isSignUp && raw.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<bool> submitGoogle() => _authViewModel.signInWithGoogle();

  Future<bool> submitEmail() async {
    _emailError = validateEmail(_email);
    _passwordError = validatePassword(_password, isSignUp: _isSignUp);
    notifyListeners();
    if (_emailError != null || _passwordError != null) return false;

    return _isSignUp
        ? _authViewModel.signUpWithEmail(email: _email, password: _password)
        : _authViewModel.signInWithEmail(email: _email, password: _password);
  }

  Future<bool> sendPasswordReset() async {
    final err = validateEmail(_email);
    if (err != null) {
      _emailError = 'Enter your email address first to reset your password';
      notifyListeners();
      return false;
    }
    _emailError = null;
    notifyListeners();
    return _authViewModel.sendPasswordReset(_email);
  }
}
