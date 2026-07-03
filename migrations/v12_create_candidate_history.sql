-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V12__create_candidate_history.sql
-- Purpose : Record every state transition for
--           Knowledge Candidates.
-- ==========================================================

CREATE TABLE candidate_history
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    knowledge_candidate_id UUID NOT NULL,

    previous_status VARCHAR(30),

    new_status VARCHAR(30) NOT NULL,

    reason TEXT,

    changed_by VARCHAR(255),

    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_candidate_history_candidate
        FOREIGN KEY (knowledge_candidate_id)
        REFERENCES knowledge_candidates(id)
);