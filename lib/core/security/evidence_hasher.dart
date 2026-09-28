import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

/// Cryptographic Tamper-Evidence Hashing Service
class EvidenceHasher {
  const EvidenceHasher._();

  /// Generates a SHA-256 fingerprint from bytes, metadata, timestamp, and salt
  static String generateEvidenceHash({
    required List<int> fileBytes,
    required String inspectionId,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
  }) {
    final fileDigest = sha256.convert(fileBytes).toString();
    final metadataString =
        '${inspectionId}_${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}_${capturedAt.toIso8601String()}_${AppConfig.tamperEvidenceSalt}_$fileDigest';
    return sha256.convert(utf8.encode(metadataString)).toString();
  }

  /// Verifies if a given file matches expected hash
  static bool verifyHash({
    required List<int> fileBytes,
    required String inspectionId,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    required String expectedHash,
  }) {
    final computed = generateEvidenceHash(
      fileBytes: fileBytes,
      inspectionId: inspectionId,
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt,
    );
    return computed == expectedHash;
  }
}
