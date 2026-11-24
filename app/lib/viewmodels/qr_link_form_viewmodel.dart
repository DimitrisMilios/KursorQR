import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/qr_link.dart';
import 'dashboard_viewmodel.dart';

/// Pure MVVM ViewModel for creating or editing a dynamic QR link.
/// Owns slug generation, URL validation, active state, and submission.
class QrLinkFormViewModel extends ChangeNotifier {
  QrLinkFormViewModel({
    required DashboardViewModel dashboardViewModel,
    this.existing,
  })  : _dashboardViewModel = dashboardViewModel,
        _slug = existing?.slug ?? generateRandomSlug(),
        _title = existing?.title ?? '',
        _webUrl = existing?.webUrl ?? '',
        _iosUrl = existing?.iosUrl ?? '',
        _androidUrl = existing?.androidUrl ?? '',
        _isActive = existing?.isActive ?? true;

  final DashboardViewModel _dashboardViewModel;
  final QrLink? existing;

  String _slug;
  String _title;
  String _webUrl;
  String _iosUrl;
  String _androidUrl;
  bool _isActive;
  bool _isSaving = false;

  String? _slugError;
  String? _titleError;
  String? _webUrlError;
  String? _iosUrlError;
  String? _androidUrlError;
  String? _submitError;

  bool get isEditing => existing != null;
  String get slug => _slug;
  String get title => _title;
  String get webUrl => _webUrl;
  String get iosUrl => _iosUrl;
  String get androidUrl => _androidUrl;
  bool get isActive => _isActive;
  bool get isSaving => _isSaving;

  String? get slugError => _slugError;
  String? get titleError => _titleError;
  String? get webUrlError => _webUrlError;
  String? get iosUrlError => _iosUrlError;
  String? get androidUrlError => _androidUrlError;
  String? get submitError => _submitError;

  static String generateRandomSlug() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rng = Random.secure();
    return List.generate(7, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static String? validateSlug(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return 'Slug is required';
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{2,47}$').hasMatch(normalized)) {
      return 'Use 3-48 chars: lowercase a-z, 0-9, "-" or "_"';
    }
    return null;
  }

  static String? validateTitle(String raw) {
    if (raw.trim().isEmpty) return 'Enter a display name';
    if (raw.trim().length > 120) return 'Name is too long (max 120 characters)';
    return null;
  }

  static String? validateRequiredUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Fallback web URL is required';
    if (!RegExp(r'^https?:\/\/.+', caseSensitive: false).hasMatch(trimmed)) {
      return 'Must start with https:// or http://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  static String? validateOptionalStoreUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(
      r'^(https?:\/\/|itms-apps:\/\/|market:\/\/).+',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return 'Must start with https://, http://, itms-apps://, or market://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  String regenerateSlug() {
    if (isEditing) return _slug;
    _slug = generateRandomSlug();
    _slugError = null;
    notifyListeners();
    return _slug;
  }

  void setSlug(String value) {
    _slug = value;
    if (_slugError != null) {
      _slugError = null;
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _title = value;
    if (_titleError != null) {
      _titleError = null;
      notifyListeners();
    }
  }

  void setWebUrl(String value) {
    _webUrl = value;
    if (_webUrlError != null) {
      _webUrlError = null;
      notifyListeners();
    }
  }

  void setIosUrl(String value) {
    _iosUrl = value;
    if (_iosUrlError != null) {
      _iosUrlError = null;
      notifyListeners();
    }
  }

  void setAndroidUrl(String value) {
    _androidUrl = value;
    if (_androidUrlError != null) {
      _androidUrlError = null;
      notifyListeners();
    }
  }

  void setActive(bool value) {
    if (_isActive == value) return;
    _isActive = value;
    notifyListeners();
  }

  /// Validates all fields and persists via [DashboardViewModel].
  /// Returns the normalized slug on success, or `null` if invalid/failed.
  Future<String?> submit() async {
    _slugError = isEditing ? null : validateSlug(_slug);
    _titleError = validateTitle(_title);
    _webUrlError = validateRequiredUrl(_webUrl);
    _iosUrlError = validateOptionalStoreUrl(_iosUrl);
    _androidUrlError = validateOptionalStoreUrl(_androidUrl);
    _submitError = null;

    if (_slugError != null ||
        _titleError != null ||
        _webUrlError != null ||
        _iosUrlError != null ||
        _androidUrlError != null) {
      notifyListeners();
      return null;
    }

    _isSaving = true;
    notifyListeners();

    final normalizedSlug = _slug.trim().toLowerCase();
    try {
      if (isEditing) {
        await _dashboardViewModel.updateLink(
          slug: normalizedSlug,
          title: _title,
          webUrl: _webUrl,
          iosUrl: _iosUrl,
          androidUrl: _androidUrl,
          isActive: _isActive,
        );
      } else {
        await _dashboardViewModel.createLink(
          slug: normalizedSlug,
          title: _title,
          webUrl: _webUrl,
          iosUrl: _iosUrl,
          androidUrl: _androidUrl,
          isActive: _isActive,
        );
      }
      return normalizedSlug;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
