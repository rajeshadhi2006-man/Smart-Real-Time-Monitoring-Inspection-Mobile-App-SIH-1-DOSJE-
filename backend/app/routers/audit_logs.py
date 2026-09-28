from fastapi import APIRouter
from typing import Optional, List
from ..services.supabase_service import supabase_db

router = APIRouter(prefix="/api/audit-logs", tags=["Audit Logs"])

@router.get("")
def get_audit_logs():
    if supabase_db.client:
        try:
            res = supabase_db.client.table("audit_logs").select("*").order("created_at", desc=True).limit(50).execute()
            if res.data and len(res.data) > 0:
                return res.data
        except Exception:
            pass

    return []
