# Google ML Kit Integration Guide — SIH 2026 User App

## 1. Overview & Architecture Division

In the SIH 2026 Field Officer Monitoring System, biometric identity verification is architecturally divided into two distinct, cooperative layers:

1. **On-Device Edge ML (Google ML Kit)**:
   - Real-time on-device face detection running locally at ~6.6 FPS (throttled ~150ms).
   - Enforces the **1-Person / 1-Face Policy** (detects 0 faces, exactly 1 face, or multiple faces).
   - Validates facial orientation (Euler yaw $\pm 18^\circ$, roll $\pm 16^\circ$), distance ratio (8%–70% of frame area), and centered positioning.
   - Monitors active blink liveness using eye-open probability thresholds ($\le 0.20$ close $\rightarrow \ge 0.75$ open).
   - Provides instantaneous dual-language (EN/HI) HUD feedback directly on the camera viewport.
   - **Crucial Rule**: ML Kit does *not* match identity or extract identity embeddings. It acts as an edge gatekeeper.

2. **Server-Side Neural Verification (FastAPI + ArcFace 512-D + Supabase)**:
   - Receives high-resolution biometric verification frames captured only after ML Kit confirms 1 valid centered person with liveness.
   - Computes 512-dimensional ArcFace cosine similarity embeddings.
   - Matches against the official enrolled biometric templates in Supabase.
   - Issues cryptographic attendance/inspection verification timestamps with geofence validation.

---

## 2. Dependencies Added

In `pubspec.yaml`:
```yaml
dependencies:
  google_mlkit_face_detection: ^0.14.0
  google_mlkit_commons: ^0.12.0
```

---

## 3. Android Configuration

### 3.1 SDK Requirements (`android/app/build.gradle`)
- `compileSdk`: 35 (or `flutter.compileSdkVersion`)
- `minSdk`: 21 (Google ML Kit requires minimum API level 21)
- `targetSdk`: 35

### 3.2 Automated Model Delivery (`android/app/src/main/AndroidManifest.xml`)
To download Google Play Services face models automatically upon app installation:
```xml
<application ...>
    <!-- Google ML Kit Unbundled Face Detection Model -->
    <meta-data
        android:name="com.google.firebase.ml.vision.DEPENDENCIES"
        android:value="face" />
    ...
</application>
```

### 3.3 Permissions Declared & Handled Runtime
- `android.permission.CAMERA`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- Runtime permissions requested via `Permission.camera.request()` before initializing the camera.

---

## 4. ML Service Architecture

The service layer is organized cleanly under `lib/services/ml/`:

```
lib/services/ml/
├── ml_detection_result.dart      # Data models: DetectedFaceData, MlFaceDetectionResult, FaceDetectionState
├── camera_image_converter.dart   # High-performance CameraImage (NV21/BGRA) -> ML Kit InputImage conversion
├── face_detection_service.dart   # Core face detector, blink tracking, 1-face policy evaluator, throttler
└── ml_kit_service.dart           # Riverpod provider definitions & facade
```

### 4.1 Data Models (`ml_detection_result.dart`)
- `FaceDetectionState`:
  - `idle`, `detecting`, `noFace`, `multipleFaces`, `misaligned`, `tooFar`, `tooClose`, `badAngle`, `readyForCapture`
- `MlFaceDetectionResult`: Contains face count, bounding boxes, landmarks, angles, distances, liveness verification, and localized prompts (EN/HI).

### 4.2 Camera Image Stream Converter (`camera_image_converter.dart`)
- Converts Flutter's `CameraImage` stream:
  - **Android**: Concatenates Y, U, V planes into NV21 byte buffer (`InputImageFormat.nv21`).
  - **iOS**: Uses plane 0 bytes (`InputImageFormat.bgra8888`).
- Computes correct rotation relative to sensor orientation (`sensorOrientation` + device orientation) into `InputImageRotation`.

### 4.3 Face Detection Pipeline (`face_detection_service.dart`)
```
Camera Image Stream (30 FPS)
         ↓
Frame Throttler (Semaphore + 150ms delta)
         ↓
CameraImageConverter.convert()
         ↓
FaceDetector.processImage() (fast mode, classification enabled)
         ↓
Face Detection Policy Evaluator:
  ├── Face Count == 0? -> "No Face Detected"
  ├── Face Count > 1?  -> "Multiple Faces Detected (N). Only 1 person allowed"
  ├── Centering Check (0.22 <= X <= 0.78, 0.22 <= Y <= 0.78)
  ├── Distance Area Check (8% <= Area <= 70%)
  ├── Head Pose Check (Yaw <= 18°, Roll <= 16°)
  └── Blink Liveness Tracking (Closed <= 0.20 -> Opened >= 0.75)
         ↓
MlFaceDetectionResult -> UI Overlay Reticle + Verification Gate
```

---

## 5. Screen Integrations

1. **Face Verification Screen** (`lib/features/face_verification/screens/face_verification_screen.dart`):
   - Streams camera frames to `FaceDetectionService.processLiveFrame()`.
   - Real-time oval reticle changes color dynamically:
     - 🔴 Red: No face or multiple faces (gated).
     - 🟡 Amber: Misaligned, too far, or head rotated.
     - 🟢 Green: Exactly 1 face, centered, upright, ready for capture.
   - Dual-language live guidance banner: e.g. "Look directly at the camera / सीधे कैमरे की ओर देखें".
   - Top banner displays active ML Kit badge: `ML KIT: READY (1 FACE)` or `ML KIT: 0 FACES`.
   - Stops stream safely before `takePicture()`, captures high-res JPEG, and sends to FastAPI `/api/v1/auth/verify-face`.

2. **Face Enrollment Screen** (`lib/features/face_verification/screens/face_enrollment_screen.dart`):
   - Enforces 1-person presence before capturing the reference enrollment image.
   - Validates that enrollment template photos contain exactly 1 clear, centered face.

3. **Inspection GPS Map Camera** (`lib/features/evidence/live_gps_map_camera_screen.dart`):
   - Used for field officer attendance and beneficiary evidence capture.
   - Can run optional ML Kit face check to ensure the officer or beneficiary is properly visible before watermarking GPS coordinates.

---

## 6. Error Handling & Edge Cases

| Scenario | Handled Behavior |
|---|---|
| Camera permission denied | Shows alert dialog directing user to App Settings; no crash. |
| Zero faces detected | Reticle pulses red, displays "No Face Detected / चेहरा नहीं मिला", capture disabled. |
| Multiple faces detected | Reticle pulses red, displays "Multiple Faces Detected (N) / एकाधिक चेहरे मिले", capture strictly blocked. |
| Extreme head angle (>18°) | Guidance advises "Look directly at the camera / सीधे कैमरे की ओर देखें". |
| App lifecycle pause/resume | `didChangeAppLifecycleState` stops detector and camera, resumes safely upon return. |
| Rapid frames (30 FPS) | Async lock (`_isDetecting`) skips frames if previous inference is still running. |
| Stream capture conflict | `_cameraController.stopImageStream()` is awaited prior to `takePicture()`. |

---

## 7. Performance & Optimization

- **Throttling**: Processing limited to max 1 frame every ~150ms (~6.6 FPS), preventing thermal throttling or UI jank on field devices.
- **Fast Mode**: Initialized with `FaceDetectorOptions(performanceMode: FaceDetectorMode.fast, enableClassification: true)`.
- **Memory Management**: Detector instances are properly closed via `dispose()`; image buffers are garbage collected after each frame.
- **Web / Desktop Fallbacks**: Stubs in `mlkit_web_stub.dart` ensure desktop and web compilations do not break.

---

## 8. Verification & Testing

### Automated Unit Tests
Run the test suite:
```bash
flutter test test/ml_kit_face_detection_test.dart
flutter test
```
**Test Cases Covered**:
1. `Zero faces produces noFace state and blocks verification` (PASSED)
2. `Multiple faces strictly violates 1-person policy` (PASSED)
3. `Single centered face with blink verified allows verification capture` (PASSED)
4. `Head angle exceeding threshold is flagged as badAngle` (PASSED)

### Build & Run on Connected Android Device
```powershell
flutter build apk --debug
adb -s 10BF3G0Q4A005B1 install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb -s 10BF3G0Q4A005B1 shell am start -n in.gov.mosje.sih_inspection/.MainActivity
```
