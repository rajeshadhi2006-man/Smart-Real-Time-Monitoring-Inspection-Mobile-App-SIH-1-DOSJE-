import hashlib
import time
from typing import Optional
from jose import jwt, JWTError
from .config import settings

def create_access_token(data: dict, expires_delta_seconds: int = 86400 * 7) -> str:
    to_encode = data.copy()
    expire = time.time() + expires_delta_seconds
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm="HS256")
    return encoded_jwt

def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        return payload
    except JWTError:
        return None

def compute_evidence_hash(user_id: str, timestamp: str, payload_str: str) -> str:
    content = f"{user_id}:{timestamp}:{payload_str}:{settings.TAMPER_EVIDENCE_SALT}"
    return hashlib.sha256(content.encode("utf-8")).hexdigest()
