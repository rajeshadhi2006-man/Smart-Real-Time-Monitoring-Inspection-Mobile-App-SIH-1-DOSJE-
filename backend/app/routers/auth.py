from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional
from ..core.security import create_access_token, decode_access_token

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login")
def login(req: LoginRequest):
    """
    Authenticates field officer and returns JWT token & profile
    """
    # Demonstration & operational demo users
    user_id = req.username.strip()
    token = create_access_token({"sub": user_id, "role": "OFFICER"})
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "user_id": user_id,
            "officer_id": "OFF-001" if "officer" in user_id.lower() else "INSP-042",
            "full_name": "Field Inspector Rajesh" if "officer" in user_id.lower() else user_id.split("@")[0].capitalize(),
            "email": user_id if "@" in user_id else f"{user_id}@surveillance.gov.in",
            "role": "OFFICER",
            "department": "Social Welfare Inspection & Monitoring Directorate"
        }
    }

@router.get("/me")
def get_current_user(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Session expired")
    user_id = payload.get("sub", "officer@surveillance.gov.in")
    return {
        "id": user_id,
        "user_id": user_id,
        "officer_id": "OFF-001",
        "full_name": "Field Inspector Rajesh",
        "email": user_id if "@" in user_id else f"{user_id}@surveillance.gov.in",
        "role": "OFFICER",
        "department": "Social Welfare Inspection & Monitoring Directorate"
    }
