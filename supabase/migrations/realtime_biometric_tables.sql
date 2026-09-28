-- ============================================================
-- SIH Biometric Enrollment — Real-Time Database Migration
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Voice Templates Table (NEW — for real MFCC voice enrollment)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voice_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    officer_id TEXT,
    fingerprint FLOAT[] NOT NULL,          -- MFCC fingerprint vector (40-D)
    fingerprint_dimensions INT DEFAULT 40,
    model_version TEXT DEFAULT 'mfcc_librosa_v1',
    passphrase TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable realtime for voice_templates
ALTER PUBLICATION supabase_realtime ADD TABLE voice_templates;

-- Row Level Security
ALTER TABLE voice_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "voice_templates_user_access" ON voice_templates
    FOR ALL USING (true);  -- Adjust for production: auth.uid()::text = user_id

-- ────────────────────────────────────────────────────────────
-- 2. Enrollment Status Table (NEW — tracks per-user enrollment progress)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS enrollment_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    officer_id TEXT,
    face_enrolled BOOLEAN DEFAULT FALSE,
    face_enrolled_at TIMESTAMPTZ,
    voice_enrolled BOOLEAN DEFAULT FALSE,
    voice_enrolled_at TIMESTAMPTZ,
    location_enrolled BOOLEAN DEFAULT FALSE,
    location_enrolled_at TIMESTAMPTZ,
    overall_status TEXT DEFAULT 'NOT_STARTED',
    -- Possible values: NOT_STARTED, FACE_PENDING, FACE_ENROLLED,
    --                  VOICE_PENDING, VOICE_ENROLLED, LOCATION_PENDING,
    --                  LOCATION_ENROLLED, FULLY_ENROLLED, VERIFICATION_FAILED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER PUBLICATION supabase_realtime ADD TABLE enrollment_status;
ALTER TABLE enrollment_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "enrollment_status_access" ON enrollment_status FOR ALL USING (true);

-- ────────────────────────────────────────────────────────────
-- 3. Geofence Events Table (NEW — real entry/exit events)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS geofence_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    officer_id TEXT,
    geofence_id TEXT NOT NULL,
    geofence_name TEXT,
    event_type TEXT NOT NULL CHECK (event_type IN ('ENTRY', 'EXIT')),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER PUBLICATION supabase_realtime ADD TABLE geofence_events;
ALTER TABLE geofence_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "geofence_events_access" ON geofence_events FOR ALL USING (true);

-- Index for fast user lookups
CREATE INDEX IF NOT EXISTS idx_geofence_events_user_id ON geofence_events(user_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_timestamp ON geofence_events(timestamp DESC);

-- ────────────────────────────────────────────────────────────
-- 4. User Geofence Assignments (NEW — maps users to geofences)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_geofence_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    geofence_id UUID REFERENCES geofences(id) ON DELETE CASCADE,
    assigned_by TEXT,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_geofence_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_geofence_assignments_access" ON user_geofence_assignments FOR ALL USING (true);

-- ────────────────────────────────────────────────────────────
-- 5. Update geofences table to ensure required columns exist
-- ────────────────────────────────────────────────────────────
DO $$ BEGIN
    -- Add is_active column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'geofences' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE geofences ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- ────────────────────────────────────────────────────────────
-- 6. Update user_face_embeddings to track enrollment timestamp
-- ────────────────────────────────────────────────────────────
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_face_embeddings' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE user_face_embeddings ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- ────────────────────────────────────────────────────────────
-- 7. Sample geofence data (replace with real inspection zones)
-- ────────────────────────────────────────────────────────────
INSERT INTO geofences (name, center_latitude, center_longitude, radius_meters, department, description, is_active)
VALUES
    ('Coimbatore Field Operations Center', 11.016844, 76.955832, 200.0, 'MoSJE Field Inspection Directorate', 'Primary welfare inspection zone', true),
    ('Chennai Welfare Inspection Zone', 13.082680, 80.270718, 300.0, 'MoSJE Field Inspection Directorate', 'Chennai regional inspection zone', true)
ON CONFLICT DO NOTHING;
