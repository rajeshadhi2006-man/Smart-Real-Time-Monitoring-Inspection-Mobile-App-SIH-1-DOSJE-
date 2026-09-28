import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../services/reverse_geocoding_service.dart';

/// GPS Map Camera Watermark Card
/// Pixel-perfect replica of the official GPS Map Camera photo stamp overlay.
class GpsMapCameraWatermark extends StatelessWidget {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final GeoAddressData addressData;
  final bool showHeaderBadge;

  const GpsMapCameraWatermark({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.addressData,
    this.showHeaderBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    // Format timestamp: "15/05/23 03:15 PM GMT+05:30"
    final dateStr = DateFormat("dd/MM/yy hh:mm a").format(timestamp);
    final timestampFormatted = "$dateStr GMT+05:30";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Top "GPS Map Camera" Badge
        if (showHeaderBadge)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xE6322F1D), // Dark olive/charcoal translucent
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera Icon with gradient lens
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFFBBF24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "GPS Map Camera",
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom Stamped Geo Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xE82B2816), // Characteristic dark olive tint
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mini Satellite Map Thumbnail with Red Google Pin
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 96,
                  height: 96,
                  color: const Color(0xFF1E293B),
                  child: Stack(
                    children: [
                      // Satellite Tile
                      Positioned.fill(
                        child: Image.network(
                          addressData.satelliteTileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF1F2937),
                            child: const Center(
                              child: Icon(Icons.satellite_alt_rounded, color: Colors.white38, size: 28),
                            ),
                          ),
                        ),
                      ),

                      // Red Google Map Marker Pin in Center
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pin shadow
                            Transform.translate(
                              offset: const Offset(1, 1),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.black54,
                                size: 36,
                              ),
                            ),
                            // Red Map Pin
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFEA4335), // Google Red
                              size: 34,
                            ),
                            // Inner white/dark ring dot
                            Positioned(
                              top: 8,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB91C1C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Google Brand Watermark on Satellite Tile
                      Positioned(
                        left: 4,
                        bottom: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            "Google",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Address and Coordinates Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Title
                    Text(
                      addressData.locationTitle,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Street Address / Plus Code
                    Text(
                      addressData.streetAddress,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFF1F5F9),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Locality Code
                    Text(
                      addressData.localityCode,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFE2E8F0),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Latitude
                    Text(
                      "Lat ${latitude.toStringAsFixed(6)}°",
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),

                    // Longitude
                    Text(
                      "Long ${longitude.toStringAsFixed(6)}°",
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Date & Time with Timezone
                    Text(
                      timestampFormatted,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFCBD5E1),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper utility to burn/composite the GPS Map Camera watermark into an image
class GpsMapCameraStamper {
  static Future<Uint8List> captureWatermarkedPhoto(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("RenderRepaintBoundary not found on widget key.");
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Failed to encode watermarked image.");
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("Watermark stamping error: $e");
      rethrow;
    }
  }
}
