-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V4__create_universal_objects.sql
-- Purpose : Create Universal Objects table
-- ==========================================================

CREATE TABLE universal_objects
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    object_number VARCHAR(50) NOT NULL,

    name VARCHAR(255) NOT NULL,

    description TEXT,

    origin VARCHAR(50) NOT NULL DEFAULT 'Human',

    object_type_id UUID NOT NULL,

    domain_id UUID NOT NULL,

    current_state_id UUID NOT NULL,

    version_major INTEGER NOT NULL DEFAULT 1,

    version_minor INTEGER NOT NULL DEFAULT 0,

    checksum VARCHAR(128),

    created_by VARCHAR(255),

    updated_by VARCHAR(255),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_universal_objects_number
        UNIQUE (object_number),

    CONSTRAINT fk_uo_object_type
        FOREIGN KEY (object_type_id)
        REFERENCES object_types(id),

    CONSTRAINT fk_uo_domain
        FOREIGN KEY (domain_id)
        REFERENCES knowledge_domains(id),

    CONSTRAINT fk_uo_state
        FOREIGN KEY (current_state_id)
        REFERENCES object_states(id)
);