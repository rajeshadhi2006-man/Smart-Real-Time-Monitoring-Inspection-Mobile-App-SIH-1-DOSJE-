import cv2
import numpy as np
import logging
from typing import List, Tuple, Optional

logger = logging.getLogger("MoSJEFaceDetector")

class DetectedFace:
    def __init__(self, bbox: Tuple[int, int, int, int], landmarks: np.ndarray, confidence: float):
        """
        bbox: (x, y, w, h)
        landmarks: 5x2 array [[x_le, y_le], [x_re, y_re], [x_nose, y_nose], [x_lm, y_lm], [x_rm, y_rm]]
        confidence: detection confidence score [0.0 - 1.0]
        """
        self.bbox = bbox
        self.landmarks = landmarks
        self.confidence = confidence

class FaceDetector:
    def __init__(self):
        # Load OpenCV Haar Cascades
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.face_cascade_alt = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_alt2.xml')
        self.profile_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_profileface.xml')
        self.eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')

    def detect_faces(self, image: np.ndarray) -> List[DetectedFace]:
        """
        Detects faces and extracts 5 canonical landmarks:
        [left_eye, right_eye, nose, left_mouth_corner, right_mouth_corner]
        """
        if image is None or image.size == 0:
            return []

        h_img, w_img = image.shape[:2]
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
        
        # 1. Primary Haar cascade detection (frontal default)
        faces = self.face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.08,
            minNeighbors=4,
            minSize=(50, 50),
            flags=cv2.CASCADE_SCALE_IMAGE
        )

        # 2. Fallback to Alt2 cascade (tolerant to illumination & slight angles)
        if len(faces) == 0:
            faces = self.face_cascade_alt.detectMultiScale(
                gray,
                scaleFactor=1.08,
                minNeighbors=3,
                minSize=(50, 50),
                flags=cv2.CASCADE_SCALE_IMAGE
            )

        # 3. Fallback to Profile cascade for turned faces
        if len(faces) == 0:
            faces = self.profile_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=4,
                minSize=(50, 50)
            )
            if len(faces) == 0:
                # Check horizontally flipped for opposite profile angle
                flipped_gray = cv2.flip(gray, 1)
                flipped_faces = self.profile_cascade.detectMultiScale(
                    flipped_gray,
                    scaleFactor=1.1,
                    minNeighbors=4,
                    minSize=(50, 50)
                )
                if len(flipped_faces) > 0:
                    faces = [(w_img - (fx + fw), fy, fw, fh) for (fx, fy, fw, fh) in flipped_faces]

        if len(faces) == 0:
            logger.info("[FACE] Detected 0 faces")
            return []

        detected = []
        for (x, y, w, h) in faces:
            # Ensure within bounds
            x = max(0, int(x))
            y = max(0, int(y))
            w = min(w_img - x, int(w))
            h = min(h_img - y, int(h))

            roi_gray = gray[y:y+h, x:x+w]
            
            # Detect eyes in upper region
            eyes = self.eye_cascade.detectMultiScale(roi_gray[:int(h * 0.65), :], scaleFactor=1.1, minNeighbors=2)
            
            if len(eyes) >= 2:
                eyes = sorted(eyes, key=lambda e: e[0])
                le_x = x + eyes[0][0] + eyes[0][2] // 2
                le_y = y + eyes[0][1] + eyes[0][3] // 2
                re_x = x + eyes[-1][0] + eyes[-1][2] // 2
                re_y = y + eyes[-1][1] + eyes[-1][3] // 2
            else:
                le_x = int(x + 0.35 * w)
                le_y = int(y + 0.38 * h)
                re_x = int(x + 0.65 * w)
                re_y = int(y + 0.38 * h)

            nose_x = int(x + 0.50 * w)
            nose_y = int(y + 0.58 * h)
            lm_x = int(x + 0.35 * w)
            lm_y = int(y + 0.78 * h)
            rm_x = int(x + 0.65 * w)
            rm_y = int(y + 0.78 * h)

            landmarks = np.array([
                [le_x, le_y],
                [re_x, re_y],
                [nose_x, nose_y],
                [lm_x, lm_y],
                [rm_x, rm_y]
            ], dtype=np.float32)

            detected.append(DetectedFace(
                bbox=(x, y, w, h),
                landmarks=landmarks,
                confidence=0.95
            ))

        logger.info(f"[FACE] Detected {len(detected)} face(s)")
        return detected

detector = FaceDetector()
