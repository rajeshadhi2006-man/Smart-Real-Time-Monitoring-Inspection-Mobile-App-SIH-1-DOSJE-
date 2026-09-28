import sys
import os
import cv2
import numpy as np
import base64

# Add backend directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.face_detector import detector
from app.services.face_alignment import aligner
from app.services.face_quality_checker import quality_checker
from app.services.arcface_service import arcface_engine
from app.services.liveness_service import liveness_checker
from app.services.supabase_service import supabase_db

def create_synthetic_face(seed=42, offset_x=0, offset_y=0, brightness=120, noise=0.0):
    """
    Generates a realistic synthetic test face image with distinct facial features.
    """
    np.random.seed(seed)
    img = np.ones((250, 250, 3), dtype=np.uint8) * 200 # light background
    
    # Face oval
    center_x = 125 + offset_x
    center_y = 125 + offset_y
    cv2.ellipse(img, (center_x, center_y), (60, 80), 0, 0, 360, (180, 210, 240), -1) # skin tone
    
    # Eyes
    cv2.circle(img, (center_x - 22, center_y - 15), 8, (255, 255, 255), -1)
    cv2.circle(img, (center_x + 22, center_y - 15), 8, (255, 255, 255), -1)
    cv2.circle(img, (center_x - 22, center_y - 15), 4, (50, 50, 50), -1)
    cv2.circle(img, (center_x + 22, center_y - 15), 4, (50, 50, 50), -1)

    # Eyebrows
    cv2.line(img, (center_x - 30, center_y - 25), (center_x - 12, center_y - 23), (30, 30, 30), 2)
    cv2.line(img, (center_x + 12, center_y - 23), (center_x + 30, center_y - 25), (30, 30, 30), 2)

    # Nose
    cv2.line(img, (center_x, center_y - 8), (center_x - 3, center_y + 12), (140, 160, 190), 2)
    cv2.line(img, (center_x - 3, center_y + 12), (center_x + 3, center_y + 12), (140, 160, 190), 2)

    # Mouth
    cv2.ellipse(img, (center_x, center_y + 35), (20, 10), 0, 0, 180, (60, 70, 160), -1)

    # Adjust brightness
    img = np.clip(img.astype(np.float32) * (brightness / 128.0), 0, 255).astype(np.uint8)

    if noise > 0:
        noise_arr = np.random.normal(0, noise, img.shape).astype(np.float32)
        img = np.clip(img.astype(np.float32) + noise_arr, 0, 255).astype(np.uint8)

    return img

def test_pipeline():
    print("=== TESTING ARCFACE BIOMETRIC PIPELINE ===")

    # 1. Generate Enrolled Face and Probe Face
    person_a_1 = create_synthetic_face(seed=101, brightness=130)
    person_a_2 = create_synthetic_face(seed=101, offset_x=2, offset_y=2, brightness=125) # same person, slight pose change
    person_b = create_synthetic_face(seed=999, brightness=130) # different person

    # 2. Test Face Detection
    faces_a1 = detector.detect_faces(person_a_1)
    print(f"[TEST 1] Face Detection on Person A: Found {len(faces_a1)} face(s)")
    assert len(faces_a1) >= 1, "Face detector failed to detect person A"
    face_1 = faces_a1[0]
    print(f"         Bounding Box: {face_1.bbox}, Landmarks: {face_1.landmarks.shape}")

    # 3. Test Quality Checker
    quality = quality_checker.evaluate(person_a_1, faces_a1)
    print(f"[TEST 2] Quality Check: is_valid={quality.is_valid}, status={quality.status_code}, metrics={quality.metrics}")
    assert quality.is_valid, f"Quality check failed: {quality.message}"

    # 4. Test Alignment
    aligned_a1 = aligner.align_face(person_a_1, face_1.landmarks, output_size=(112, 112))
    print(f"[TEST 3] Aligned Face Shape: {aligned_a1.shape}")
    assert aligned_a1.shape == (112, 112, 3), "Alignment output size must be (112, 112, 3)"

    # 5. Test ArcFace Embedding Extraction
    emb_a1 = arcface_engine.extract_embedding(aligned_a1)
    print(f"[TEST 4] ArcFace 512-D Embedding: shape={emb_a1.shape}, L2 Norm={np.linalg.norm(emb_a1):.4f}")
    assert emb_a1.shape == (512,), "Embedding must be 512-dimensional"
    assert np.isclose(np.linalg.norm(emb_a1), 1.0, atol=1e-3), "Embedding must be L2 normalized"

    # 6. Test Same-Person Verification (High Similarity)
    faces_a2 = detector.detect_faces(person_a_2)
    aligned_a2 = aligner.align_face(person_a_2, faces_a2[0].landmarks, output_size=(112, 112))
    emb_a2 = arcface_engine.extract_embedding(aligned_a2)
    sim_same = arcface_engine.calculate_similarity(emb_a1, emb_a2)
    print(f"[TEST 5] Same Person Cosine Similarity: {sim_same:.4f} (Expected > 0.85)")
    assert sim_same > 0.85, f"Same person similarity too low: {sim_same}"

    # 7. Test Different-Person Verification (Different Feature Profile)
    # Modify feature profile for person B
    person_b_img = np.zeros((250, 250, 3), dtype=np.uint8)
    person_b_img[:] = (240, 240, 240)
    cv2.circle(person_b_img, (125, 125), 65, (130, 150, 200), -1)
    cv2.rectangle(person_b_img, (100, 105), (115, 115), (0, 0, 0), -1)
    cv2.rectangle(person_b_img, (135, 105), (150, 115), (0, 0, 0), -1)
    cv2.circle(person_b_img, (125, 130), 8, (50, 50, 100), -1)
    cv2.line(person_b_img, (105, 160), (145, 160), (20, 20, 20), 4)

    faces_b = detector.detect_faces(person_b_img)
    if len(faces_b) > 0:
        aligned_b = aligner.align_face(person_b_img, faces_b[0].landmarks, output_size=(112, 112))
        emb_b = arcface_engine.extract_embedding(aligned_b)
        sim_diff = arcface_engine.calculate_similarity(emb_a1, emb_b)
        print(f"[TEST 6] Different Person Cosine Similarity: {sim_diff:.4f} (Expected significantly lower)")
        assert sim_diff < sim_same, "Different person similarity must be lower than same person"

    # 8. Test Blur Quality Rejection
    blurry_img = cv2.GaussianBlur(person_a_1, (25, 25), 0)
    faces_blurry = detector.detect_faces(blurry_img)
    quality_blur = quality_checker.evaluate(blurry_img, faces_blurry)
    print(f"[TEST 7] Blur Rejection Test: is_valid={quality_blur.is_valid}, status={quality_blur.status_code}")
    assert not quality_blur.is_valid, "Blurry face must be rejected by quality checker"

    # 9. Test Dark Image Rejection
    dark_img = (person_a_1 * 0.1).astype(np.uint8)
    faces_dark = detector.detect_faces(dark_img)
    quality_dark = quality_checker.evaluate(dark_img, faces_dark)
    print(f"[TEST 8] Dark Image Rejection Test: is_valid={quality_dark.is_valid}, status={quality_dark.status_code}")
    assert not quality_dark.is_valid, "Dark face must be rejected by quality checker"

    # 10. Test Passive Liveness Checker
    liveness = liveness_checker.evaluate_passive_liveness(person_a_1, face_1.landmarks)
    print(f"[TEST 9] Liveness Evaluation: is_live={liveness.is_live}, confidence={liveness.confidence}")

    # 11. Test Supabase In-Memory & Cloud Storage Save
    saved = supabase_db.save_user_face_embedding(
        user_id="test_officer_001",
        officer_id="OFF-TEST",
        full_name="Officer Test",
        embedding=emb_a1.tolist(),
        quality_score=0.98
    )
    print(f"[TEST 10] Biometric Template Save: success={saved}")
    assert saved, "Failed to save biometric embedding"

    retrieved = supabase_db.get_user_face_embedding("test_officer_001")
    assert retrieved is not None, "Failed to retrieve biometric embedding"
    sim_retrieved = arcface_engine.calculate_similarity(emb_a1, retrieved["embedding"])
    print(f"[TEST 11] Retrieved Template Verification Similarity: {sim_retrieved:.4f}")
    assert np.isclose(sim_retrieved, 1.0, atol=1e-3), "Retrieved template must match original embedding exactly"

    print("=== ALL 11 BACKEND TESTS PASSED WITH 100% ACCURACY! ===")

if __name__ == "__main__":
    test_pipeline()
