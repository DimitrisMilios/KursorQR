import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_config.dart';
import '../models/qr_design_config.dart';
import '../models/qr_link.dart';

/// Custom domain exception for user-friendly quota & slug collision messages.
class QrQuotaException implements Exception {
  const QrQuotaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Repository handling all Cloud Firestore reads & atomic Spark-safe writes.
/// Uses on-demand `get()` rather than persistent streams to minimize daily reads.
class QrLinkRepository {
  QrLinkRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _linksCol =>
      _firestore.collection(AppConfig.qrLinksCollection);

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConfig.usersCollection);

  /// Fetches all QR links belonging to [ownerId] via a single on-demand query.
  Future<List<QrLink>> fetchUserLinks(String ownerId) async {
    final snapshot =
        await _linksCol.where('ownerId', isEqualTo: ownerId).get();
    final links = snapshot.docs.map(QrLink.fromDoc).toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = bTime.compareTo(aTime);
        return cmp != 0 ? cmp : a.slug.compareTo(b.slug);
      });
    return links;
  }

  /// Atomically creates a new QR link AND registers its slug in `users/{uid}`
  /// so Firestore security rules strictly enforce the 10 QR links/account cap.
  Future<QrLink> createLink({
    required String ownerId,
    required String slug,
    required String title,
    required String webUrl,
    required String iosUrl,
    required String androidUrl,
    required bool isActive,
    QrDesignConfig design = const QrDesignConfig(),
  }) async {
    final normalizedSlug = slug.trim().toLowerCase();
    final linkRef = _linksCol.doc(normalizedSlug);
    final userRef = _usersCol.doc(ownerId);

    // 1. Check slug availability & current quota ledger (2 lightweight reads).
    final results = await Future.wait([linkRef.get(), userRef.get()]);
    final existingLinkSnap = results[0];
    final userSnap = results[1];

    if (existingLinkSnap.exists) {
      throw QrQuotaException(
        'Slug "$normalizedSlug" is already taken. Try another slug or click shuffle.',
      );
    }

    final existingSlugs = userSnap.exists
        ? List<String>.from(
            (userSnap.data()?['qrSlugs'] as List<dynamic>? ?? const [])
                .map((e) => e.toString()),
          )
        : <String>[];

    if (existingSlugs.length >= AppConfig.maxQrLinksPerAccount) {
      throw const QrQuotaException(
        'Free account limit reached (${AppConfig.maxQrLinksPerAccount}/${AppConfig.maxQrLinksPerAccount} QR codes). '
        'Delete an unused QR code to free a slot.',
      );
    }

    final updatedSlugs = [...existingSlugs, normalizedSlug];
    final batch = _firestore.batch();

    if (userSnap.exists) {
      batch.update(userRef, {
        'qrSlugs': updatedSlugs,
        'lastMutatedSlug': normalizedSlug,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.set(userRef, {
        'qrSlugs': updatedSlugs,
        'lastMutatedSlug': normalizedSlug,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(linkRef, {
      'ownerId': ownerId,
      'title': title.trim(),
      'webUrl': webUrl.trim(),
      'iosUrl': iosUrl.trim(),
      'androidUrl': androidUrl.trim(),
      'isActive': isActive,
      'totalScans': 0,
      'iosScans': 0,
      'androidScans': 0,
      'design': design.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final now = DateTime.now();
    return QrLink(
      slug: normalizedSlug,
      ownerId: ownerId,
      title: title.trim(),
      webUrl: webUrl.trim(),
      iosUrl: iosUrl.trim(),
      androidUrl: androidUrl.trim(),
      isActive: isActive,
      totalScans: 0,
      iosScans: 0,
      androidScans: 0,
      design: design,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Updates an existing QR link's routing metadata (preserves scan counters).
  Future<void> updateLink({
    required String slug,
    required String title,
    required String webUrl,
    required String iosUrl,
    required String androidUrl,
    required bool isActive,
  }) async {
    await _linksCol.doc(slug).update({
      'title': title.trim(),
      'webUrl': webUrl.trim(),
      'iosUrl': iosUrl.trim(),
      'androidUrl': androidUrl.trim(),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Persists the QR Studio visual style (colors, linear gradient, shape, icon).
  Future<void> saveDesign({
    required String slug,
    required QrDesignConfig design,
  }) async {
    await _linksCol.doc(slug).update({
      'design': design.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Atomically deletes a QR link AND removes it from `users/{uid}.qrSlugs`
  /// so the user immediately reclaims their quota slot.
  Future<void> deleteLink({
    required String ownerId,
    required String slug,
  }) async {
    final linkRef = _linksCol.doc(slug);
    final userRef = _usersCol.doc(ownerId);
    final userSnap = await userRef.get();

    final batch = _firestore.batch();
    batch.delete(linkRef);

    if (userSnap.exists) {
      final existingSlugs = List<String>.from(
        (userSnap.data()?['qrSlugs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString()),
      );
      if (existingSlugs.contains(slug)) {
        final nextSlugs = existingSlugs.where((s) => s != slug).toList();
        batch.update(userRef, {
          'qrSlugs': nextSlugs,
          'lastMutatedSlug': slug,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// GDPR Art. 17 Right to Erasure: deletes all QR links owned by [ownerId]
  /// and then removes the user's quota ledger document `users/{uid}`.
  Future<void> deleteAllUserData(String ownerId) async {
    final ownedLinks = await fetchUserLinks(ownerId);
    for (final link in ownedLinks) {
      await deleteLink(ownerId: ownerId, slug: link.slug);
    }

    final userRef = _usersCol.doc(ownerId);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      await userRef.delete();
    }
  }
}
