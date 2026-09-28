"""
Dedicated SpeechBrain ECAPA-TDNN Speaker Verification Service.

Architecture:
  Real Audio (WAV/PCM) -> Audio Preprocessing (16kHz Mono, Peak Norm) ->
  SpeechBrain ECAPA-TDNN -> 192-D Speaker Embedding -> Cosine Similarity Matching.

Model: speechbrain/spkrec-ecapa-voxceleb
"""

import io
import os
import time
import random
import logging
import threading
from typing import Tuple, Optional, List, Dict, Any

import numpy as np
import soundfile as sf
import torch

from speechbrain.inference.speaker import SpeakerRecognition
from speechbrain.utils.fetching import LocalStrategy

from ..core.config import settings

logger = logging.getLogger("SpeechBrainVoiceService")


class AudioValidationError(Exception):
    """Raised when incoming audio fails format, duration, or quality checks."""
    def __init__(self, message: str, code: str = "AUDIO_INVALID"):
        super().__init__(message)
        self.message = message
        self.code = code


class VoiceVerificationService:
    _instance: Optional["VoiceVerificationService"] = None
    _lock = threading.Lock()

    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model: Optional[SpeakerRecognition] = None
        self.model_name = "speechbrain/spkrec-ecapa-voxceleb"
        self.model_version = "ECAPA-TDNN-192"
        self.embedding_dim = 192
        self.threshold = settings.VOICE_VERIFICATION_THRESHOLD
        self._load_lock = threading.Lock()

    @classmethod
    def get_instance(cls) -> "VoiceVerificationService":
        with cls._lock:
            if cls._instance is None:
                cls._instance = cls()
            return cls._instance

    def load_model(self):
        """Loads SpeechBrain ECAPA-TDNN model once into memory."""
        with self._load_lock:
            if self.model is not None:
                return
            logger.info(f"Loading SpeechBrain ECAPA model ({self.model_name}) on device: {self.device}...")
            start_t = time.perf_counter()
            try:
                os.makedirs(settings.SPEECHBRAIN_MODEL_DIR, exist_ok=True)
                self.model = SpeakerRecognition.from_hparams(
                    source=settings.SPEECHBRAIN_SOURCE,
                    savedir=settings.SPEECHBRAIN_MODEL_DIR,
                    run_opts={"device": self.device},
                    local_strategy=LocalStrategy.COPY,
                )
                load_time_ms = (time.perf_counter() - start_t) * 1000.0
                logger.info(f"SpeechBrain ECAPA model loaded successfully in {load_time_ms:.1f}ms")
            except Exception as e:
                logger.error(f"Failed to load SpeechBrain ECAPA model: {e}")
                raise RuntimeError(f"SpeechBrain model initialization failed: {e}")

    def is_ready(self) -> bool:
        return self.model is not None

    def validate_and_preprocess_audio(self, audio_bytes: bytes) -> Tuple[torch.Tensor, Dict[str, Any]]:
        """
        Validates and converts incoming audio bytes into a normalized 16kHz mono torch Tensor.

        Checks:
        - Non-empty and valid audio header
        - Audio duration >= 1.2s and <= 15.0s
        - Non-corrupted audio stream
        - Non-silent / adequate volume RMS energy
        """
        if not audio_bytes or len(audio_bytes) < 100:
            raise AudioValidationError(
                "Audio data is empty or too small. Please speak clearly for at least 3 seconds.",
                code="AUDIO_TOO_SHORT"
            )

        audio_buffer = io.BytesIO(audio_bytes)
        audio_np: Optional[np.ndarray] = None
        sample_rate: int = settings.VOICE_SAMPLE_RATE
        e_av = None
        e_sf = None
        e_librosa = None

        # 1A. Primary universal decoder: PyAV (decodes WebM, Opus, Ogg, M4A, AAC, MP3, WAV, FLAC)
        try:
            import av
            container = av.open(io.BytesIO(audio_bytes))
            audio_stream = next((s for s in container.streams if s.type == "audio"), None)
            if audio_stream is not None:
                resampler = av.AudioResampler(format="fltp", layout="mono", rate=settings.VOICE_SAMPLE_RATE)
                chunks = []
                for frame in container.decode(audio_stream):
                    for rf in resampler.resample(frame):
                        chunks.append(rf.to_ndarray()[0])
                if chunks:
                    audio_np = np.concatenate(chunks).astype(np.float32)
                    sample_rate = settings.VOICE_SAMPLE_RATE
        except Exception as ex:
            e_av = ex
            logger.debug(f"PyAV decode fallback: {e_av}")

        # 1B. Fallback: Soundfile (WAV, PCM, OGG)
        if audio_np is None:
            try:
                audio_buffer.seek(0)
                audio_np, sample_rate = sf.read(audio_buffer, dtype="float32")
            except Exception as ex:
                e_sf = ex
                # 1C. Fallback: Librosa
                try:
                    import librosa
                    audio_buffer.seek(0)
                    audio_np, sample_rate = librosa.load(audio_buffer, sr=None, mono=False)
                except Exception as ex2:
                    e_librosa = ex2
                    # 1D. Fallback: Raw 16-bit PCM integer stream
                    if len(audio_bytes) % 2 == 0:
                        try:
                            raw_pcm = np.frombuffer(audio_bytes, dtype=np.int16).astype(np.float32) / 32768.0
                            if len(raw_pcm) >= 16000 * 0.8:
                                audio_np = raw_pcm
                                sample_rate = settings.VOICE_SAMPLE_RATE
                        except Exception:
                            pass
                    if audio_np is None:
                        logger.warning(f"Audio decoding failed across all decoders: av={e_av}, sf={e_sf}, librosa={e_librosa}")
                        raise AudioValidationError(
                            "Corrupted or unsupported audio format. Standard audio (WAV/WebM/Opus/MP4/M4A) supported.",
                            code="CORRUPTED_AUDIO"
                        )

        if audio_np is None or len(audio_np) == 0:
            raise AudioValidationError("Decoded audio contains no samples.", code="EMPTY_AUDIO")

        # 2. Convert to Mono
        if audio_np.ndim > 1:
            audio_np = np.mean(audio_np, axis=1)

        # 3. Resample to 16,000 Hz if necessary
        target_sr = settings.VOICE_SAMPLE_RATE
        if sample_rate != target_sr:
            import librosa
            audio_np = librosa.resample(audio_np, orig_sr=sample_rate, target_sr=target_sr)
            sample_rate = target_sr

        # 4. Duration check
        duration_s = float(len(audio_np)) / float(target_sr)
        if duration_s < settings.VOICE_MIN_DURATION_SEC:
            raise AudioValidationError(
                f"Audio recording too short ({duration_s:.1f}s). Minimum required duration is {settings.VOICE_MIN_DURATION_SEC}s.",
                code="INSUFFICIENT_DURATION"
            )
        if duration_s > settings.VOICE_MAX_DURATION_SEC:
            # Safely slice to maximum allowed duration
            audio_np = audio_np[: int(target_sr * settings.VOICE_MAX_DURATION_SEC)]
            duration_s = settings.VOICE_MAX_DURATION_SEC

        # 5. Volume & RMS Silence check
        rms_energy = float(np.sqrt(np.mean(audio_np ** 2)))
        if rms_energy < 0.0001:
            raise AudioValidationError(
                f"Audio recording volume is too low or silent (RMS={rms_energy:.6f}). Please speak closer to the microphone.",
                code="LOW_VOLUME"
            )

        # 6. Peak Normalization (scale-invariant speech feature extraction)
        peak = float(np.max(np.abs(audio_np)))
        if peak > 1e-6:
            audio_np = (audio_np / peak) * 0.9

        # 7. Convert to torch tensor with shape (1, num_samples)
        tensor = torch.from_numpy(audio_np).unsqueeze(0).to(self.device)

        metadata = {
            "duration_s": round(duration_s, 2),
            "sample_rate": target_sr,
            "samples": len(audio_np),
            "rms_energy": round(rms_energy, 6),
            "channels": 1,
        }
        return tensor, metadata

    def extract_embedding(self, audio_tensor: torch.Tensor) -> np.ndarray:
        """
        Runs SpeechBrain ECAPA-TDNN forward pass to generate a 192-dimensional speaker embedding.
        L2-normalizes the embedding vector.
        """
        if self.model is None:
            self.load_model()

        with torch.no_grad():
            # ECAPA-TDNN expects (batch, time_steps)
            embeddings = self.model.encode_batch(audio_tensor)  # Shape: (1, 1, 192)
            embedding = embeddings.squeeze().cpu()  # Shape: (192,)
            # L2 Normalize
            norm_emb = torch.nn.functional.normalize(embedding, p=2, dim=0)
            return norm_emb.numpy().astype(np.float32)

    def combine_enrollment_embeddings(self, embeddings_list: List[np.ndarray]) -> np.ndarray:
        """
        Combines multiple voice enrollment sample embeddings (e.g. 3-5 samples)
        into a single robust, registered speaker profile vector.
        """
        if not embeddings_list:
            raise ValueError("No embeddings provided for enrollment.")

        # Mean vector across enrollment samples
        stacked = np.array(embeddings_list, dtype=np.float32)
        mean_vector = np.mean(stacked, axis=0)

        # Re-normalize combined vector to unit hypersphere
        norm = np.linalg.norm(mean_vector)
        if norm > 1e-6:
            mean_vector = mean_vector / norm
        return mean_vector

    def compute_similarity(self, embedding_a: np.ndarray, embedding_b: np.ndarray) -> float:
        """
        Calculates cosine similarity between two normalized 192-D speaker embeddings.
        Returns a float between -1.0 and 1.0 (typically 0.0 to 1.0 for speech).
        """
        norm_a = np.linalg.norm(embedding_a)
        norm_b = np.linalg.norm(embedding_b)
        if norm_a < 1e-6 or norm_b < 1e-6:
            return 0.0
        dot = float(np.dot(embedding_a, embedding_b))
        sim = dot / (norm_a * norm_b)
        return float(np.clip(sim, -1.0, 1.0))

    def verify_speaker(
        self,
        probe_embedding: np.ndarray,
        enrolled_embedding: np.ndarray,
        custom_threshold: Optional[float] = None
    ) -> Tuple[bool, float, float]:
        """
        Compares live probe embedding with enrolled profile.
        Returns: (verified: bool, raw_score: float, threshold: float)
        """
        threshold = custom_threshold if custom_threshold is not None else settings.VOICE_VERIFICATION_THRESHOLD
        similarity = self.compute_similarity(probe_embedding, enrolled_embedding)
        verified = bool(similarity >= threshold)
        return verified, round(similarity, 4), threshold

    @staticmethod
    def generate_challenge_phrase() -> Dict[str, str]:
        """
        Generates a dynamic, one-time anti-spoofing challenge verification phrase.
        Ensures temporal freshness to prevent pre-recorded replay attacks.
        """
        actions = [
            "Government field verification",
            "DoSJE tactical inspection protocol",
            "Official biometric surveillance check",
            "Authorized site audit confirmation",
            "National MoSJE inspector validation",
        ]
        action = random.choice(actions)
        code = random.randint(100, 999)
        nonce = f"nonce_{int(time.time())}_{random.randint(1000, 9999)}"
        phrase = f"{action} {code}"
        return {
            "challenge_phrase": phrase,
            "nonce": nonce,
            "timestamp": str(int(time.time())),
        }


# Global instance
voice_service = VoiceVerificationService.get_instance()
