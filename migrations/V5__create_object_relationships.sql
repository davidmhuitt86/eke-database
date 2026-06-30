-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V5__create_object_relationships.sql
-- Purpose : Create relationships between Universal Objects
-- ==========================================================

CREATE TABLE object_relationships
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_object_id UUID NOT NULL,

    target_object_id UUID NOT NULL,

    relationship_type_id UUID NOT NULL,

    confidence NUMERIC(5,2) NOT NULL DEFAULT 100.00,

    created_by VARCHAR(255),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_relationship_source
        FOREIGN KEY (source_object_id)
        REFERENCES universal_objects(id),

    CONSTRAINT fk_relationship_target
        FOREIGN KEY (target_object_id)
        REFERENCES universal_objects(id),

    CONSTRAINT fk_relationship_type
        FOREIGN KEY (relationship_type_id)
        REFERENCES relationship_types(id),

    CONSTRAINT chk_relationship_confidence
        CHECK (confidence >= 0 AND confidence <= 100)
);