-- ========================================================================
-- SMART INDIA HACKATHON (SIH) 2026 - MoSJE / DoSJE Unified Biometric Schema
-- Run this complete script in the Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ========================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================================================
-- 1. USER FACE EMBEDDINGS (512-D ArcFace Biometrics)
-- Stores 512-dimensional ArcFace vectors without storing raw photos
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.user_face_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) UNIQUE NOT NULL,
    officer_id VARCHAR(64),
    full_name VARCHAR(255),
    embedding JSONB NOT NULL,                 -- 512-D float array [0.034, 0.982, ...]
    model_version VARCHAR(64) NOT NULL DEFAULT 'ArcFace-MobileFaceNet-512',
    quality_score DOUBLE PRECISION DEFAULT 1.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for instant lookup by user_id and officer_id
CREATE INDEX IF NOT EXISTS idx_user_face_embeddings_user_id ON public.user_face_embeddings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_face_embeddings_officer_id ON public.user_face_embeddings(officer_id);

-- Enable RLS & open policies
ALTER TABLE public.user_face_embeddings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access for user_face_embeddings" ON public.user_face_embeddings;
CREATE POLICY "Allow public read access for user_face_embeddings"
ON public.user_face_embeddings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public write access for user_face_embeddings" ON public.user_face_embeddings;
CREATE POLICY "Allow public write access for user_face_embeddings"
ON public.user_face_embeddings FOR ALL USING (true);


-- ========================================================================
-- 2. VOICE BIOMETRIC TEMPLATES (MFCC Audio Fingerprints)
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.voice_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL UNIQUE,
    officer_id TEXT,
    fingerprint FLOAT[] NOT NULL,              -- 40-D MFCC feature vector
    fingerprint_dimensions INT DEFAULT 40,
    model_version TEXT DEFAULT 'mfcc_librosa_v1',
    passphrase TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voice_templates_user_id ON public.voice_templates(user_id);

ALTER TABLE public.voice_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "voice_templates_access" ON public.voice_templates;
CREATE POLICY "voice_templates_access" ON public.voice_templates FOR ALL USING (true);


-- ========================================================================
-- 3. ENROLLMENT STATUS TRACKER (Multi-Factor Progress)
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.enrollment_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL UNIQUE,
    officer_id TEXT,
    face_enrolled BOOLEAN DEFAULT FALSE,
    face_enrolled_at TIMESTAMPTZ,
    voice_enrolled BOOLEAN DEFAULT FALSE,
    voice_enrolled_at TIMESTAMPTZ,
    location_enrolled BOOLEAN DEFAULT FALSE,
    location_enrolled_at TIMESTAMPTZ,
    overall_status TEXT DEFAULT 'NOT_STARTED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.enrollment_status ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "enrollment_status_access" ON public.enrollment_status;
CREATE POLICY "enrollment_status_access" ON public.enrollment_status FOR ALL USING (true);


-- ========================================================================
-- 4. VERIFICATION RECORDS (Biometric Audit Logs)
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.verification_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    user_name VARCHAR(255),
    officer_id VARCHAR(64),
    verification_type VARCHAR(32) NOT NULL DEFAULT 'FACE',
    confidence_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    status VARCHAR(32) NOT NULL DEFAULT 'VERIFIED',
    failure_reason TEXT,
    details TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure officer_id column exists if table was created previously without it
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'verification_records' AND column_name = 'officer_id'
    ) THEN
        ALTER TABLE public.verification_records ADD COLUMN officer_id VARCHAR(64);
    END IF;
END $$;

ALTER TABLE public.verification_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "verification_records_access" ON public.verification_records;
CREATE POLICY "verification_records_access" ON public.verification_records FOR ALL USING (true);


-- ========================================================================
-- 5. ALERTS & INCIDENTS (Real-Time Command Dispatch)
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128),
    user_name VARCHAR(255),
    officer_id VARCHAR(64),
    severity VARCHAR(32) NOT NULL DEFAULT 'CRITICAL',
    alert_type VARCHAR(64) NOT NULL DEFAULT 'BIOMETRIC_MISMATCH',
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    geofence_id UUID,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    acknowledged_by VARCHAR(255),
    acknowledged_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "alerts_access" ON public.alerts;
CREATE POLICY "alerts_access" ON public.alerts FOR ALL USING (true);


-- ========================================================================
-- 6. GEOFENCE EVENTS (Real-Time Entry & Exit)
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.geofence_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    officer_id TEXT,
    geofence_id TEXT NOT NULL,
    geofence_name TEXT,
    event_type TEXT NOT NULL CHECK (event_type IN ('ENTRY', 'EXIT', 'BREACH')),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geofence_events_user_id ON public.geofence_events(user_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_timestamp ON public.geofence_events(timestamp DESC);

ALTER TABLE public.geofence_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "geofence_events_access" ON public.geofence_events;
CREATE POLICY "geofence_events_access" ON public.geofence_events FOR ALL USING (true);


-- ========================================================================
-- 7. ENABLE REAL-TIME REPLICATION FOR LIVE SYNC
-- ========================================================================
DO $$ BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_face_embeddings;
    EXCEPTION WHEN duplicate_object THEN END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_templates;
    EXCEPTION WHEN duplicate_object THEN END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.enrollment_status;
    EXCEPTION WHEN duplicate_object THEN END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.geofence_events;
    EXCEPTION WHEN duplicate_object THEN END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_records;
    EXCEPTION WHEN duplicate_object THEN END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
    EXCEPTION WHEN duplicate_object THEN END;
END $$;
