import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitored_person.dart';
import '../services/api_service.dart';
import 'realtime_connection_provider.dart';

final monitoredPersonsProvider = StateNotifierProvider<MonitoredPersonsNotifier, AsyncValue<List<MonitoredPerson>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = MonitoredPersonsNotifier(apiService);

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventProvider, (previous, next) {
    next.whenData((event) {
      final type = (event['type'] ?? event['event'] ?? '').toString();
      if (type == 'LOCATION_UPDATE' || type == 'location' || type == 'GEOFENCE_EVENT' || type == 'ATTENDANCE_VERIFIED') {
        final data = event['data'] is Map<String, dynamic> ? event['data'] as Map<String, dynamic> : event;
        final personId = (data['user_id'] ?? data['person_id'] ?? data['officer_id'])?.toString();
        if (personId != null && personId.isNotEmpty) {
          final lat = (data['latitude'] ?? data['lat'] ?? 0.0).toDouble();
          final lng = (data['longitude'] ?? data['lng'] ?? data['lon'] ?? 0.0).toDouble();
          final status = (data['status'] ?? 'INSIDE').toString().toUpperCase();
          final accuracy = (data['gps_accuracy'] ?? data['accuracy'] ?? 0.0).toDouble();
          if (lat != 0.0 && lng != 0.0) {
            notifier.updatePersonLocation(personId, lat, lng, status, accuracy);
          }
        }
      }
    });
  });

  return notifier;
});

class MonitoredPersonsNotifier extends StateNotifier<AsyncValue<List<MonitoredPerson>>> {
  final ApiService _apiService;

  MonitoredPersonsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadPersons();
  }

  static final List<MonitoredPerson> _defaultPersons = [
    MonitoredPerson(
      id: 'PEMP-205',
      name: 'Rajesh S',
      status: 'INSIDE',
      assignedSite: 'CRC Coimbatore Rehabilitation Centre',
      latitude: 11.016844,
      longitude: 76.955832,
      gpsAccuracy: 8.0,
      distanceMeters: 18.0,
      geofenceId: 'GEO-CRC-CBE',
      geofenceName: 'CRC Coimbatore Campus',
      lastUpdate: DateTime.now(),
      todayAttendanceStatus: 'PENDING',
      deviceStatus: 'ONLINE',
    ),
    MonitoredPerson(
      id: 'PEMP-ARUN-202',
      name: 'Arun Kumar',
      status: 'VERIFYING',
      assignedSite: 'National Institute for Empowerment (NIEPMD)',
      latitude: 12.8258,
      longitude: 80.0450,
      gpsAccuracy: 12.0,
      distanceMeters: 42.0,
      geofenceId: 'GEO-NIEPMD-01',
      geofenceName: 'NIEPMD Outer Sector',
      lastUpdate: DateTime.now(),
      todayAttendanceStatus: 'PENDING',
      deviceStatus: 'ONLINE',
    ),
    MonitoredPerson(
      id: 'PEMP-KAV-101',
      name: 'Kavitha Raman',
      status: 'PENDING',
      assignedSite: 'Divyangjan Skills & Training Complex',
      latitude: 13.0827,
      longitude: 80.2707,
      gpsAccuracy: 9.0,
      distanceMeters: 25.0,
      geofenceId: 'GEO-DSTC-02',
      geofenceName: 'DSTC Chennai Facility',
      lastUpdate: DateTime.now(),
      todayAttendanceStatus: 'PENDING',
      deviceStatus: 'ONLINE',
    ),
  ];

  Future<void> loadPersons() async {
    state = const AsyncValue.loading();
    try {
      final persons = await _apiService.getMonitoredPersons();
      final locations = await _apiService.getUserLocations();
      final locMap = <String, Map<String, dynamic>>{};
      for (final loc in locations) {
        final uid = (loc['user_id'] ?? loc['officer_id'])?.toString();
        if (uid != null) {
          locMap[uid] = loc;
        }
      }

      final updated = persons.map((p) {
        final loc = locMap[p.id];
        if (loc != null) {
          final lat = (loc['latitude'] ?? loc['lat'] ?? p.latitude).toDouble();
          final lng = (loc['longitude'] ?? loc['lng'] ?? p.longitude).toDouble();
          final acc = (loc['gps_accuracy'] ?? loc['accuracy'] ?? p.gpsAccuracy).toDouble();
          final status = (loc['status'] ?? p.status).toString();
          return MonitoredPerson(
            id: p.id,
            name: p.name,
            photoUrl: p.photoUrl,
            status: status,
            assignedSite: p.assignedSite,
            latitude: lat,
            longitude: lng,
            gpsAccuracy: acc,
            distanceMeters: p.distanceMeters,
            geofenceId: p.geofenceId,
            geofenceName: p.geofenceName,
            lastUpdate: loc['timestamp'] != null ? DateTime.tryParse(loc['timestamp']) ?? p.lastUpdate : p.lastUpdate,
            todayAttendanceStatus: p.todayAttendanceStatus,
            deviceStatus: 'ONLINE',
          );
        }
        return p;
      }).toList();

      if (updated.isEmpty) {
        state = AsyncValue.data(_defaultPersons);
      } else {
        state = AsyncValue.data(updated);
      }
    } catch (_) {
      state = AsyncValue.data(_defaultPersons);
    }
  }

  void updatePersonLocation(String personId, double lat, double lng, String status, double accuracy) {
    state.whenData((persons) {
      var found = false;
      final updatedList = persons.map((person) {
        if (person.id == personId) {
          found = true;
          return MonitoredPerson(
            id: person.id,
            name: person.name,
            photoUrl: person.photoUrl,
            status: status,
            assignedSite: person.assignedSite,
            latitude: lat,
            longitude: lng,
            gpsAccuracy: accuracy,
            distanceMeters: person.distanceMeters,
            geofenceId: person.geofenceId,
            geofenceName: person.geofenceName,
            lastUpdate: DateTime.now(),
            todayAttendanceStatus: person.todayAttendanceStatus,
            deviceStatus: 'ONLINE',
          );
        }
        return person;
      }).toList();

      if (!found) {
        updatedList.add(MonitoredPerson(
          id: personId,
          name: 'Field Officer ($personId)',
          photoUrl: null,
          status: status,
          assignedSite: 'Assigned Perimeter',
          latitude: lat,
          longitude: lng,
          gpsAccuracy: accuracy,
          distanceMeters: 0.0,
          geofenceId: '',
          geofenceName: 'Active Sector',
          lastUpdate: DateTime.now(),
          todayAttendanceStatus: 'PRESENT',
          deviceStatus: 'ONLINE',
        ));
      }

      state = AsyncValue.data(updatedList);
    });
  }
}

