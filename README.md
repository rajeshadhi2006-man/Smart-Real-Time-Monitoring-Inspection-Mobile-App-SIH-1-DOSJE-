# MoSJE Nirikshan — Smart Real-Time Monitoring & Inspection Mobile App
### Smart India Hackathon (SIH) — Problem Statement ID: 26095
**Ministry:** Ministry of Social Justice and Empowerment (MoSJE)  
**Department:** Department of Social Justice and Empowerment  
**Category:** Software | **Theme:** Smart Automation  
**Primary Target Users:** PMU Officers, Inspection Officers, and Departmental Officials

---

## 1. Executive Summary & Overview

**MoSJE Nirikshan** is a production-quality, enterprise-grade Flutter mobile application engineered for field monitoring, compliance auditing, and tamper-evident inspection of welfare schemes, grantee NGOs, rehabilitation centres, and residential institutions.

Unlike conventional CRUD or static prototype applications, **MoSJE Nirikshan** provides:
- **Strict GPS Geofencing:** Real-time distance matrix and anti-spoofing validators preventing check-in unless the inspector is physically within the 100-meter radius of the registered institution.
- **Cryptographic Anti-Tampering Evidence:** Every photograph and video recorded is stamped on-device with GPS coordinates, authoritative timestamp, inspection ID, and a **SHA-256 integrity hash**.
- **Dynamic Digital Checklist Engine:** Categorized across Infrastructure, Services, Beneficiaries, and Documentation with autosaving state and live compliance scoring.
- **Multi-Modal Attendance Auditing:** Supports manual verification, QR-based UDID cards, and on-device facial recognition matching pipelines adhering to strict privacy and data minimization guidelines.
- **AI-Powered Anomaly & Risk Analytics:** Automated heuristic and AI variance indicators comparing physical headcount with 90-day historical institutional baselines to flag attendance shortfalls and missing compliance tags.
- **Offline-First Resilience:** Encrypted local drafts with an idempotent transaction sync queue that automatically commits records to the central MoSJE PostgreSQL database upon network resumption.

---

## 2. System Architecture

Built on **Clean Architecture** with a **Feature-First** structure and **Riverpod State Management**:

```
lib/
├── core/
│   ├── config/          # Environment configuration (AppConfig)
│   ├── constants/       # AppColors, AppDimensions, AppStrings
│   ├── routing/         # GoRouter with StatefulShellRoute navigation
│   ├── security/        # SHA-256 EvidenceHasher & tamper-evidence salt
│   ├── theme/           # MoSJE Gov Enterprise Material 3 Theme (Light & Dark)
│   ├── utils/           # GeoUtils (Haversine geodesic distance, geofencing)
│   └── widgets/         # AppButton, AppCard, StatusBadge, RiskBadge, MetricCard, LocationStatusCard
│
├── features/
│   ├── auth/            # Official login, role resolution, session persistence
│   ├── shell/           # Bottom navigation shell (Home, Inspections, Map, Alerts, Profile)
│   ├── dashboard/       # Statistical KPI cards, today's inspection highlight, quick actions
│   ├── inspections/     # List, detail dossier, start modal, checklist, summary, progress
│   ├── projects/        # Project dossier, registered geo-anchor, compliance, CCTV feeds
│   ├── location/        # Live GPS verification, geofencing (100m), interactive map grid
│   ├── evidence/        # Camera capture, video recording, SHA-256 fingerprinting, vault
│   ├── attendance/      # Expected vs verified headcount, face audit, privacy consent
│   ├── analytics/       # AI anomaly indicators, explainable flags, recommended actions
│   ├── notifications/   # Push & in-app alerts, random assignment broadcasts
│   └── profile/         # Officer credentials, operational role switcher, system settings
│
├── app.dart             # Root MaterialApp.router with Riverpod ProviderScope
└── main.dart            # Orientation locking, error zones, and entry point
```

---

## 3. Implemented User Roles & Access Control

1. **PMU Officer:** High-level field monitoring, review of flagged anomalies, and supervisor sign-off.
2. **Inspection Officer:** Primary field auditor executing geofence validation, checklists, evidence capture, and headcount.
3. **Department Official:** Central ministry overview, policy compliance, and audit log tracking.
4. **Project Staff:** Institution focal person facilitating physical verification.

*Role switching is supported dynamically in the Profile section for real-time demonstration during evaluation.*

---

## 4. Problem Statement Feature Matrix (SIH 26095)

| Requirement | Implementation Component | Status |
| :--- | :--- | :--- |
| **Secure Authentication** | `LoginScreen`, `AuthNotifier`, Supabase / Mock Auth Repository | Completed |
| **Random Assignment** | Central Randomization Engine modal & automated notifications | Completed |
| **Project Details & CCTV** | `ProjectDetailsScreen` with CCTV surveillance telemetry | Completed |
| **GPS Geofence Verification** | `GeoUtils.calculateDistanceInMeters`, `LocationStatusCard`, `MapVerificationScreen` | Completed |
| **Anti-Spoofing & Mock GPS** | Minimum ±25m accuracy threshold + `isMocked` provider detection | Completed |
| **Dynamic Checklist** | Multi-category checklist (Infra, Services, Beneficiaries, Records) with autosave | Completed |
| **Tamper-Evident Evidence** | `EvidenceCaptureScreen` + `EvidenceHasher` (SHA-256 fingerprinting) | Completed |
| **Beneficiary Verification** | `AttendanceVerificationScreen` (Manual + QR + On-Device Face Audit) | Completed |
| **AI Anomaly Detection** | `AiAnalysisScreen` with explainable variance and risk scoring | Completed |
| **Pre-Submission Summary** | `InspectionSummaryScreen` with mandatory digital sign-off dialog | Completed |
| **Offline-First & Auto-Sync** | Local encrypted cache, sync status badges, and idempotent progress commits | Completed |

---

## 5. Getting Started & Installation

### Prerequisites
- Flutter SDK **3.41.x** (or later stable channel)
- Dart SDK **3.11.x**
- Android SDK (API 34+) / iOS Xcode / Windows Developer Mode

### Step 1: Clone or Navigate to Project Root
```bash
cd "d:/ALL PROJECT/SIH"
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Environment Variables
Copy `.env.example` to `.env` or pass variables via `--dart-define`:
```bash
# Example
flutter run --dart-define=USE_MOCK_FALLBACK=true --dart-define=MAX_GEOFENCE_RADIUS_METERS=100
```

### Step 4: Run Dart Analyzer & Tests
```bash
dart analyze lib
flutter test
```

### Step 5: Run the Application
```bash
flutter run
```

---

## 6. Verification and Automated Testing

Automated unit tests are located in `test/widget_test.dart` and validate:
- **Haversine Distance Accuracy:** Correct geodesic calculation confirming 48m is within geofence and 1.8km is rejected.
- **SHA-256 Hash Tamper Proofing:** Ensuring evidence fingerprints change if even a single byte is altered.
- **Role Designation Deserialization:** Verification of departmental officer roles.
- **Checklist Engine Progress:** Live verification of dynamic scoring.

Run tests anytime with:
```bash
flutter test
```

---

## 7. Production Real-Time Location Tracking Module (Flutter + OpenStreetMap + Supabase)

### Architecture Overview
This module enables GPS tracking of field officers during official audits **without Google Maps API** or proprietary paid map services:
- **Mobile Client:** Flutter + `flutter_map` + `latlong2` using OpenStreetMap tiles with a compliant government User-Agent header (`in.gov.mosje.sih_inspection`).
- **Telemetry Stream:** `geolocator` captures high-accuracy coordinates with a battery-optimized 10-meter distance filter and 5–10s time throttling.
- **Offline Resiliency:** When network connectivity is lost, updates buffer in an offline FIFO queue (up to 100 updates) and automatically flush to Supabase upon reconnection via `connectivity_plus`.
- **Geofence Audit Engine:** Computes exact Haversine distance from registered facility centers and flags `INSIDE AUTHORIZED AREA` vs `OUTSIDE AUTHORIZED AREA`.
- **Backend & Security:** Supabase PostgreSQL database with Row Level Security (RLS) ensuring field inspectors can only insert/view their own records while authorized PMU/government officials view permitted inspectors.
- **Government Admin Dashboard:** React + TypeScript + Tailwind CSS + OpenStreetMap (Leaflet) with live Supabase Realtime replication and smooth marker animation.

---

### Step-by-Step Supabase Setup

1. Create a project at [supabase.com](https://supabase.com).
2. Navigate to **SQL Editor** and execute the complete schema file:
   ```
   supabase/schema.sql
   ```
   This script creates:
   - `profiles`, `geofences`, `tracking_sessions`, and `location_updates` tables.
   - High-performance indexes on `user_id`, `tracking_session_id`, and `created_at`.
   - Strict Row Level Security (RLS) policies.
   - Realtime publication on `location_updates` and `tracking_sessions`.
3. In your Supabase Project Settings, copy your **Project URL** and **anon/public key**.
4. Configure these keys in `.env` (or via `--dart-define` for Flutter and `VITE_` variables for Admin Dashboard):
   - Flutter: `SUPABASE_URL` and `SUPABASE_ANON_KEY`
   - Admin Dashboard (`admin_dashboard/.env`): `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`

---

### Android Location Permissions

Location and internet permissions are declared in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```
- The app handles runtime permission requests gracefully:
  - Explains the official necessity of location tracking via `PermissionScreen`.
  - Prompts standard Android system dialog.
  - Detects if location services (GPS hardware) are disabled and prompts the user to enable them.
  - If permanently denied, guides the user with a direct button to Android App Settings.

---

### Running the Mobile Application

1. Ensure dependencies are up to date:
   ```bash
   flutter pub get
   ```
2. Verify code health:
   ```bash
   flutter analyze
   flutter test
   ```
3. Launch the Flutter mobile app (Android / iOS / Web):
   ```bash
   flutter run -d chrome --web-port=3000
   # or on an Android emulator / physical device:
   flutter run
   ```
4. Navigate to **Location Tracking** (via the bottom navigation **Radar** tab or directly to `/location-tracking`).

---

### Running the Admin Dashboard (React + TypeScript)

1. Open a terminal and navigate to the admin dashboard directory:
   ```bash
   cd admin_dashboard
   ```
2. Install dependencies (if not already installed):
   ```bash
   npm install
   ```
3. Start the Vite development server:
   ```bash
   npm run dev
   ```
4. Open the dashboard in your browser:
   ```
   http://localhost:5173
   ```
   - Real-time KPI banner: `Active Users`, `Inside Area`, `Outside Area`.
   - Live OpenStreetMap with moving officer pins and geofence boundary circle.
   - Interactive user roster with search, status filters, and click-to-center.

---

### How to Test Live Location Using Two Devices / Emulators

1. **Setup Device 1 (Field Inspector Mobile App):**
   - Run the Flutter app on an Android emulator or physical device.
   - Grant location permission.
   - The app begins transmitting live GPS coordinates to Supabase `location_updates`.
   - In Android Studio Emulator, open the **Extended Controls (...)** > **Location** tab:
     - Set coordinates near the Coimbatore facility (`11.016844, 76.955832`) to verify **INSIDE AUTHORIZED AREA**.
     - Change coordinates to 2km away (`11.032000, 76.968000`) to observe immediate transition to **OUTSIDE AUTHORIZED AREA**.
2. **Setup Device 2 (Government Admin Dashboard):**
   - Open `http://localhost:5173` on your workstation or tablet.
   - Observe the live marker for your field inspector update position in real time via Supabase Realtime without refreshing the page.
   - The marker dynamically reflects status color (Green for inside, Red for outside) and moves smoothly across the OpenStreetMap canvas.

