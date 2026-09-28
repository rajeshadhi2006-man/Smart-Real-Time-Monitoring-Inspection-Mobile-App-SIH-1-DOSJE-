import cv2
import numpy as np

# Standard 112x112 ArcFace canonical 5-point facial template
# Coordinates: [left_eye, right_eye, nose, left_mouth_corner, right_mouth_corner]
ARCFACE_REFERENCE_POINTS = np.array([
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041]
], dtype=np.float32)

class FaceAligner:
    @staticmethod
    def align_face(image: np.ndarray, landmarks: np.ndarray, output_size=(112, 112)) -> np.ndarray:
        """
        Aligns and crops a face to standard 112x112 using similarity/affine transformation
        based on 5 facial landmarks.
        """
        if landmarks is None or len(landmarks) != 5:
            # Fallback center crop if landmarks are missing
            h, w = image.shape[:2]
            cx, cy = w // 2, h // 2
            size = min(w, h)
            cropped = image[max(0, cy - size//2):min(h, cy + size//2), max(0, cx - size//2):min(w, cx + size//2)]
            return cv2.resize(cropped, output_size)

        src_pts = np.array(landmarks, dtype=np.float32)
        dst_pts = ARCFACE_REFERENCE_POINTS.copy()

        # Compute similarity transformation matrix (translation, rotation, scale)
        M, _ = cv2.estimateAffinePartial2D(src_pts, dst_pts)
        
        if M is None:
            # Fallback simple affine using 3 points (eyes and nose)
            M = cv2.getAffineTransform(src_pts[:3], dst_pts[:3])

        # Warp image into 112x112 aligned face chip
        aligned_face = cv2.warpAffine(
            image,
            M,
            output_size,
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REFLECT
        )

        return aligned_face

aligner = FaceAligner()
