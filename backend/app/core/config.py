import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "MoSJE ArcFace Biometric Verification Engine"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api"
    
    # Supabase Configuration
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://ctmkpwwbdexwkakuqpat.supabase.co")
    SUPABASE_ANON_KEY: str = os.getenv(
        "SUPABASE_ANON_KEY",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWtwd3diZGV4d2tha3VxcGF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2MDk4MDAsImV4cCI6MjEwNDE4NTgwMH0.ilxOvgsxXQoD3Rh6pZgmfiEMET5u3RtS-B0W_kOEhLU"
    )
    
    # ArcFace Biometric Thresholds
    FACE_MATCH_THRESHOLD: float = float(os.getenv("FACE_MATCH_THRESHOLD", "0.68")) # Cosine similarity threshold
    MIN_FACE_SIZE: int = int(os.getenv("MIN_FACE_SIZE", "80")) # Min width/height in px
    BLUR_THRESHOLD: float = float(os.getenv("BLUR_THRESHOLD", "65.0")) # Laplacian variance
    MIN_BRIGHTNESS: float = float(os.getenv("MIN_BRIGHTNESS", "40.0")) # Average pixel intensity
    MAX_BRIGHTNESS: float = float(os.getenv("MAX_BRIGHTNESS", "240.0"))
    
    # Model Metadata
    MODEL_VERSION: str = "ArcFace-MobileFaceNet-512"
    EMBEDDING_DIM: int = 512
    
    # Security
    JWT_SECRET: str = os.getenv("JWT_SECRET", "sih_mosje_secure_biometric_jwt_2026")
    TAMPER_EVIDENCE_SALT: str = os.getenv("TAMPER_EVIDENCE_SALT", "mosje_sih_secure_salt_2026")

    # SpeechBrain ECAPA-TDNN Speaker Recognition
    VOICE_VERIFICATION_THRESHOLD: float = float(os.getenv("VOICE_VERIFICATION_THRESHOLD", "0.65")) # Cosine similarity threshold calibrated for ECAPA-TDNN VoxCeleb
    SPEECHBRAIN_SOURCE: str = os.getenv("SPEECHBRAIN_SOURCE", "speechbrain/spkrec-ecapa-voxceleb")
    SPEECHBRAIN_MODEL_DIR: str = os.getenv("SPEECHBRAIN_MODEL_DIR", "models/speechbrain_ecapa")
    VOICE_SAMPLE_RATE: int = 16000
    VOICE_MIN_DURATION_SEC: float = 1.2
    VOICE_MAX_DURATION_SEC: float = 15.0

    class Config:
        case_sensitive = True

settings = Settings()
