-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V2__create_reference_tables.sql
-- Purpose : Create reference (lookup) tables
-- ==========================================================

-- ==========================================================
-- Object Types
-- ==========================================================

CREATE TABLE object_types
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_object_types_name UNIQUE (name)
);

-- ==========================================================
-- Knowledge Domains
-- ==========================================================

CREATE TABLE knowledge_domains
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_knowledge_domains_name UNIQUE (name)
);

-- ==========================================================
-- Object States
-- ==========================================================

CREATE TABLE object_states
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_object_states_name UNIQUE (name)
);

-- ==========================================================
-- Relationship Types
-- ==========================================================

CREATE TABLE relationship_types
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    inverse_name VARCHAR(100),

    is_symmetric BOOLEAN NOT NULL DEFAULT FALSE,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_relationship_types_name UNIQUE (name)
);