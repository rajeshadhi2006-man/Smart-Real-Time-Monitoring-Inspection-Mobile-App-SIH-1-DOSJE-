-- ========================================================================
-- SMART INDIA HACKATHON (SIH) & DoSJE NATIONAL COMMAND SYSTEM
-- Complete Unified Supabase PostgreSQL Database Schema
-- Single Shared Access for BOTH Government Web Dashboard & Flutter Mobile App
-- Paste & Execute in Supabase SQL Editor: https://supabase.com/dashboard
-- ========================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================================================
-- 1. PROFILES & USERS TABLES
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    officer_id VARCHAR(64) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(32),
    department VARCHAR(128) NOT NULL DEFAULT 'Field Operations',
    designation VARCHAR(128) NOT NULL DEFAULT 'Field Officer',
    role VARCHAR(32) NOT NULL DEFAULT 'OFFICER' CHECK (role IN ('SUPER_ADMIN', 'DOSJE_OFFICIAL', 'STATE_OFFICIAL', 'DISTRICT_OFFICIAL', 'PMU_OFFICER', 'INSPECTION_OFFICER', 'PROJECT_INCHARGE', 'ADMIN', 'OFFICER', 'VIEWER')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    department TEXT NOT NULL DEFAULT 'Field Operations',
    designation TEXT DEFAULT 'Field Personnel',
    role TEXT NOT NULL DEFAULT 'OFFICER',
    status TEXT NOT NULL DEFAULT 'offline',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 2. GEOFENCES & ASSIGNMENTS
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.geofences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    department VARCHAR(128) NOT NULL DEFAULT 'Command Center',
    description TEXT,
    center_latitude DOUBLE PRECISION NOT NULL,
    center_longitude DOUBLE PRECISION NOT NULL,
    radius_meters DOUBLE PRECISION NOT NULL CHECK (radius_meters > 0),
    geometry_type VARCHAR(32) NOT NULL DEFAULT 'CIRCLE' CHECK (geometry_type IN ('CIRCLE', 'POLYGON')),
    polygon_coordinates JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.geofence_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    officer_id VARCHAR(64) NOT NULL,
    user_id TEXT,
    geofence_id UUID NOT NULL REFERENCES public.geofences(id) ON DELETE CASCADE,
    assignment_name VARCHAR(255) DEFAULT 'Perimeter Assignment',
    assigned_by VARCHAR(255) DEFAULT 'Command Officer',
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'REVOKED')),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 3. LOCATION UPDATES & LIVE GPS TELEMETRY
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.location_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    officer_id VARCHAR(64),
    full_name VARCHAR(255),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION DEFAULT 5.0,
    altitude DOUBLE PRECISION DEFAULT 0.0,
    speed DOUBLE PRECISION DEFAULT 0.0,
    heading DOUBLE PRECISION DEFAULT 0.0,
    geofence_id UUID REFERENCES public.geofences(id) ON DELETE SET NULL,
    geofence_name VARCHAR(255),
    geofence_status VARCHAR(32) NOT NULL DEFAULT 'INSIDE' CHECK (geofence_status IN ('INSIDE', 'OUTSIDE', 'BREACH')),
    is_inside_geofence BOOLEAN NOT NULL DEFAULT true,
    device_id VARCHAR(128),
    battery_percentage INTEGER CHECK (battery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.locations (
    user_id TEXT PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION DEFAULT 5.0,
    speed DOUBLE PRECISION DEFAULT 0.0,
    heading DOUBLE PRECISION DEFAULT 0.0,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'online',
    is_inside_geofence INTEGER DEFAULT 1,
    geofence_id TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 4. ATTENDANCE RECORDS
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    officer_id VARCHAR(64),
    full_name VARCHAR(255),
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_time TIMESTAMPTZ,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    geofence_id UUID REFERENCES public.geofences(id) ON DELETE SET NULL,
    face_verified BOOLEAN NOT NULL DEFAULT false,
    voice_verified BOOLEAN NOT NULL DEFAULT false,
    location_verified BOOLEAN NOT NULL DEFAULT false,
    status VARCHAR(32) NOT NULL CHECK (status IN ('PRESENT', 'ABSENT', 'LATE', 'REVIEW', 'LEAVE')),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.attendance (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    officer_id TEXT,
    date TEXT NOT NULL,
    check_in_time TEXT NOT NULL,
    check_out_time TEXT,
    entry_lat DOUBLE PRECISION,
    entry_lng DOUBLE PRECISION,
    exit_lat DOUBLE PRECISION,
    exit_lng DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'PRESENT',
    geofence_verified INTEGER DEFAULT 1,
    face_verified INTEGER DEFAULT 1,
    voice_verified INTEGER DEFAULT 1,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 5. VERIFICATION RECORDS
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.verification_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    user_name VARCHAR(255),
    officer_id VARCHAR(64),
    verification_type VARCHAR(32) NOT NULL CHECK (verification_type IN ('FACE', 'VOICE', 'LOCATION', 'MULTI_FACTOR_FUSION')),
    confidence_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    status VARCHAR(32) NOT NULL CHECK (status IN ('VERIFIED', 'FAILED', 'PENDING', 'REVIEW_REQUIRED', 'MODEL_UNAVAILABLE')),
    failure_reason TEXT,
    details TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.verification_results (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    geofence_id TEXT,
    officer_id TEXT,
    face_result TEXT DEFAULT 'MODEL NOT CONNECTED',
    face_confidence DOUBLE PRECISION DEFAULT 0.0,
    voice_result TEXT DEFAULT 'MODEL NOT CONNECTED',
    voice_confidence DOUBLE PRECISION DEFAULT 0.0,
    gps_result TEXT DEFAULT 'VERIFIED',
    final_result TEXT NOT NULL DEFAULT 'PENDING',
    result TEXT NOT NULL DEFAULT 'PENDING',
    engine_mode TEXT DEFAULT 'PRODUCTION_AI',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata TEXT
);

-- ========================================================================
-- 6. ALERTS & INCIDENT DISPATCH
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128),
    user_name VARCHAR(255),
    officer_id VARCHAR(64),
    severity VARCHAR(32) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'WARNING', 'INFO')),
    alert_type VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    geofence_id UUID REFERENCES public.geofences(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ACKNOWLEDGED', 'RESOLVED')),
    acknowledged_by VARCHAR(255),
    acknowledged_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 7. AUDIT LOGS & DEVICES
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    officer_id VARCHAR(64),
    officer_name VARCHAR(255) NOT NULL,
    action VARCHAR(128) NOT NULL,
    target VARCHAR(255),
    result VARCHAR(32) NOT NULL DEFAULT 'SUCCESS' CHECK (result IN ('SUCCESS', 'DENIED', 'FAILURE')),
    details JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.devices (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    device_id TEXT UNIQUE NOT NULL,
    user_id TEXT,
    device_type TEXT NOT NULL DEFAULT 'FLUTTER_GOV_APP',
    os_version TEXT,
    app_version TEXT,
    battery_level INTEGER DEFAULT 100,
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 8. DoSJE PROJECTS, INSTITUTIONS & CCTV
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.projects (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    scheme TEXT NOT NULL DEFAULT 'PM-AJAY',
    ngo_institute TEXT NOT NULL,
    incharge_name TEXT NOT NULL,
    incharge_phone TEXT,
    state TEXT NOT NULL,
    district TEXT NOT NULL,
    location_address TEXT NOT NULL,
    latitude DOUBLE PRECISION DEFAULT 0.0,
    longitude DOUBLE PRECISION DEFAULT 0.0,
    registered_beneficiaries INTEGER DEFAULT 0,
    staff_count INTEGER DEFAULT 0,
    compliance_status TEXT NOT NULL DEFAULT 'COMPLIANT',
    risk_score DOUBLE PRECISION DEFAULT 0.0,
    geofence_id TEXT,
    cctv_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.cctv_cameras (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    project_id TEXT NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    camera_name TEXT NOT NULL,
    location_description TEXT,
    stream_url TEXT,
    status TEXT NOT NULL DEFAULT 'OFFLINE' CHECK (status IN ('ONLINE', 'OFFLINE', 'UNCONFIGURED')),
    last_heartbeat TIMESTAMPTZ,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 9. INSPECTIONS, REPORTS & EVIDENCE
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.inspection_teams (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    team_name TEXT NOT NULL,
    lead_officer_name TEXT NOT NULL,
    members_json JSONB DEFAULT '[]'::jsonb,
    state TEXT NOT NULL,
    district TEXT NOT NULL,
    availability_status TEXT NOT NULL DEFAULT 'AVAILABLE',
    current_workload INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inspections (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    inspection_code TEXT UNIQUE NOT NULL,
    project_id TEXT NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    project_name TEXT NOT NULL,
    ngo_institute TEXT NOT NULL,
    inspection_type TEXT NOT NULL DEFAULT 'SURPRISE' CHECK (inspection_type IN ('SURPRISE', 'SCHEDULED', 'RANDOM_AI')),
    reason TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    deadline TIMESTAMPTZ,
    team_id TEXT,
    team_name TEXT,
    inspector_id TEXT,
    inspector_name TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED')),
    start_time TIMESTAMPTZ,
    completion_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inspection_reports (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    inspection_id TEXT UNIQUE NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
    project_id TEXT NOT NULL,
    inspector_id TEXT NOT NULL,
    inspector_name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION DEFAULT 5.0,
    geofence_status TEXT DEFAULT 'INSIDE',
    observations TEXT NOT NULL,
    compliance_findings TEXT,
    violations TEXT,
    beneficiary_verification_summary TEXT,
    staff_verification_summary TEXT,
    remarks TEXT,
    final_status TEXT NOT NULL DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inspection_evidence (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    inspection_id TEXT NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
    evidence_type TEXT NOT NULL CHECK (evidence_type IN ('PHOTO', 'VIDEO', 'DOCUMENT')),
    file_url TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    inspector_id TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 10. AI ANOMALIES & VC CALL SESSIONS
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.anomalies (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    entity_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    risk_level TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    reason TEXT NOT NULL,
    evidence_summary TEXT,
    recommended_action TEXT,
    status TEXT NOT NULL DEFAULT 'DETECTED' CHECK (status IN ('DETECTED', 'INVESTIGATING', 'RESOLVED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vc_sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    project_id TEXT NOT NULL,
    project_name TEXT NOT NULL,
    target_person_id TEXT NOT NULL,
    target_person_name TEXT NOT NULL,
    target_role TEXT NOT NULL DEFAULT 'INCHARGE',
    initiator_id TEXT DEFAULT 'COMMAND-OFFICER',
    status TEXT NOT NULL DEFAULT 'REQUESTED' CHECK (status IN ('REQUESTED', 'ACCEPTED', 'REJECTED', 'CONNECTING', 'CONNECTED', 'COMPLETED', 'MISSED', 'FAILED', 'CANCELLED')),
    call_type TEXT DEFAULT 'RANDOM_SURPRISE_VC',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    audit_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- INDEXES FOR PERFORMANCE
-- ========================================================================
CREATE INDEX IF NOT EXISTS idx_geofences_active ON public.geofences (is_active);
CREATE INDEX IF NOT EXISTS idx_location_updates_user_id ON public.location_updates (user_id);
CREATE INDEX IF NOT EXISTS idx_location_updates_created_at ON public.location_updates (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON public.alerts (status);
CREATE INDEX IF NOT EXISTS idx_attendance_created_at ON public.attendance_records (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inspections_status ON public.inspections (status);
CREATE INDEX IF NOT EXISTS idx_projects_state ON public.projects (state);

-- ========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR BOTH WEB & FLUTTER APP
-- ========================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geofences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geofence_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cctv_cameras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vc_sessions ENABLE ROW LEVEL SECURITY;

-- Unified RLS Policies (Allow Read/Write for Anon & Authenticated Clients)
DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Unified read %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Unified read %I" ON public.%I FOR SELECT TO anon, authenticated USING (true)', tbl, tbl);
        
        EXECUTE format('DROP POLICY IF EXISTS "Unified insert %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Unified insert %I" ON public.%I FOR INSERT TO anon, authenticated WITH CHECK (true)', tbl, tbl);
        
        EXECUTE format('DROP POLICY IF EXISTS "Unified update %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Unified update %I" ON public.%I FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true)', tbl, tbl);

        EXECUTE format('DROP POLICY IF EXISTS "Unified delete %I" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "Unified delete %I" ON public.%I FOR DELETE TO anon, authenticated USING (true)', tbl, tbl);
    END LOOP;
END
$$;

-- ========================================================================
-- REALTIME REPLICATION PUBLICATION FOR BOTH APP & WEB
-- ========================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;

  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.geofences; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.location_updates; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.locations; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_records; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_records; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_results; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.inspections; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.inspection_reports; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.inspection_evidence; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.vc_sessions; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.anomalies; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.devices; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_profiles; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_verification_logs; EXCEPTION WHEN OTHERS THEN NULL; END;
END
$$;

-- ========================================================================
-- VOICE BIOMETRIC (SPEECHBRAIN ECAPA-TDNN) TABLES
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.voice_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) UNIQUE NOT NULL,
    officer_id VARCHAR(128),
    voice_profile_id VARCHAR(64) UNIQUE,
    embedding JSONB NOT NULL,
    embedding_dimensions INT NOT NULL DEFAULT 192,
    model_name VARCHAR(128) NOT NULL DEFAULT 'speechbrain/spkrec-ecapa-voxceleb',
    model_version VARCHAR(64) NOT NULL DEFAULT 'ECAPA-TDNN-192',
    sample_count INT NOT NULL DEFAULT 3,
    passphrase TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.voice_verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) NOT NULL,
    score NUMERIC(6, 4) NOT NULL,
    threshold NUMERIC(6, 4) NOT NULL,
    result VARCHAR(32) NOT NULL,
    model_name VARCHAR(128) NOT NULL DEFAULT 'speechbrain/spkrec-ecapa-voxceleb',
    model_version VARCHAR(64) NOT NULL DEFAULT 'ECAPA-TDNN-192',
    processing_time_ms NUMERIC(10, 2),
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voice_profiles_user_id ON public.voice_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_verification_logs_user_id ON public.voice_verification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_verification_logs_created_at ON public.voice_verification_logs(created_at DESC);

ALTER TABLE public.voice_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_verification_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public voice_profiles select" ON public.voice_profiles;
CREATE POLICY "Allow public voice_profiles select" ON public.voice_profiles FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Allow public voice_profiles insert" ON public.voice_profiles;
CREATE POLICY "Allow public voice_profiles insert" ON public.voice_profiles FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public voice_profiles update" ON public.voice_profiles;
CREATE POLICY "Allow public voice_profiles update" ON public.voice_profiles FOR UPDATE TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow public voice_logs select" ON public.voice_verification_logs;
CREATE POLICY "Allow public voice_logs select" ON public.voice_verification_logs FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Allow public voice_logs insert" ON public.voice_verification_logs;
CREATE POLICY "Allow public voice_logs insert" ON public.voice_verification_logs FOR INSERT TO anon, authenticated WITH CHECK (true);
