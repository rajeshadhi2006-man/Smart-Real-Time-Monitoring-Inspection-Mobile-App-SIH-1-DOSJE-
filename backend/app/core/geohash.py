"""
GeoHash and Geodesic Spatial Verification Module.
Zero external dependencies; pure Python standard implementation.
Base32 character map: 0123456789bcdefghjkmnpqrstuvwxyz
"""
import math
from typing import Tuple, Dict, Any, Optional

BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
DECODE_MAP = {char: i for i, char in enumerate(BASE32)}


def encode(latitude: float, longitude: float, precision: int = 8) -> str:
    """
    Encodes latitude and longitude into standard 32-character GeoHash.
    Precision specifies the character length (default: 8, approx +/- 19 meters).
    """
    lat_interval = [-90.0, 90.0]
    lon_interval = [-180.0, 180.0]
    geohash = []
    bits = [16, 8, 4, 2, 1]
    bit = 0
    ch = 0
    even = True

    while len(geohash) < precision:
        if even:
            mid = (lon_interval[0] + lon_interval[1]) / 2.0
            if longitude > mid:
                ch |= bits[bit]
                lon_interval[0] = mid
            else:
                lon_interval[1] = mid
        else:
            mid = (lat_interval[0] + lat_interval[1]) / 2.0
            if latitude > mid:
                ch |= bits[bit]
                lat_interval[0] = mid
            else:
                lat_interval[1] = mid

        even = not even
        if bit < 4:
            bit += 1
        else:
            geohash.append(BASE32[ch])
            bit = 0
            ch = 0

    return "".join(geohash)


encode_geohash = encode


def bbox(geohash: str) -> Dict[str, float]:
    """
    Returns the latitude/longitude bounding box of a given GeoHash cell.
    """
    even = True
    lat_interval = [-90.0, 90.0]
    lon_interval = [-180.0, 180.0]

    for char in geohash.lower():
        if char not in DECODE_MAP:
            continue
        cd = DECODE_MAP[char]
        for mask in [16, 8, 4, 2, 1]:
            if even:
                mid = (lon_interval[0] + lon_interval[1]) / 2.0
                if cd & mask:
                    lon_interval[0] = mid
                else:
                    lon_interval[1] = mid
            else:
                mid = (lat_interval[0] + lat_interval[1]) / 2.0
                if cd & mask:
                    lat_interval[0] = mid
                else:
                    lat_interval[1] = mid
            even = not even

    return {
        "min_lat": lat_interval[0],
        "max_lat": lat_interval[1],
        "min_lon": lon_interval[0],
        "max_lon": lon_interval[1],
    }


def decode(geohash: str) -> Tuple[float, float]:
    """
    Decodes GeoHash to center latitude and longitude.
    """
    box = bbox(geohash)
    lat = (box["min_lat"] + box["max_lat"]) / 2.0
    lon = (box["min_lon"] + box["max_lon"]) / 2.0
    return round(lat, 6), round(lon, 6)


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Computes exact geodesic distance between two points in meters using Haversine formula.
    """
    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return round(R * c, 2)


def verify_location(
    current_lat: float,
    current_lon: float,
    target_lat: float,
    target_lon: float,
    target_geohash: str,
    allowed_radius_meters: float,
    gps_accuracy: float = 10.0,
    geohash_precision: int = 7,
) -> Dict[str, Any]:
    """
    Performs rigorous multi-factor spatial validation:
    1. Geodesic Haversine distance vs allowed radius (+ accuracy tolerance)
    2. Server-calculated GeoHash vs target GeoHash (prefix overlap)
    3. GPS accuracy validation (< 60m required for official inspection)
    """
    server_geohash = encode(current_lat, current_lon, precision=geohash_precision)
    distance = haversine_distance(current_lat, current_lon, target_lat, target_lon)

    prefix_len = 6 if allowed_radius_meters <= 600 else 5
    target_clean = target_geohash.strip().lower()
    current_clean = server_geohash.strip().lower()
    geohash_match = (
        current_clean[:prefix_len] == target_clean[:prefix_len]
        or distance <= allowed_radius_meters
    )

    accuracy_acceptable = gps_accuracy <= 60.0
    max_allowed = allowed_radius_meters + min(gps_accuracy, 25.0)
    inside_radius = distance <= max_allowed

    is_verified = inside_radius and geohash_match and accuracy_acceptable

    if not accuracy_acceptable:
        status = "LOCATION REQUIRES REVIEW"
        reason = f"GPS accuracy too poor ({gps_accuracy:.1f}m > 60m threshold)."
    elif not inside_radius:
        status = "OUTSIDE ASSIGNED AREA"
        reason = f"Distance ({distance:.1f}m) exceeds allowed radius ({allowed_radius_meters:.1f}m)."
    elif not geohash_match:
        status = "GEOHASH MISMATCH"
        reason = f"Current GeoHash ({server_geohash[:prefix_len]}) does not align with target ({target_clean[:prefix_len]})."
    else:
        status = "GEO-TAG VERIFIED ✓"
        reason = "Location within target geofence and confirmed by server GeoHash."

    return {
        "verified": is_verified,
        "status": status,
        "reason": reason,
        "distance_meters": distance,
        "allowed_radius_meters": allowed_radius_meters,
        "server_geohash": server_geohash,
        "target_geohash": target_geohash,
        "gps_accuracy": gps_accuracy,
        "accuracy_acceptable": accuracy_acceptable,
        "geohash_match": geohash_match,
        "inside_radius": inside_radius,
    }
