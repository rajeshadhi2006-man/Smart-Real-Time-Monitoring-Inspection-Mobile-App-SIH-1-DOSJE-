"""
End-to-End Test Suite for SpeechBrain ECAPA-TDNN Voice Verification System.

Tests:
A. Same officer multi-sample enrollment and matching verification (genuine match).
B. Different officer voice sample (impostor mismatch).
C. Very short audio (<1.2 seconds) -> rejected with INSUFFICIENT_DURATION.
D. Silent / low-volume audio -> rejected with LOW_VOLUME.
E. Corrupted audio bytes -> rejected with CORRUPTED_AUDIO.
F. Live endpoint schema verification (/api/verification/voice & /challenge).
"""

import os
import io
import json
import base64
import numpy as np
import soundfile as sf
import requests

BASE_URL = "http://127.0.0.1:8000"

def generate_synthetic_speaker_audio(
    base_pitch: float = 120.0,
    duration: float = 3.0,
    sample_rate: int = 16000,
    noise_level: float = 0.005,
    volume: float = 0.5
) -> bytes:
    """
    Generates a realistic multi-formant synthetic voice signal with harmonic structure
    unique to a specific speaker base pitch, modulated by speech-like envelope.
    """
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    
    # Formants for speaker identity
    signal = np.zeros_like(t)
    harmonics = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
    weights =   [1.0, 0.7, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05]
    
    for h, w in zip(harmonics, weights):
        freq = base_pitch * h
        # Add slight vibrato/pitch drift
        freq_mod = freq * (1.0 + 0.015 * np.sin(2 * np.pi * 4.5 * t))
        signal += w * np.sin(2 * np.pi * freq_mod * t)
        
    # Syllabic envelope (simulates speaking words)
    envelope = 0.5 * (1.0 + np.sin(2 * np.pi * 3.0 * t))
    signal = signal * envelope * volume
    
    # Add subtle background noise
    signal += np.random.normal(0, noise_level, len(t))
    
    # Peak normalize
    peak = np.max(np.abs(signal))
    if peak > 0:
        signal = signal / peak * 0.8
        
    buf = io.BytesIO()
    sf.write(buf, signal, sample_rate, format="WAV", subtype="PCM_16")
    return buf.getvalue()


def run_tests():
    print("=" * 65)
    print(" SPEECHBRAIN ECAPA-TDNN SPEAKER VERIFICATION TEST SUITE")
    print("=" * 65)
    
    # 0. Health & Model status
    print("\n[TEST 0] Checking System Health & SpeechBrain Model Status...")
    resp = requests.get(f"{BASE_URL}/api/health")
    assert resp.status_code == 200, f"Health check failed: {resp.text}"
    health = resp.json()
    voice_info = health.get("voice_verification", {})
    print(f"  Service: {health.get('service')}")
    print(f"  Voice Model: {voice_info.get('model')}")
    print(f"  Status: {voice_info.get('status')}")
    print(f"  Device: {voice_info.get('device')}")
    print(f"  Threshold: {voice_info.get('threshold')}")
    assert voice_info.get("status") == "LOADED", "SpeechBrain model not loaded!"
    print("  -> PASS: SpeechBrain model is LOADED and operational.")

    # 1. Dynamic Challenge-Response
    print("\n[TEST 1] Anti-Spoofing Dynamic Challenge Generation...")
    c_resp = requests.get(f"{BASE_URL}/api/verification/voice/challenge")
    assert c_resp.status_code == 200
    c_data = c_resp.json()
    print(f"  Challenge Phrase: '{c_data.get('challenge_phrase')}'")
    print(f"  Nonce: {c_data.get('nonce')}")
    assert "challenge_phrase" in c_data and len(c_data["challenge_phrase"]) > 5
    print("  -> PASS: Dynamic challenge generated successfully.")

    test_user_a = "officer_sharma_104"
    test_user_b = "impostor_patel_999"

    # 2. Multi-sample Enrollment (Officer A: pitch 130 Hz)
    print(f"\n[TEST 2] Multi-Sample Voice Enrollment for '{test_user_a}'...")
    samples_a = [
        generate_synthetic_speaker_audio(base_pitch=130.0, duration=3.0),
        generate_synthetic_speaker_audio(base_pitch=131.0, duration=3.2),
        generate_synthetic_speaker_audio(base_pitch=129.5, duration=3.1),
    ]
    for idx, sample_bytes in enumerate(samples_a):
        b64_audio = base64.b64encode(sample_bytes).decode()
        is_final = (idx == len(samples_a) - 1)
        payload = {
            "user_id": test_user_a,
            "audio_base64": b64_audio,
            "sample_index": idx,
            "total_samples": 3,
            "is_final_sample": is_final,
            "passphrase_text": c_data.get("challenge_phrase"),
            "challenge_nonce": c_data.get("nonce")
        }
        enroll_resp = requests.post(f"{BASE_URL}/api/verification/voice/enroll", json=payload)
        assert enroll_resp.status_code == 200, f"Enroll failed at sample {idx}: {enroll_resp.text}"
        res_json = enroll_resp.json()
        print(f"  Sample {idx + 1}/3: {res_json.get('status')} - {res_json.get('message')}")
        if is_final:
            assert res_json.get("success") is True
            assert res_json.get("model_name") == "speechbrain/spkrec-ecapa-voxceleb"
            assert res_json.get("embedding_dimensions") == 192
    print(f"  -> PASS: Multi-sample voice profile combined and registered (192-D).")

    # 3. Genuine Match: Same Officer A with a new utterance
    print(f"\n[TEST 3] Genuine Verification (Same Officer: '{test_user_a}')...")
    probe_a = generate_synthetic_speaker_audio(base_pitch=130.5, duration=3.2)
    verify_payload_a = {
        "user_id": test_user_a,
        "sample_data": base64.b64encode(probe_a).decode(),
        "passphrase_text": c_data.get("challenge_phrase"),
        "challenge_nonce": c_data.get("nonce")
    }
    match_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=verify_payload_a)
    assert match_resp.status_code == 200, f"Verify request failed: {match_resp.text}"
    match_data = match_resp.json()
    print(f"  Verified: {match_data.get('verified')}")
    print(f"  Score: {match_data.get('score'):.4f}")
    print(f"  Threshold: {match_data.get('threshold')}")
    print(f"  Status: {match_data.get('status')}")
    print(f"  Method: {match_data.get('method')}")
    print(f"  Processing Time: {match_data.get('processing_time_ms')} ms")
    assert match_data.get("verified") is True, f"Expected verified=True, got {match_data}"
    assert match_data.get("score") >= match_data.get("threshold"), "Score below threshold!"
    assert match_data.get("method") == "speechbrain_ecapa"
    print("  -> PASS: Genuine officer verified with high similarity score!")

    # 4. Impostor Mismatch: Different Officer B (pitch 220 Hz) against Officer A profile
    print(f"\n[TEST 4] Impostor Rejection (Officer B voice tested against '{test_user_a}')...")
    impostor_audio = generate_synthetic_speaker_audio(base_pitch=220.0, duration=3.0)
    impostor_payload = {
        "user_id": test_user_a, # Claiming to be Officer A
        "sample_data": base64.b64encode(impostor_audio).decode(),
        "passphrase_text": c_data.get("challenge_phrase"),
        "challenge_nonce": c_data.get("nonce")
    }
    impostor_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=impostor_payload)
    assert impostor_resp.status_code == 200, f"Verify request failed: {impostor_resp.text}"
    impostor_data = impostor_resp.json()
    print(f"  Verified: {impostor_data.get('verified')}")
    print(f"  Score: {impostor_data.get('score'):.4f}")
    print(f"  Threshold: {impostor_data.get('threshold')}")
    print(f"  Status: {impostor_data.get('status')}")
    print(f"  Processing Time: {impostor_data.get('processing_time_ms')} ms")
    assert impostor_data.get("verified") is False, "Impostor should NOT be verified!"
    assert impostor_data.get("status") == "mismatch", f"Expected mismatch, got {impostor_data.get('status')}"
    print("  -> PASS: Impostor successfully rejected with status 'mismatch'!")

    # 5. Very Short Recording (< 1.2s)
    print("\n[TEST 5] Rejection of Very Short Audio (< 1.2s)...")
    short_audio = generate_synthetic_speaker_audio(base_pitch=130.0, duration=0.6)
    short_payload = {
        "user_id": test_user_a,
        "sample_data": base64.b64encode(short_audio).decode(),
    }
    short_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=short_payload)
    print(f"  HTTP Status: {short_resp.status_code}")
    short_data = short_resp.json()
    print(f"  Response: {short_data}")
    assert short_data.get("verified") is False
    assert short_data.get("status") == "quality_failed"
    assert short_data.get("error_code") == "INSUFFICIENT_DURATION"
    print("  -> PASS: Short audio correctly rejected with INSUFFICIENT_DURATION.")

    # 6. Silent Audio Recording
    print("\n[TEST 6] Rejection of Silent / Zero-Volume Audio...")
    silent_signal = np.zeros(16000 * 3, dtype=np.float32)
    s_buf = io.BytesIO()
    sf.write(s_buf, silent_signal, 16000, format="WAV", subtype="PCM_16")
    silent_payload = {
        "user_id": test_user_a,
        "sample_data": base64.b64encode(s_buf.getvalue()).decode(),
    }
    silent_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=silent_payload)
    print(f"  HTTP Status: {silent_resp.status_code}")
    silent_data = silent_resp.json()
    print(f"  Response: {silent_data}")
    assert silent_data.get("verified") is False
    assert silent_data.get("status") == "quality_failed"
    assert silent_data.get("error_code") == "LOW_VOLUME"
    print("  -> PASS: Silent audio correctly rejected with LOW_VOLUME.")

    # 7. Corrupted Audio Bytes
    print("\n[TEST 7] Rejection of Corrupted Audio...")
    corrupt_bytes = b"RIFF" + b"\x00" * 4000 + b"WAVEfmt corrupted garbage data" * 40
    corrupt_payload = {
        "user_id": test_user_a,
        "sample_data": base64.b64encode(corrupt_bytes).decode(),
    }
    corrupt_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=corrupt_payload)
    print(f"  HTTP Status: {corrupt_resp.status_code}")
    corrupt_data = corrupt_resp.json()
    print(f"  Response: {corrupt_data}")
    assert corrupt_data.get("verified") is False
    assert corrupt_data.get("status") == "quality_failed"
    assert corrupt_data.get("error_code") in ["CORRUPTED_AUDIO", "AUDIO_TOO_SHORT"]
    print("  -> PASS: Corrupted audio correctly rejected.")

    # 8. Unregistered User Verification Attempt
    print("\n[TEST 8] Verification Attempt for Unregistered User...")
    unregistered_payload = {
        "user_id": "nonexistent_officer_000",
        "sample_data": base64.b64encode(probe_a).decode(),
    }
    unreg_resp = requests.post(f"{BASE_URL}/api/verification/voice", json=unregistered_payload)
    print(f"  HTTP Status: {unreg_resp.status_code}")
    unreg_data = unreg_resp.json()
    print(f"  Response: {unreg_data}")
    assert unreg_data.get("verified") is False
    assert unreg_data.get("status") == "not_enrolled"
    assert unreg_data.get("error_code") == "NOT_ENROLLED"
    print("  -> PASS: Unregistered user properly returned not_enrolled status.")

    print("\n" + "=" * 65)
    print(" ALL 8 REAL-TIME VOICE VERIFICATION TESTS PASSED SUCCESSFULLY! ")
    print("=" * 65)

if __name__ == "__main__":
    run_tests()
