import 'package:flutter/material.dart';
import '../models/user_location.dart';
import '../services/geofence_service.dart';

/// Clean enterprise telemetry card displaying geofence containment,
/// exact geodesic distance, and satellite coordinates.
class LocationInfoCard extends StatelessWidget {
  final UserLocation? userLocation;
  final GeofenceEvaluation? evaluation;

  const LocationInfoCard({
    super.key,
    required this.userLocation,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInside = evaluation?.isInside ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geofence status header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GEOFENCE AUDIT STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInside ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInside ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      size: 13,
                      color: isInside ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isInside ? 'INSIDE AUTHORIZED AREA' : 'OUTSIDE AUTHORIZED AREA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isInside ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Distance from authorized area / center
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distance from authorized area:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  evaluation != null
                      ? isInside
                          ? '0 m (Compliant)'
                          : '${evaluation!.distanceToPerimeterMeters.toStringAsFixed(0)} m'
                      : '-- m',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isInside ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Telemetry Specs Grid
          Row(
            children: [
              _buildSpecItem(
                label: 'Latitude',
                value: userLocation != null ? userLocation!.latitude.toStringAsFixed(6) : '--',
              ),
              _buildSpecItem(
                label: 'Longitude',
                value: userLocation != null ? userLocation!.longitude.toStringAsFixed(6) : '--',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSpecItem(
                label: 'Speed',
                value: userLocation != null
                    ? '${(userLocation!.speed * 3.6).toStringAsFixed(1)} km/h'
                    : '--',
              ),
              _buildSpecItem(
                label: 'Altitude',
                value: userLocation != null
                    ? '${userLocation!.altitude.toStringAsFixed(1)} m'
                    : '--',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
