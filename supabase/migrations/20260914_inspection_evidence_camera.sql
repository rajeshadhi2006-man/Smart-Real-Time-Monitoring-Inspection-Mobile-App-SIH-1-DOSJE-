-- ========================================================================
-- SMART INDIA HACKATHON (SIH) 2026 - DoSJE INSPECTION EVIDENCE SCHEMA
-- Camera-Only In-App Physical Evidence Capture & Immutable Storage
-- ========================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.inspection_evidence (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    evidence_id TEXT UNIQUE NOT NULL,
    inspection_id TEXT NOT NULL,
    assignment_id TEXT,
    officer_id TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    gps_accuracy DOUBLE PRECISION NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL,
    capture_source TEXT NOT NULL DEFAULT 'device_camera' CHECK (capture_source = 'device_camera'),
    category TEXT DEFAULT 'Infrastructure',
    description TEXT,
    sha256_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable indexes for fast lookup and reporting
CREATE INDEX IF NOT EXISTS idx_inspection_evidence_insp ON public.inspection_evidence(inspection_id);
CREATE INDEX IF NOT EXISTS idx_inspection_evidence_asg ON public.inspection_evidence(assignment_id);
CREATE INDEX IF NOT EXISTS idx_inspection_evidence_officer ON public.inspection_evidence(officer_id);
CREATE INDEX IF NOT EXISTS idx_inspection_evidence_captured ON public.inspection_evidence(captured_at DESC);

-- Enable RLS & Policies
ALTER TABLE public.inspection_evidence ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'inspection_evidence' AND policyname = 'Public select inspection_evidence'
    ) THEN
        CREATE POLICY "Public select inspection_evidence" ON public.inspection_evidence FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'inspection_evidence' AND policyname = 'Public insert inspection_evidence'
    ) THEN
        CREATE POLICY "Public insert inspection_evidence" ON public.inspection_evidence FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- Enable Realtime for inspection_evidence
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE inspection_evidence;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
END $$;
