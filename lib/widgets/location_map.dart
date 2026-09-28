import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../models/geofence.dart';
import '../models/user_location.dart';

/// Production OpenStreetMap widget powered by flutter_map with clean enterprise styling.
class LocationMap extends StatefulWidget {
  final UserLocation? userLocation;
  final List<UserLocation> history;
  final Geofence geofence;
  final bool isTracking;

  const LocationMap({
    super.key,
    required this.userLocation,
    required this.history,
    required this.geofence,
    required this.isTracking,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final MapController _mapController = MapController();
  bool _hasInitialCentered = false;

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null && !_hasInitialCentered) {
      _hasInitialCentered = true;
      _centerOnUser();
    }
  }

  void _centerOnUser() {
    if (widget.userLocation == null) return;
    _mapController.move(
      LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
      16.5,
    );
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidGeofence = widget.geofence.latitude != 0.0 && widget.geofence.longitude != 0.0;
    final defaultCenter = widget.userLocation != null
        ? LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude)
        : (hasValidGeofence
            ? LatLng(widget.geofence.latitude, widget.geofence.longitude)
            : const LatLng(20.5937, 78.9629));

    final polylinePoints = widget.history
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: defaultCenter,
            initialZoom: widget.userLocation != null ? 16.5 : (hasValidGeofence ? 16.0 : 5.0),
            minZoom: 4.0,
            maxZoom: 19.0,
          ),
          children: [
            // Compliant OpenStreetMap Tile Provider with MoSJE User-Agent
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'in.gov.mosje.sih_officer',
            ),

            // Geofence Authorized Perimeter Circle
            CircleLayer(
              circles: [
                if (hasValidGeofence)
                  CircleMarker(
                    point: LatLng(widget.geofence.latitude, widget.geofence.longitude),
                    radius: widget.geofence.radiusMeters,
                    useRadiusInMeter: true,
                    color: AppColors.accentTeal.withValues(alpha: 0.12),
                    borderColor: AppColors.accentTeal,
                    borderStrokeWidth: 2.0,
                  ),
                // Accuracy circle around user location
                if (widget.userLocation != null)
                  CircleMarker(
                    point: LatLng(
                      widget.userLocation!.latitude,
                      widget.userLocation!.longitude,
                    ),
                    radius: widget.userLocation!.accuracy.clamp(5.0, 100.0),
                    useRadiusInMeter: true,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    borderStrokeWidth: 1.0,
                  ),
              ],
            ),

            // Movement Path History
            if (polylinePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 3.5,
                    color: const Color(0xFF1D4ED8),
                  ),
                ],
              ),

            // Map Markers: Geofence Anchor & User Location Pin
            MarkerLayer(
              markers: [
                // Geofence Centre Anchor Marker
                if (hasValidGeofence)
                  Marker(
                    point: LatLng(widget.geofence.latitude, widget.geofence.longitude),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: AppColors.accentTeal, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        size: 22,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),

                // User Location Live Position Marker
                if (widget.userLocation != null)
                  Marker(
                    point: LatLng(
                      widget.userLocation!.latitude,
                      widget.userLocation!.longitude,
                    ),
                    width: 48,
                    height: 48,
                    child: _buildUserMarker(),
                  ),
              ],
            ),
          ],
        ),

        // Controls overlay: Recenter + Zoom Buttons
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControlButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Re-center on officer',
                onTap: _centerOnUser,
              ),
              const SizedBox(height: 8),
              _buildMapControlButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom in',
                onTap: _zoomIn,
              ),
              const SizedBox(height: 4),
              _buildMapControlButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom out',
                onTap: _zoomOut,
              ),
            ],
          ),
        ),

        // Geofence Legend Pill (Top-Left)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.geofence.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Live GPS acquisition status banner if awaiting initial fix
        if (widget.userLocation == null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acquiring Real-Time Device GPS Telemetry...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing radar ripple if tracking active
        if (widget.isTracking)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            ),
          ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
