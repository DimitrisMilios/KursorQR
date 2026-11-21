import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import 'qr_design_config.dart';

/// Immutable domain model representing a dynamic QR link in Cloud Firestore.
@immutable
class QrLink {
  const QrLink({
    required this.slug,
    required this.ownerId,
    required this.title,
    required this.webUrl,
    required this.iosUrl,
    required this.androidUrl,
    required this.isActive,
    required this.totalScans,
    required this.iosScans,
    required this.androidScans,
    this.design = const QrDesignConfig(),
    this.createdAt,
    this.updatedAt,
  });

  final String slug;
  final String ownerId;
  final String title;
  final String webUrl;
  final String iosUrl;
  final String androidUrl;
  final bool isActive;
  final int totalScans;
  final int iosScans;
  final int androidScans;
  final QrDesignConfig design;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get redirectUrl {
    final base = AppConfig.redirectBaseUrl.endsWith('/')
        ? AppConfig.redirectBaseUrl.substring(
            0,
            AppConfig.redirectBaseUrl.length - 1,
          )
        : AppConfig.redirectBaseUrl;
    return '$base/$slug';
  }

  QrLink copyWith({
    String? title,
    String? webUrl,
    String? iosUrl,
    String? androidUrl,
    bool? isActive,
    int? totalScans,
    int? iosScans,
    int? androidScans,
    QrDesignConfig? design,
    DateTime? updatedAt,
  }) {
    return QrLink(
      slug: slug,
      ownerId: ownerId,
      title: title ?? this.title,
      webUrl: webUrl ?? this.webUrl,
      iosUrl: iosUrl ?? this.iosUrl,
      androidUrl: androidUrl ?? this.androidUrl,
      isActive: isActive ?? this.isActive,
      totalScans: totalScans ?? this.totalScans,
      iosScans: iosScans ?? this.iosScans,
      androidScans: androidScans ?? this.androidScans,
      design: design ?? this.design,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toExportJson() {
    return {
      'slug': slug,
      'redirectUrl': redirectUrl,
      'title': title,
      'webUrl': webUrl,
      'iosUrl': iosUrl,
      'androidUrl': androidUrl,
      'isActive': isActive,
      'anonymousScanCounters': {
        'totalScans': totalScans,
        'iosScans': iosScans,
        'androidScans': androidScans,
      },
      'design': design.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory QrLink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final designRaw = data['design'];
    return QrLink(
      slug: doc.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : doc.id,
      webUrl: (data['webUrl'] as String?) ?? '',
      iosUrl: (data['iosUrl'] as String?) ?? '',
      androidUrl: (data['androidUrl'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      totalScans: (data['totalScans'] as num?)?.toInt() ?? 0,
      iosScans: (data['iosScans'] as num?)?.toInt() ?? 0,
      androidScans: (data['androidScans'] as num?)?.toInt() ?? 0,
      design: designRaw is Map<String, dynamic>
          ? QrDesignConfig.fromMap(designRaw)
          : const QrDesignConfig(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
