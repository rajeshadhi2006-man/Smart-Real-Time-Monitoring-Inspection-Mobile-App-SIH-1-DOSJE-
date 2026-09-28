"""
Proxy re-export for backend/services/voice_verification.py
"""
from ..app.services.voice_verification import (
    VoiceVerificationService,
    AudioValidationError,
    voice_service,
)

__all__ = [
    "VoiceVerificationService",
    "AudioValidationError",
    "voice_service",
]
