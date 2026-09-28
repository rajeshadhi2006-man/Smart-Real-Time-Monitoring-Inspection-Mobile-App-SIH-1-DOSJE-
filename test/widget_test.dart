import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspection/core/security/evidence_hasher.dart';
import 'package:sih_inspection/core/utils/geo_utils.dart';
import 'package:sih_inspection/features/auth/domain/models/user_profile.dart';
import 'package:sih_inspection/features/inspections/domain/models/inspection_model.dart';

void main() {
  group('SIH 26095 Smart Inspection Core Unit Tests', () {
    test('GeoUtils calculates accurate distance and validates geofence', () {
      // Coimbatore Project Registered Location
      const double projectLat = 11.016844;
      const double projectLon = 76.955832;

      // Nearby Inspector (approx 48 meters away)
      const double nearbyLat = 11.016500;
      const double nearbyLon = 76.955600;

      final distance = GeoUtils.calculateDistanceInMeters(
        startLatitude: nearbyLat,
        startLongitude: nearbyLon,
        endLatitude: projectLat,
        endLongitude: projectLon,
      );

      // Verify distance is approximately 45-55 meters
      expect(distance, greaterThan(30.0));
      expect(distance, lessThan(70.0));

      // Check within 100m geofence
      final isInside = GeoUtils.isWithinGeofence(
        inspectorLat: nearbyLat,
        inspectorLon: nearbyLon,
        projectLat: projectLat,
        projectLon: projectLon,
        customRadiusMeters: 100.0,
      );
      expect(isInside, isTrue);

      // Distant Inspector (approx 1.8km away)
      const double distantLat = 11.032000;
      const double distantLon = 76.968000;

      final isOutside = GeoUtils.isWithinGeofence(
        inspectorLat: distantLat,
        inspectorLon: distantLon,
        projectLat: projectLat,
        projectLon: projectLon,
        customRadiusMeters: 100.0,
      );
      expect(isOutside, isFalse);
    });

    test('EvidenceHasher generates deterministic SHA-256 fingerprint', () {
      final mockBytes = [1, 2, 3, 4, 5, 6, 7, 8];
      final timestamp = DateTime(2026, 9, 3, 10, 30);

      final hash1 = EvidenceHasher.generateEvidenceHash(
        fileBytes: mockBytes,
        inspectionId: 'INS-2026-00182',
        latitude: 11.016844,
        longitude: 76.955832,
        capturedAt: timestamp,
      );

      final hash2 = EvidenceHasher.generateEvidenceHash(
        fileBytes: mockBytes,
        inspectionId: 'INS-2026-00182',
        latitude: 11.016844,
        longitude: 76.955832,
        capturedAt: timestamp,
      );

      // Verify hashes are 64 characters (SHA-256 hex string)
      expect(hash1.length, equals(64));
      expect(hash1, equals(hash2));

      // Verify hash changes if file or metadata is altered
      final alteredHash = EvidenceHasher.generateEvidenceHash(
        fileBytes: [1, 2, 3, 4, 5, 6, 7, 9], // altered 1 byte
        inspectionId: 'INS-2026-00182',
        latitude: 11.016844,
        longitude: 76.955832,
        capturedAt: timestamp,
      );
      expect(hash1, isNot(equals(alteredHash)));
    });

    test('UserProfile and UserRole correctly parse designations', () {
      expect(UserRole.fromString('PMU Officer'), equals(UserRole.pmuOfficer));
      expect(UserRole.fromString('Department Official'), equals(UserRole.departmentOfficial));
      expect(UserRole.fromString('Inspection Officer'), equals(UserRole.inspectionOfficer));
      expect(UserRole.fromString('Project Staff'), equals(UserRole.projectStaff));

      const profile = UserProfile(
        id: 'USR-01',
        email: 'rajesh.pmu@mosje.gov.in',
        fullName: 'Rajesh Sharma',
        officerId: 'PMU-TN-01',
        role: UserRole.pmuOfficer,
        department: 'MoSJE',
        assignedDistrict: 'Coimbatore',
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, equals('USR-01'));
      expect(restored.fullName, equals('Rajesh Sharma'));
      expect(restored.role, equals(UserRole.pmuOfficer));
    });

    test('InspectionModel calculates checklist completion progress accurately', () {
      final checklist = [
        const ChecklistItemModel(
          id: 'q1',
          category: ChecklistCategory.infrastructure,
          question: 'Building structure intact',
          selectedOption: ChecklistOption.pass,
        ),
        const ChecklistItemModel(
          id: 'q2',
          category: ChecklistCategory.services,
          question: 'Training equipment operational',
          selectedOption: ChecklistOption.fail,
        ),
        const ChecklistItemModel(
          id: 'q3',
          category: ChecklistCategory.beneficiaries,
          question: 'Headcount matches records',
          selectedOption: null, // unanswered
        ),
        const ChecklistItemModel(
          id: 'q4',
          category: ChecklistCategory.documentation,
          question: 'Financial accounts verified',
          selectedOption: null, // unanswered
        ),
      ];

      final inspection = InspectionModel(
        id: 'INS-TEST-01',
        projectId: 'PRJ-TEST-01',
        projectName: 'Test Centre',
        organization: 'Test NGO',
        district: 'Coimbatore',
        status: InspectionStatus.inProgress,
        priority: 'HIGH',
        assignmentReason: 'Audit',
        scheduledWindow: 'Today',
        deadline: 'Tomorrow',
        assignedInspector: 'Inspector Officer',
        checklist: checklist,
      );

      expect(inspection.totalChecklistCount, equals(4));
      expect(inspection.completedChecklistCount, equals(2));
      expect(inspection.checklistProgress, equals(0.5));
    });
  });
}
