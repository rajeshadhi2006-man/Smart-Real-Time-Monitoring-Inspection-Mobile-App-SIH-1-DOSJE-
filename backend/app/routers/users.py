from fastapi import APIRouter
from typing import Optional, List
from ..services.supabase_service import supabase_db

router = APIRouter(prefix="/api/users", tags=["Users"])

@router.get("")
def get_users():
    if supabase_db.client:
        try:
            res = supabase_db.client.table("profiles").select("*").limit(50).execute()
            if res.data and len(res.data) > 0:
                return res.data
        except Exception:
            pass

    return [
        {
            "id": "USR-001",
            "officer_id": "OFF-001",
            "full_name": "Field Inspector Rajesh",
            "email": "officer@surveillance.gov.in",
            "role": "OFFICER",
            "department": "Field Surveillance Unit",
            "is_active": True
        }
    ]
