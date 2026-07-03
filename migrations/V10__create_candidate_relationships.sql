-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V10__create_candidate_relationships.sql
-- Purpose : Store inferred relationships between
--           Knowledge Candidates and known objects.
-- ==========================================================

CREATE TABLE candidate_relationships
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    knowledge_candidate_id UUID NOT NULL,

    related_universal_object_id UUID,

    related_candidate_id UUID,

    relationship_type_id UUID NOT NULL,

    confidence NUMERIC(5,2) NOT NULL DEFAULT 0.00,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_candidate_relationship_candidate
        FOREIGN KEY (knowledge_candidate_id)
        REFERENCES knowledge_candidates(id),

    CONSTRAINT fk_candidate_relationship_object
        FOREIGN KEY (related_universal_object_id)
        REFERENCES universal_objects(id),

    CONSTRAINT fk_candidate_relationship_candidate2
        FOREIGN KEY (related_candidate_id)
        REFERENCES knowledge_candidates(id),

    CONSTRAINT fk_candidate_relationship_type
        FOREIGN KEY (relationship_type_id)
        REFERENCES relationship_types(id),

    CONSTRAINT chk_candidate_relationship_confidence
        CHECK (confidence >= 0 AND confidence <= 100)
);