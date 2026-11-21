import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../models/qr_design_config.dart';
import '../models/qr_link.dart';
import '../repositories/qr_link_repository.dart';
import '../services/file_downloader.dart';

/// MVVM ViewModel for the authenticated user's multi-tenant QR workspace.
/// Optimized for Spark Plan scale: fetches via on-demand `get()` + manual
/// Refresh + optimistic local updates (zero persistent read streams).
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required QrLinkRepository repository,
    required this.ownerId,
    required this.ownerEmail,
  }) : _repository = repository;

  final QrLinkRepository _repository;
  final String ownerId;
  final String ownerEmail;

  List<QrLink> _links = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  DateTime? _lastRefreshedAt;

  List<QrLink> get allLinks => _links;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  int get usedQuota => _links.length;
  int get maxQuota => AppConfig.maxQrLinksPerAccount;
  bool get isQuotaReached => usedQuota >= maxQuota;
  double get quotaProgress => (usedQuota / maxQuota).clamp(0.0, 1.0);

  int get activeCount => _links.where((e) => e.isActive).length;
  int get totalScans => _links.fold<int>(0, (acc, e) => acc + e.totalScans);
  int get iosScans => _links.fold<int>(0, (acc, e) => acc + e.iosScans);
  int get androidScans => _links.fold<int>(0, (acc, e) => acc + e.androidScans);

  List<QrLink> get filteredLinks {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _links;
    return _links.where((link) {
      return link.slug.toLowerCase().contains(q) ||
          link.title.toLowerCase().contains(q) ||
          link.webUrl.toLowerCase().contains(q) ||
          link.iosUrl.toLowerCase().contains(q) ||
          link.androidUrl.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Loads or refreshes links on demand via a single Spark-friendly `.get()`.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _links = await _repository.fetchUserLinks(ownerId);
      _hasLoadedOnce = true;
      _lastRefreshedAt = DateTime.now();
    } catch (e) {
      _errorMessage = 'Could not load your QR links: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<QrLink> createLink({
    required String slug,
    required String title,
    required String webUrl,
    required String iosUrl,
    required String androidUrl,
    required bool isActive,
  }) async {
    final created = await _repository.createLink(
      ownerId: ownerId,
      slug: slug,
      title: title,
      webUrl: webUrl,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      isActive: isActive,
    );
    _links = [created, ..._links];
    notifyListeners();
    return created;
  }

  Future<void> updateLink({
    required String slug,
    required String title,
    required String webUrl,
    required String iosUrl,
    required String androidUrl,
    required bool isActive,
  }) async {
    await _repository.updateLink(
      slug: slug,
      title: title,
      webUrl: webUrl,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      isActive: isActive,
    );
    _links = _links.map((link) {
      if (link.slug != slug) return link;
      return link.copyWith(
        title: title.trim(),
        webUrl: webUrl.trim(),
        iosUrl: iosUrl.trim(),
        androidUrl: androidUrl.trim(),
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
    }).toList();
    notifyListeners();
  }

  Future<void> saveLinkDesign({
    required String slug,
    required QrDesignConfig design,
  }) async {
    await _repository.saveDesign(slug: slug, design: design);
    _links = _links.map((link) {
      if (link.slug != slug) return link;
      return link.copyWith(design: design, updatedAt: DateTime.now());
    }).toList();
    notifyListeners();
  }

  Future<void> deleteLink(String slug) async {
    await _repository.deleteLink(ownerId: ownerId, slug: slug);
    _links = _links.where((link) => link.slug != slug).toList();
    notifyListeners();
  }

  /// GDPR Art. 20 Right to Data Portability: exports all account QR data as JSON.
  void exportMyDataAsJson() {
    final payload = {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'platform': AppConfig.appName,
      'gdprNotice':
          'Contains only account-owned QR routing configs and anonymous aggregate scan counters. Zero scanner PII is ever collected.',
      'account': {
        'uid': ownerId,
        'email': ownerEmail,
        'quotaUsed': usedQuota,
        'quotaLimit': maxQuota,
      },
      'qrLinks': _links.map((l) => l.toExportJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    final bytes = Uint8List.fromList(utf8.encode(encoder.convert(payload)));
    downloadBytes(
      bytes: bytes,
      fileName: 'kursorqr-gdpr-export.json',
      mimeType: 'application/json;charset=utf-8',
    );
  }
}
