"""
Production ArcFace Neural Biometric Service.

Implements deep metric face representation using official ArcFace ONNX model:
1. Canonical 5-Point Facial Landmark Detection & Affine Alignment (112x112)
2. BGR to RGB color conversion
3. InsightFace normalization: (x - 127.5) / 128.0
4. Deep ResNet ArcFace feature extraction -> 512-D vector
5. L2 unit-norm embedding projection
6. Cosine similarity matching with configurable threshold (default: 0.65)
"""

import os
import logging
from typing import List, Optional, Tuple
import numpy as np
import cv2
import onnxruntime as ort

from .face_detector import detector, DetectedFace
from .face_alignment import aligner

logger = logging.getLogger("MoSJEBiometric")

MODEL_PATH = os.path.join(os.path.dirname(__file__), "../../models/arcface.onnx")

class ArcFaceService:
    def __init__(self):
        self.session: Optional[ort.InferenceSession] = None
        self.input_name: Optional[str] = None
        self.output_name: Optional[str] = None
        self.embedding_dim: int = 512
        self._load_model()

    def _load_model(self):
        """Loads ArcFace ONNX session with hardware optimizations."""
        abs_model_path = os.path.abspath(MODEL_PATH)
        if not os.path.exists(abs_model_path):
            logger.error(f"[ArcFace] Model file not found at: {abs_model_path}")
            return

        try:
            opts = ort.SessionOptions()
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            opts.intra_op_num_threads = 4

            self.session = ort.InferenceSession(abs_model_path, sess_options=opts, providers=['CPUExecutionProvider'])
            self.input_name = self.session.get_inputs()[0].name
            self.output_name = self.session.get_outputs()[0].name
            out_shape = self.session.get_outputs()[0].shape
            self.embedding_dim = out_shape[1] if len(out_shape) > 1 and isinstance(out_shape[1], int) else 512

            logger.info("[ARCFACE] Model loaded")
            logger.info(
                f"[ArcFace] Model loaded successfully from {abs_model_path}: "
                f"input='{self.input_name}', output='{self.output_name}', dim={self.embedding_dim}"
            )
        except Exception as e:
            logger.error(f"[ArcFace] Error loading ONNX model: {e}")
            self.session = None

    def preprocess_aligned_face(self, aligned_bgr: np.ndarray) -> np.ndarray:
        """
        Prepares a 112x112 BGR face chip for ArcFace:
        - BGR to RGB
        - Ensure (112, 112, 3)
        - Normalize: (pixel - 127.5) / 128.0
        - Add batch dimension: shape (1, 112, 112, 3) float32
        """
        input_dims = (aligned_bgr.shape[0], aligned_bgr.shape[1])
        if aligned_bgr.shape[:2] != (112, 112):
            aligned_bgr = cv2.resize(aligned_bgr, (112, 112), interpolation=cv2.INTER_CUBIC)

        rgb = cv2.cvtColor(aligned_bgr, cv2.COLOR_BGR2RGB)
        normalized = (rgb.astype(np.float32) - 127.5) / 128.0
        tensor = np.expand_dims(normalized, axis=0)

        logger.info(f"[FACE] Input dimensions = {input_dims}")
        logger.info(f"[FACE] Model input dimensions = (112, 112, 3)")
        logger.info(f"[FACE] Pixel format = RGB")
        logger.info(f"[FACE] Tensor shape = {tensor.shape}")

        return tensor

    def extract_embedding_from_aligned(self, aligned_bgr: np.ndarray) -> Optional[np.ndarray]:
        """
        Extracts 512-D L2-normalized embedding directly from an aligned 112x112 face chip.
        """
        if self.session is None:
            self._load_model()
            if self.session is None:
                logger.error("[ArcFace] Model session unavailable.")
                return None

        try:
            tensor = self.preprocess_aligned_face(aligned_bgr)
            raw_emb = self.session.run([self.output_name], {self.input_name: tensor})[0][0]

            # Verify no NaN or Inf
            is_valid = not (np.isnan(raw_emb).any() or np.isinf(raw_emb).any())
            if not is_valid:
                logger.error("[ARCFACE] Embedding valid = false")
                return None

            # L2 unit-norm normalization
            norm = np.linalg.norm(raw_emb)
            if norm == 0:
                logger.error("[ARCFACE] Embedding valid = false")
                return None

            l2_embedding = (raw_emb / norm).astype(np.float32)
            logger.info(f"[ARCFACE] Embedding dimension = {len(l2_embedding)}")
            logger.info("[ARCFACE] Embedding valid = true")
            return l2_embedding
        except Exception as e:
            logger.error(f"[ArcFace] Inference error: {e}")
            logger.error("[ARCFACE] Embedding valid = false")
            return None

    def detect_and_encode_face(self, image_bgr: np.ndarray) -> Optional[np.ndarray]:
        """
        Complete ArcFace Pipeline:
        Camera Frame -> Face Detection -> 5-Point Alignment -> 112x112 RGB -> ArcFace -> L2 Norm Embedding
        Returns 512-D normalized vector, or None if no face detected.
        """
        if image_bgr is None or image_bgr.size == 0:
            return None

        # 1. Detect faces and extract 5 canonical landmarks
        faces: List[DetectedFace] = detector.detect_faces(image_bgr)
        if not faces:
            # Try rotated orientations if camera sensor orientation wasn't portrait
            for rot in [cv2.ROTATE_90_CLOCKWISE, cv2.ROTATE_180, cv2.ROTATE_90_COUNTERCLOCKWISE]:
                rot_img = cv2.rotate(image_bgr, rot)
                faces = detector.detect_faces(rot_img)
                if faces:
                    image_bgr = rot_img
                    break

        if not faces:
            logger.warning("[ArcFace] No face detected in frame.")
            return None

        # Take largest detected face
        primary_face = max(faces, key=lambda f: f.bbox[2] * f.bbox[3])

        # 2. Canonical 5-point affine alignment to 112x112 ArcFace template
        aligned_chip = aligner.align_face(image_bgr, primary_face.landmarks, output_size=(112, 112))

        # 3. Model inference and L2 normalization
        return self.extract_embedding_from_aligned(aligned_chip)

    def extract_embedding(self, aligned_bgr: np.ndarray) -> Optional[np.ndarray]:
        """Convenience alias matching test pipeline."""
        return self.extract_embedding_from_aligned(aligned_bgr)

    def count_faces(self, image_bgr: np.ndarray) -> int:
        """Returns the number of detected faces in the image."""
        if image_bgr is None or image_bgr.size == 0:
            return 0
        faces = detector.detect_faces(image_bgr)
        if not faces:
            for rot in [cv2.ROTATE_90_CLOCKWISE, cv2.ROTATE_180, cv2.ROTATE_90_COUNTERCLOCKWISE]:
                rot_img = cv2.rotate(image_bgr, rot)
                faces = detector.detect_faces(rot_img)
                if faces:
                    break
        if not faces:
            return 0
        # Filter out minor noise or background artifacts (< 30% area of the largest face)
        max_area = max(f.bbox[2] * f.bbox[3] for f in faces)
        significant = [f for f in faces if (f.bbox[2] * f.bbox[3]) >= 0.30 * max_area]
        return len(significant)

    @staticmethod
    def calculate_similarity(embedding_a: List[float], embedding_b: List[float]) -> float:
        """
        Calculates cosine similarity between two 512-D normalized ArcFace embeddings.
        Cosine similarity: dot(A, B) / (norm(A) * norm(B))
        Since embeddings are L2 normalized, this is simply the dot product.
        Range: [0.0, 1.0] where >= 0.65 indicates verified identity match.
        """
        if embedding_a is None or embedding_b is None:
            return 0.0

        a = np.array(embedding_a, dtype=np.float32).flatten()
        b = np.array(embedding_b, dtype=np.float32).flatten()

        if a.size == 0 or b.size == 0:
            return 0.0

        if a.shape != b.shape:
            return 0.0

        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)

        if norm_a == 0.0 or norm_b == 0.0:
            return 0.0

        cos_sim = float(np.dot(a, b) / (norm_a * norm_b))
        # Clamp to [0.0, 1.0]
        return round(float(max(0.0, min(1.0, cos_sim))), 4)


# Global Singleton
arcface_engine = ArcFaceService()
