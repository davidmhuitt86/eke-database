-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V11__create_candidate_evidence.sql
-- Purpose : Store supporting evidence for
--           Knowledge Candidates.
-- ==========================================================

CREATE TABLE candidate_evidence
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    knowledge_candidate_id UUID NOT NULL,

    evidence_type VARCHAR(50) NOT NULL,

    evidence_value TEXT NOT NULL,

    confidence NUMERIC(5,2) NOT NULL DEFAULT 100.00,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_candidate_evidence_candidate
        FOREIGN KEY (knowledge_candidate_id)
        REFERENCES knowledge_candidates(id),

    CONSTRAINT chk_candidate_evidence_confidence
        CHECK (confidence >= 0 AND confidence <= 100)
);