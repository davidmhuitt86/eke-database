-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V8__create_knowledge_candidates.sql
-- Purpose : Store unknown engineering entities awaiting
--           classification and promotion.
-- ==========================================================

CREATE TABLE knowledge_candidates
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    candidate_number VARCHAR(50) NOT NULL,

    observed_name VARCHAR(255) NOT NULL,

    proposed_type VARCHAR(100),

    confidence NUMERIC(5,2) NOT NULL DEFAULT 0.00,

    status VARCHAR(30) NOT NULL DEFAULT 'UNCLASSIFIED',

    first_observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    last_observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    observation_count INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_candidate_number
        UNIQUE(candidate_number),

    CONSTRAINT chk_candidate_confidence
        CHECK(confidence >= 0 AND confidence <= 100)
);