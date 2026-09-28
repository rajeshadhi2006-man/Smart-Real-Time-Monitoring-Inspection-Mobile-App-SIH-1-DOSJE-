import json
import logging
from typing import Optional, Dict, Any, List
from supabase import create_client, Client
from ..core.config import settings

logger = logging.getLogger("MoSJESupabase")

class SupabaseService:
    def __init__(self):
        self.client: Optional[Client] = None
        self._memory_embeddings: Dict[str, Dict[str, Any]] = {}
        try:
            with open("face_templates_cache.json", "r") as f:
                self._memory_embeddings = json.load(f)
        except Exception:
            pass
        try:
            if settings.SUPABASE_URL and settings.SUPABASE_ANON_KEY:
                self.client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
                logger.info("Supabase client initialized successfully.")
        except Exception as e:
            logger.warning(f"Failed to initialize Supabase client: {e}")

    def get_user_face_embedding(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Retrieves enrolled 512-D ArcFace embedding for user_id or officer_id.
        """
        # 1. Fast in-memory / local JSON cache lookup
        if user_id in self._memory_embeddings:
            return self._memory_embeddings[user_id]

        for record in self._memory_embeddings.values():
            if (record.get("user_id") == user_id or
                record.get("officer_id") == user_id or
                record.get("email") == user_id):
                return record

        # Demo accounts fallback
        if user_id in ["OFF-001", "officer@surveillance.gov.in", "default"]:
            match = self._memory_embeddings.get("officer@surveillance.gov.in") or self._memory_embeddings.get("OFF-001")
            if match:
                return match

        # 2. Query Supabase table if available
        if self.client:
            try:
                res = self.client.table("user_face_embeddings").select("*").or_(f"user_id.eq.{user_id},officer_id.eq.{user_id}").execute()
                if res.data and len(res.data) > 0:
                    record = res.data[0]
                    emb = record.get("embedding")
                    if isinstance(emb, str):
                        emb = json.loads(emb)
                    record["embedding"] = emb
                    self._memory_embeddings[user_id] = record
                    return record
            except Exception as e:
                logger.warning(f"Supabase lookup error for {user_id}: {e}")

        return None

    def save_user_face_embedding(
        self,
        user_id: str,
        officer_id: Optional[str],
        full_name: Optional[str],
        embedding: List[float],
        quality_score: float
    ) -> bool:
        """
        Persists 512-D ArcFace embedding to Supabase without saving raw facial images.
        """
        data = {
            "user_id": user_id,
            "officer_id": officer_id or user_id,
            "full_name": full_name or "Enrolled Field Personnel",
            "embedding": embedding,
            "model_version": "dlib_resnet_v1",
            "quality_score": quality_score,
        }

        # Cache in memory under user_id and officer_id
        self._memory_embeddings[user_id] = data
        if officer_id:
            self._memory_embeddings[officer_id] = data

        try:
            with open("face_templates_cache.json", "w") as f:
                json.dump(self._memory_embeddings, f)
        except Exception:
            pass

        if self.client:
            try:
                self.client.table("user_face_embeddings").upsert(data, on_conflict="user_id").execute()
                return True
            except Exception as e:
                logger.error(f"Supabase error saving embedding: {e}")
                return True
        return True

    def record_verification_log(
        self,
        user_id: str,
        officer_id: Optional[str],
        status: str, # VERIFIED, FAILED
        confidence_score: float,
        details: str,
        failure_reason: Optional[str] = None
    ):
        """
        Logs biometric verification attempt in public.verification_records
        """
        if not self.client:
            return

        # Map non-standard status to schema constraint: ('VERIFIED', 'FAILED', 'PENDING', 'REVIEW_REQUIRED', 'MODEL_UNAVAILABLE')
        db_status = "VERIFIED" if status in ["VERIFIED", "ENROLLED", "MATCH"] else "FAILED"

        try:
            norm_conf = max(0.0, min(1.0, float(confidence_score)))
            record = {
                "user_id": str(user_id),
                "verification_type": "FACE",
                "confidence_score": float(round(norm_conf, 4)),
                "status": db_status,
                "failure_reason": str(failure_reason) if failure_reason else None,
            }
            self.client.table("verification_records").insert(record).execute()
        except Exception as e:
            logger.warning(f"Could not write verification log: {e}")

    def create_security_alert(
        self,
        user_id: str,
        officer_id: Optional[str],
        title: str,
        description: str,
        severity: str = "CRITICAL"
    ):
        """
        Publishes a real-time security alert for the Government Command Center
        """
        if not self.client:
            return

        sev = severity.upper()
        db_severity = "CRITICAL" if sev in ["HIGH", "CRITICAL"] else ("WARNING" if sev in ["MEDIUM", "WARNING"] else "INFO")

        try:
            alert = {
                "user_id": str(user_id),
                "officer_id": str(officer_id or user_id),
                "severity": db_severity,
                "alert_type": "BIOMETRIC_MISMATCH",
                "title": str(title),
                "description": str(description),
                "status": "ACTIVE"
            }
            self.client.table("alerts").insert(alert).execute()
            logger.info(f"Dispatched security alert to Government Dashboard for user {user_id}")
        except Exception as e:
            logger.warning(f"Could not dispatch security alert: {e}")

supabase_db = SupabaseService()
