from fastapi import APIRouter
from typing import Optional, List
from ..services.supabase_service import supabase_db

router = APIRouter(prefix="/api/alerts", tags=["Government Command Alerts"])

@router.get("")
def get_alerts():
    if supabase_db.client:
        try:
            res = supabase_db.client.table("alerts").select("*").order("created_at", desc=True).limit(50).execute()
            return res.data or []
        except Exception:
            pass
    return []

@router.get("/my-alerts")
def get_my_alerts(user_id: Optional[str] = None):
    if supabase_db.client and user_id:
        try:
            res = supabase_db.client.table("alerts").select("*").eq("user_id", user_id).order("created_at", desc=True).limit(20).execute()
            return res.data or []
        except Exception:
            pass
    return []
