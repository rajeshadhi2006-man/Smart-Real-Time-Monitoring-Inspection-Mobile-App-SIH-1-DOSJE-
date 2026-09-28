import requests
import cv2
import numpy as np
import base64
import json

BASE_URL = "http://127.0.0.1:8000"

def create_face_b64(seed=42):
    img = np.ones((250, 250, 3), dtype=np.uint8) * 210
    cv2.ellipse(img, (125, 125), (60, 80), 0, 0, 360, (180, 210, 240), -1)
    cv2.circle(img, (103, 110), 8, (255, 255, 255), -1)
    cv2.circle(img, (147, 110), 8, (255, 255, 255), -1)
    cv2.circle(img, (103, 110), 4, (50, 50, 50), -1)
    cv2.circle(img, (147, 110), 4, (50, 50, 50), -1)
    cv2.line(img, (95, 100), (113, 98), (30, 30, 30), 2)
    cv2.line(img, (137, 98), (155, 100), (30, 30, 30), 2)
    cv2.line(img, (125, 117), (122, 137), (140, 160, 190), 2)
    cv2.line(img, (122, 137), (128, 137), (140, 160, 190), 2)
    cv2.ellipse(img, (125, 160), (20, 10), 0, 0, 180, (60, 70, 160), -1)
    _, buffer = cv2.imencode('.jpg', img)
    return base64.b64encode(buffer).decode('utf-8')

def test_api():
    print("--- 1. Testing Health Endpoint ---")
    r = requests.get(f"{BASE_URL}/api/health")
    print("Health Status:", r.status_code, r.json())
    assert r.status_code == 200

    print("\n--- 2. Checking Initial Face Status (Unenrolled) ---")
    r = requests.get(f"{BASE_URL}/api/face/status?user_id=officer_rajesh_test")
    print("Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["enrolled"] is False

    print("\n--- 3. Testing Face Enrollment ---")
    b64_face = create_face_b64(seed=1)
    enroll_payload = {
        "user_id": "officer_rajesh_test",
        "officer_id": "OFF-TEST-99",
        "full_name": "Field Inspector Rajesh",
        "image_base64": b64_face
    }
    r = requests.post(f"{BASE_URL}/api/face/enroll", json=enroll_payload)
    print("Enroll Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["success"] is True
    assert r.json()["embedding_dimensions"] == 512

    print("\n--- 4. Checking Face Status After Enrollment ---")
    r = requests.get(f"{BASE_URL}/api/face/status?user_id=officer_rajesh_test")
    print("Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["enrolled"] is True

    print("\n--- 5. Testing Face Verification (MATCH) ---")
    verify_payload = {
        "user_id": "officer_rajesh_test",
        "image_base64": b64_face,
        "context": "ATTENDANCE_CHECK_IN"
    }
    r = requests.post(f"{BASE_URL}/api/face/verify", json=verify_payload)
    print("Verify Match Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["verified"] is True
    assert r.json()["status"] == "MATCH"
    assert r.json()["similarity"] > 0.90

    print("\n--- 6. Testing Face Verification (MISMATCH / Alert Creation) ---")
    # Generate different image
    img_diff = np.zeros((250, 250, 3), dtype=np.uint8)
    img_diff[:] = 230
    cv2.circle(img_diff, (125, 125), 65, (130, 150, 200), -1)
    cv2.rectangle(img_diff, (100, 105), (115, 115), (0, 0, 0), -1)
    cv2.rectangle(img_diff, (135, 105), (150, 115), (0, 0, 0), -1)
    cv2.line(img_diff, (105, 160), (145, 160), (20, 20, 20), 4)
    _, buf2 = cv2.imencode('.jpg', img_diff)
    b64_diff = base64.b64encode(buf2).decode('utf-8')

    verify_diff_payload = {
        "user_id": "officer_rajesh_test",
        "image_base64": b64_diff,
        "context": "ATTENDANCE_CHECK_IN"
    }
    r = requests.post(f"{BASE_URL}/api/face/verify", json=verify_diff_payload)
    print("Verify Mismatch Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["verified"] is False
    assert r.json()["status"] in ["MISMATCH", "LOW_CONFIDENCE"]

    print("\n--- 7. Testing Attendance Entry with Face Verification ---")
    att_payload = {
        "user_id": "officer_rajesh_test",
        "latitude": 11.016844,
        "longitude": 76.955832,
        "geofence_verified": True,
        "face_verified": True,
        "voice_verified": True
    }
    r = requests.post(f"{BASE_URL}/api/attendance/entry", json=att_payload)
    print("Attendance Entry Status:", r.status_code, r.json())
    assert r.status_code == 200
    assert r.json()["status"] == "PRESENT"

    print("\n=== ALL API ENDPOINTS PASSED AND SYNCHRONIZED SUCCESSFULLY! ===")

if __name__ == "__main__":
    test_api()
