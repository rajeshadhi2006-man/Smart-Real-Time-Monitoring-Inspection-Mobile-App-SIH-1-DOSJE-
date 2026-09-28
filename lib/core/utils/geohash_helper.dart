import 'dart:math' as math;

class GeoBox {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const GeoBox({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  double get centerLat => (minLat + maxLat) / 2.0;
  double get centerLon => (minLon + maxLon) / 2.0;
}

class GeoHashHelper {
  static const String base32 = "0123456789bcdefghjkmnpqrstuvwxyz";

  /// Encodes latitude and longitude into standard GeoHash string.
  static String encode(double latitude, double longitude, {int precision = 8}) {
    List<double> latInterval = [-90.0, 90.0];
    List<double> lonInterval = [-180.0, 180.0];
    StringBuffer geohash = StringBuffer();
    const List<int> bits = [16, 8, 4, 2, 1];
    int bit = 0;
    int ch = 0;
    bool even = true;

    while (geohash.length < precision) {
      if (even) {
        double mid = (lonInterval[0] + lonInterval[1]) / 2.0;
        if (longitude > mid) {
          ch |= bits[bit];
          lonInterval[0] = mid;
        } else {
          lonInterval[1] = mid;
        }
      } else {
        double mid = (latInterval[0] + latInterval[1]) / 2.0;
        if (latitude > mid) {
          ch |= bits[bit];
          latInterval[0] = mid;
        } else {
          latInterval[1] = mid;
        }
      }

      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return geohash.toString();
  }

  /// Computes the bounding box of a GeoHash string.
  static GeoBox boundingBox(String geohash) {
    bool even = true;
    List<double> latInterval = [-90.0, 90.0];
    List<double> lonInterval = [-180.0, 180.0];

    for (int i = 0; i < geohash.length; i++) {
      int cd = base32.indexOf(geohash[i].toLowerCase());
      if (cd == -1) continue;

      for (int mask in [16, 8, 4, 2, 1]) {
        if (even) {
          double mid = (lonInterval[0] + lonInterval[1]) / 2.0;
          if ((cd & mask) != 0) {
            lonInterval[0] = mid;
          } else {
            lonInterval[1] = mid;
          }
        } else {
          double mid = (latInterval[0] + latInterval[1]) / 2.0;
          if ((cd & mask) != 0) {
            latInterval[0] = mid;
          } else {
            latInterval[1] = mid;
          }
        }
        even = !even;
      }
    }

    return GeoBox(
      minLat: latInterval[0],
      maxLat: latInterval[1],
      minLon: lonInterval[0],
      maxLon: lonInterval[1],
    );
  }

  /// Calculates geodesic distance between two points in meters using Haversine.
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (math.pi / 180.0);
  }

  /// Checks if current GeoHash aligns with target GeoHash within acceptable precision.
  static bool matchesTargetGeohash(String current, String target, {int prefixLength = 6}) {
    if (current.isEmpty || target.isEmpty) return false;
    int len = math.min(prefixLength, math.min(current.length, target.length));
    return current.toLowerCase().substring(0, len) == target.toLowerCase().substring(0, len);
  }
}
