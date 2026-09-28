-- ========================================================================
-- SMART REAL-TIME GEO-TAGGED ASSIGNMENT SUBMISSION SYSTEM
-- Supabase PostgreSQL Schema Migration
-- ========================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ASSIGNMENTS TABLE
CREATE TABLE IF NOT EXISTS public.assignments (
    assignment_id VARCHAR(64) PRIMARY KEY,
    assigned_user_id TEXT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_location VARCHAR(255) NOT NULL,
    target_latitude DOUBLE PRECISION NOT NULL,
    target_longitude DOUBLE PRECISION NOT NULL,
    target_geohash VARCHAR(16) NOT NULL,
    allowed_radius_meters DOUBLE PRECISION NOT NULL DEFAULT 200.0,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '48 hours'),
    status VARCHAR(32) NOT NULL DEFAULT 'ASSIGNED' CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'EXPIRED', 'MISSED')),
    evidence_requirement VARCHAR(64) NOT NULL DEFAULT 'GEO_TAGGED_PHOTO',
    assigned_by VARCHAR(255) DEFAULT 'State PMU Command Center',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user assignment queries
CREATE INDEX IF NOT EXISTS idx_assignments_user ON public.assignments(assigned_user_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_geohash ON public.assignments(target_geohash);

-- 2. ASSIGNMENT EVIDENCE TABLE
CREATE TABLE IF NOT EXISTS public.assignment_evidence (
    evidence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id VARCHAR(64) NOT NULL REFERENCES public.assignments(assignment_id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    image_url TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geohash VARCHAR(16) NOT NULL,
    gps_accuracy DOUBLE PRECISION NOT NULL,
    altitude DOUBLE PRECISION DEFAULT 0.0,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    server_verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    location_verified BOOLEAN NOT NULL DEFAULT true,
    verification_reason TEXT,
    submission_status VARCHAR(64) NOT NULL DEFAULT 'VERIFIED',
    distance_meters DOUBLE PRECISION,
    device_info TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for evidence queries
CREATE INDEX IF NOT EXISTS idx_assignment_evidence_asg ON public.assignment_evidence(assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_evidence_user ON public.assignment_evidence(user_id);
CREATE INDEX IF NOT EXISTS idx_assignment_evidence_created ON public.assignment_evidence(created_at DESC);

-- Enable Realtime for live updates to Government Dashboard
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.assignments;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.assignment_evidence;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

-- 3. SEED INITIAL ASSIGNMENTS FOR IMMEDIATE TESTING
INSERT INTO public.assignments (
    assignment_id,
    assigned_user_id,
    title,
    description,
    assigned_location,
    target_latitude,
    target_longitude,
    target_geohash,
    allowed_radius_meters,
    start_time,
    end_time,
    status,
    evidence_requirement,
    assigned_by
) VALUES 
(
    'ASG-2026-101',
    'officer@surveillance.gov.in',
    'Elderly Care Home Physical Audit',
    'Verify structural compliance, resident rehabilitation facilities, and attendance records on-site.',
    'Coimbatore District Social Welfare Center',
    11.016844,
    76.955832,
    't9zcq5p8',
    300.0,
    NOW() - INTERVAL '1 hour',
    NOW() + INTERVAL '24 hours',
    'ASSIGNED',
    'GEO_TAGGED_PHOTO',
    'Director, Social Defense Department'
),
(
    'ASG-2026-102',
    'officer_sharma_104',
    'PM-AJAY Divyangjan Skill Center Inspection',
    'Inspect computer lab equipment, assistive devices availability, and live beneficiary training.',
    'Regional Vocational Training Institute',
    11.021500,
    76.960200,
    't9zcqk2x',
    250.0,
    NOW() - INTERVAL '2 hours',
    NOW() + INTERVAL '36 hours',
    'ASSIGNED',
    'GEO_TAGGED_PHOTO',
    'State PMU Inspection Wing'
),
(
    'ASG-2026-103',
    'OFF-001',
    'De-Addiction & Counseling Center Surprise Audit',
    'Verify stock register, counselor presence, and clean living quarters per MoSJE 2026 guidelines.',
    'Central Government IRCA Facility',
    11.012300,
    76.951100,
    't9zcq1v9',
    200.0,
    NOW() - INTERVAL '30 minutes',
    NOW() + INTERVAL '12 hours',
    'ASSIGNED',
    'GEO_TAGGED_PHOTO',
    'Joint Secretary (Social Justice)'
)
ON CONFLICT (assignment_id) DO UPDATE SET
    status = EXCLUDED.status,
    target_latitude = EXCLUDED.target_latitude,
    target_longitude = EXCLUDED.target_longitude,
    target_geohash = EXCLUDED.target_geohash,
    updated_at = NOW();
