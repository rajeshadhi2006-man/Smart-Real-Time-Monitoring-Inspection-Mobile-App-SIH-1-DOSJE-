"""
Location Telemetry & Geofence Events API Router.

FIXED:
- Added POST /api/geofence/entry for real geofence entry events
- Added POST /api/geofence/exit for real geofence exit events
- Location updates now log to Supabase with real data
"""
import logging
import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from ..services.supabase_service import supabase_db

logger = logging.getLogger("MoSJELocation")

router = APIRouter(prefix="/api/location", tags=["Location Telemetry"])


class LocationUpdateRequest(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    accuracy: float = 5.0
    speed: float = 0.0
    heading: float = 0.0
    altitude: float = 0.0
    is_inside_geofence: bool = False  # FIXED: was True (fake default)
    geofence_id: Optional[str] = None
    geofence_name: Optional[str] = None
    battery_percentage: Optional[int] = None


class GeofenceEventRequest(BaseModel):
    user_id: str
    officer_id: Optional[str] = None
    geofence_id: str
    geofence_name: Optional[str] = None
    latitude: float
    longitude: float
    accuracy: float
    event_type: str  # "ENTRY" or "EXIT"
    timestamp: Optional[str] = None


@router.post("/update")
def update_location(req: LocationUpdateRequest):
    """
    Logs a real GPS location update to Supabase.
    Validates that coordinates are reasonable (not hardcoded fallback values).
    """
    # Basic coordinate sanity check
    if not (-90 <= req.latitude <= 90) or not (-180 <= req.longitude <= 180):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid coordinates: lat={req.latitude}, lng={req.longitude}"
        )

    record = {
        "user_id": req.user_id,
        "latitude": req.latitude,
        "longitude": req.longitude,
        "accuracy": req.accuracy,
        "speed": req.speed,
        "heading": req.heading,
        "altitude": req.altitude,
        "is_inside_geofence": req.is_inside_geofence,
        "geofence_id": req.geofence_id,
        "geofence_name": req.geofence_name,
        "battery_percentage": req.battery_percentage,
    }

    logged = False
    if supabase_db.client:
        try:
            supabase_db.client.table("location_updates").insert(record).execute()
            logged = True
            logger.info(
                f"[LOCATION] user={req.user_id} lat={req.latitude:.6f} lng={req.longitude:.6f} "
                f"accuracy={req.accuracy:.1f}m inside={req.is_inside_geofence}"
            )
        except Exception as e:
            logger.warning(f"[LOCATION] Supabase insert failed: {e}")

    return {
        "status": "SUCCESS",
        "logged": logged,
        "message": "Location telemetry logged." if logged else "Location received (database temporarily unavailable).",
    }


@router.post("/geofence/entry")
def record_geofence_entry(req: GeofenceEventRequest):
    """
    Records a real geofence ENTRY event.
    Called when the user's GPS transitions from outside → inside the assigned geofence.
    """
    logger.info(
        f"[GEOFENCE ENTRY] user={req.user_id} geofence={req.geofence_id} "
        f"lat={req.latitude:.6f} lng={req.longitude:.6f} accuracy={req.accuracy:.1f}m"
    )

    event_time = req.timestamp or datetime.datetime.now(datetime.timezone.utc).isoformat()

    event_record = {
        "user_id": req.user_id,
        "officer_id": req.officer_id or req.user_id,
        "geofence_id": req.geofence_id,
        "geofence_name": req.geofence_name,
        "event_type": "ENTRY",
        "latitude": req.latitude,
        "longitude": req.longitude,
        "accuracy": req.accuracy,
        "timestamp": event_time,
    }

    saved = False
    if supabase_db.client:
        try:
            supabase_db.client.table("geofence_events").insert(event_record).execute()
            saved = True
        except Exception as e:
            logger.warning(f"[GEOFENCE ENTRY] Supabase save failed: {e}")

    return {
        "status": "ENTRY_RECORDED",
        "event_type": "ENTRY",
        "user_id": req.user_id,
        "geofence_id": req.geofence_id,
        "timestamp": event_time,
        "saved_to_database": saved,
        "message": "Geofence entry recorded.",
    }


@router.post("/geofence/exit")
def record_geofence_exit(req: GeofenceEventRequest):
    """
    Records a real geofence EXIT event.
    Called when the user's GPS transitions from inside → outside the assigned geofence.
    """
    logger.info(
        f"[GEOFENCE EXIT] user={req.user_id} geofence={req.geofence_id} "
        f"lat={req.latitude:.6f} lng={req.longitude:.6f} accuracy={req.accuracy:.1f}m"
    )

    event_time = req.timestamp or datetime.datetime.now(datetime.timezone.utc).isoformat()

    event_record = {
        "user_id": req.user_id,
        "officer_id": req.officer_id or req.user_id,
        "geofence_id": req.geofence_id,
        "geofence_name": req.geofence_name,
        "event_type": "EXIT",
        "latitude": req.latitude,
        "longitude": req.longitude,
        "accuracy": req.accuracy,
        "timestamp": event_time,
    }

    saved = False
    if supabase_db.client:
        try:
            supabase_db.client.table("geofence_events").insert(event_record).execute()
            saved = True
        except Exception as e:
            logger.warning(f"[GEOFENCE EXIT] Supabase save failed: {e}")

    return {
        "status": "EXIT_RECORDED",
        "event_type": "EXIT",
        "user_id": req.user_id,
        "geofence_id": req.geofence_id,
        "timestamp": event_time,
        "saved_to_database": saved,
        "message": "Geofence exit recorded.",
    }
