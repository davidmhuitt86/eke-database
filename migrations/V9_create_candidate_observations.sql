-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V9__create_candidate_observations.sql
-- Purpose : Store every observation made about a
--           Knowledge Candidate.
-- ==========================================================

CREATE TABLE candidate_observations
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    knowledge_candidate_id UUID NOT NULL,

    observation_text TEXT NOT NULL,

    source_type VARCHAR(50) NOT NULL,

    source_reference VARCHAR(255),

    confidence NUMERIC(5,2) NOT NULL DEFAULT 100.00,

    observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_candidate_observation_candidate
        FOREIGN KEY (knowledge_candidate_id)
        REFERENCES knowledge_candidates(id),

    CONSTRAINT chk_candidate_observation_confidence
        CHECK (confidence >= 0 AND confidence <= 100)
);