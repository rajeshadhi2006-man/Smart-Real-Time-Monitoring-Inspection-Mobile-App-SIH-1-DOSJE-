import cv2
import numpy as np
from typing import Tuple, List, Optional
from ..core.config import settings
from .face_detector import DetectedFace

class QualityCheckResult:
    def __init__(self, is_valid: bool, status_code: str, message: str, metrics: dict):
        self.is_valid = is_valid
        self.status_code = status_code # VALID, NO_FACE, MULTIPLE_FACES, TOO_SMALL, BLURRY, TOO_DARK, TOO_BRIGHT, OFF_CENTER
        self.message = message
        self.metrics = metrics

class FaceQualityChecker:
    @staticmethod
    def evaluate(image: np.ndarray, detected_faces: List[DetectedFace]) -> QualityCheckResult:
        """
        Validates frame quality against multi-dimensional biometric criteria.
        """
        h, w = image.shape[:2]

        # 1. Face Count Check
        if len(detected_faces) == 0:
            return QualityCheckResult(
                is_valid=False,
                status_code="NO_FACE",
                message="No face detected. Please position your face inside the frame.",
                metrics={"face_count": 0}
            )
        
        if len(detected_faces) > 1:
            return QualityCheckResult(
                is_valid=False,
                status_code="MULTIPLE_FACES",
                message="Multiple faces detected. Please ensure only the user is in view.",
                metrics={"face_count": len(detected_faces)}
            )

        face = detected_faces[0]
        fx, fy, fw, fh = face.bbox

        # 2. Face Size Check
        if fw < settings.MIN_FACE_SIZE or fh < settings.MIN_FACE_SIZE:
            return QualityCheckResult(
                is_valid=False,
                status_code="TOO_SMALL",
                message="Face is too far away. Please move closer to the camera.",
                metrics={"face_width": fw, "face_height": fh, "min_size": settings.MIN_FACE_SIZE}
            )

        # 3. Face Centering / Bounding Check
        face_center_x = fx + fw / 2.0
        face_center_y = fy + fh / 2.0
        frame_center_x = w / 2.0
        frame_center_y = h / 2.0

        offset_x = abs(face_center_x - frame_center_x) / (w / 2.0)
        offset_y = abs(face_center_y - frame_center_y) / (h / 2.0)

        if offset_x > 0.60 or offset_y > 0.60:
            return QualityCheckResult(
                is_valid=False,
                status_code="OFF_CENTER",
                message="Keep your face centered inside the frame.",
                metrics={"offset_x": round(offset_x, 2), "offset_y": round(offset_y, 2)}
            )

        # Crop face ROI for photometric & blur evaluation
        face_roi = image[max(0, fy):min(h, fy+fh), max(0, fx):min(w, fx+fw)]
        if face_roi.size == 0:
            face_roi = image

        # 4. Blur / Sharpness Check (Laplacian Variance)
        gray_roi = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY) if len(face_roi.shape) == 3 else face_roi
        laplacian_var = float(cv2.Laplacian(gray_roi, cv2.CV_64F).var())

        if laplacian_var < settings.BLUR_THRESHOLD:
            return QualityCheckResult(
                is_valid=False,
                status_code="BLURRY",
                message="Face is blurry. Please hold steady and clean the camera lens.",
                metrics={"blur_score": round(laplacian_var, 1), "min_threshold": settings.BLUR_THRESHOLD}
            )

        # 5. Illumination / Brightness Check
        mean_brightness = float(np.mean(gray_roi))
        if mean_brightness < settings.MIN_BRIGHTNESS:
            return QualityCheckResult(
                is_valid=False,
                status_code="TOO_DARK",
                message="Face not clear. Please move to a brighter location.",
                metrics={"brightness": round(mean_brightness, 1), "min_required": settings.MIN_BRIGHTNESS}
            )

        if mean_brightness > settings.MAX_BRIGHTNESS:
            return QualityCheckResult(
                is_valid=False,
                status_code="TOO_BRIGHT",
                message="Too much glare. Please adjust lighting or move away from direct light.",
                metrics={"brightness": round(mean_brightness, 1), "max_allowed": settings.MAX_BRIGHTNESS}
            )

        # 6. Overall Quality Score Computation (0.0 to 1.0)
        quality_score = min(1.0, (laplacian_var / (settings.BLUR_THRESHOLD * 2.0)) * 0.5 + (mean_brightness / 128.0) * 0.5)

        return QualityCheckResult(
            is_valid=True,
            status_code="VALID",
            message="Face quality is optimal.",
            metrics={
                "face_count": 1,
                "blur_score": round(laplacian_var, 1),
                "brightness": round(mean_brightness, 1),
                "quality_score": round(quality_score, 3)
            }
        )

quality_checker = FaceQualityChecker()
