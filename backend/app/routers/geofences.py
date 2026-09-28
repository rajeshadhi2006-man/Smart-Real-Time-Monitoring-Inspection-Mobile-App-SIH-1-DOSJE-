"""
Geofences & Geofence Events API Router.

FIXED:
- Removed hardcoded Coimbatore fallback geofence — returns 404 if no geofence configured
- Added GET /api/geofences/assigned/{user_id} for per-user geofence assignment
"""
import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from ..services.supabase_service import supabase_db

logger = logging.getLogger("MoSJEGeofences")

router = APIRouter(prefix="/api/geofences", tags=["Geofences & Assignments"])


class GeofenceCreate(BaseModel):
    name: str
    center_latitude: float
    center_longitude: float
    radius_meters: float
    department: Optional[str] = "Field Operations"
    description: Optional[str] = None


@router.get("")
def get_geofences():
    """Returns all active geofences from Supabase."""
    if supabase_db.client:
        try:
            res = supabase_db.client.table("geofences").select("*").limit(50).execute()
            if res.data and len(res.data) > 0:
                return res.data
        except Exception as e:
            logger.warning(f"Geofences Supabase query failed: {e}")

    # FIXED: No longer returns hardcoded Coimbatore geofence as fallback.
    # Return an empty list — the client should handle "no geofences configured" gracefully.
    return []


@router.get("/assigned/{user_id}")
def get_assigned_geofence_for_user(user_id: str):
    """
    Returns the geofence assigned to a specific user/officer.
    Checks user_geofence_assignments table joined with geofences.
    Returns 404 if no geofence is assigned (not a fake default).
    """
    if not user_id or not user_id.strip():
        raise HTTPException(status_code=400, detail="user_id is required.")

    if supabase_db.client:
        # First: check geofence_assignments table
        try:
            res = (
                supabase_db.client
                .table("geofence_assignments")
                .select("*, geofences(*)")
                .eq("officer_id", user_id)
                .eq("status", "ACTIVE")
                .limit(1)
                .execute()
            )
            if res.data and len(res.data) > 0:
                assignment = res.data[0]
                geofence = assignment.get("geofences")
                if geofence:
                    return {
                        "assignment_id": assignment.get("id"),
                        "user_id": user_id,
                        "officer_id": assignment.get("officer_id"),
                        "geofence_id": geofence.get("id"),
                        "name": geofence.get("name"),
                        "center_latitude": geofence.get("center_latitude"),
                        "center_longitude": geofence.get("center_longitude"),
                        "radius_meters": geofence.get("radius_meters"),
                        "department": geofence.get("department"),
                        "description": geofence.get("description"),
                        "is_active": geofence.get("is_active", True),
                    }
        except Exception as e:
            logger.warning(f"geofence_assignments lookup failed: {e}")

        # Second: check assignments table for a geofence_id field
        try:
            res = (
                supabase_db.client
                .table("assignments")
                .select("*")
                .eq("user_id", user_id)
                .eq("status", "ACTIVE")
                .limit(1)
                .execute()
            )
            if res.data and len(res.data) > 0:
                assignment = res.data[0]
                geo_lat = assignment.get("latitude")
                geo_lng = assignment.get("longitude")
                if geo_lat and geo_lng:
                    return {
                        "assignment_id": assignment.get("id"),
                        "user_id": user_id,
                        "geofence_id": assignment.get("geofence_id", assignment.get("id")),
                        "name": assignment.get("area_name") or assignment.get("name", "Assigned Work Area"),
                        "center_latitude": float(geo_lat),
                        "center_longitude": float(geo_lng),
                        "radius_meters": float(assignment.get("radius_meters") or assignment.get("radius") or 200.0),
                        "department": assignment.get("department", "Field Operations"),
                        "description": assignment.get("description"),
                        "is_active": True,
                    }
        except Exception as e:
            logger.warning(f"assignments lookup for geofence failed: {e}")

    # No geofence found — return 404 (not a hardcoded fake geofence)
    raise HTTPException(
        status_code=404,
        detail=f"No active geofence assignment found for user {user_id}. Please contact your supervisor.",
    )


@router.post("")
def create_geofence(geo: GeofenceCreate):
    """Creates a new geofence in Supabase."""
    record = geo.dict()
    if supabase_db.client:
        try:
            res = supabase_db.client.table("geofences").insert(record).execute()
            if res.data:
                logger.info(f"Geofence created: {res.data[0].get('id')}")
                return res.data[0]
        except Exception as e:
            logger.error(f"Create geofence failed: {e}")
            raise HTTPException(status_code=500, detail="Failed to create geofence.")
    raise HTTPException(status_code=503, detail="Database unavailable.")


@router.delete("/{geofence_id}")
def delete_geofence(geofence_id: str):
    """Deletes a geofence by ID."""
    if supabase_db.client:
        try:
            supabase_db.client.table("geofences").delete().eq("id", geofence_id).execute()
            return {"status": "DELETED", "id": geofence_id}
        except Exception as e:
            logger.error(f"Delete geofence failed: {e}")
            raise HTTPException(status_code=500, detail="Failed to delete geofence.")
    raise HTTPException(status_code=503, detail="Database unavailable.")
