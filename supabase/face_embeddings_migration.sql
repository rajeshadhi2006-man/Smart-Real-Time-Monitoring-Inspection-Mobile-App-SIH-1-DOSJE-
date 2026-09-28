-- ========================================================================
-- MoSJE SIH 2026 - Face Embeddings & Biometric Storage Migration
-- Stores 512-D ArcFace numerical embeddings securely associated with user_id
-- Raw face images are NEVER permanently stored in the database.
-- ========================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.user_face_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) UNIQUE NOT NULL,
    officer_id VARCHAR(64),
    full_name VARCHAR(255),
    embedding JSONB NOT NULL, -- 512-dimensional float array
    model_version VARCHAR(64) NOT NULL DEFAULT 'ArcFace-MobileFaceNet-512',
    quality_score DOUBLE PRECISION DEFAULT 1.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user lookup during verification
CREATE INDEX IF NOT EXISTS idx_user_face_embeddings_user_id ON public.user_face_embeddings(user_id);

-- Enable RLS
ALTER TABLE public.user_face_embeddings ENABLE ROW LEVEL SECURITY;

-- Allow anon read & write for authorized app flows
CREATE POLICY "Allow public read access for user_face_embeddings"
ON public.user_face_embeddings FOR SELECT USING (true);

CREATE POLICY "Allow public insert/update for user_face_embeddings"
ON public.user_face_embeddings FOR ALL USING (true);
