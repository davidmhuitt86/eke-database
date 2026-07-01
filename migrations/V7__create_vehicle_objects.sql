-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V7__create_vehicle_objects.sql
-- Purpose : Vehicle extension table
-- ==========================================================

CREATE TABLE vehicle_objects
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    universal_object_id UUID NOT NULL,

    year SMALLINT,

    manufacturer VARCHAR(100),

    make VARCHAR(100),

    model VARCHAR(100),

    trim VARCHAR(100),

    body_style VARCHAR(100),

    engine VARCHAR(100),

    transmission VARCHAR(100),

    drive_type VARCHAR(50),

    fuel_type VARCHAR(50),

    vin VARCHAR(17),

    production_date DATE,

    market VARCHAR(100),

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_vehicle_universal_object
        FOREIGN KEY (universal_object_id)
        REFERENCES universal_objects(id),

    CONSTRAINT uq_vehicle_universal_object
        UNIQUE (universal_object_id),

    CONSTRAINT uq_vehicle_vin
        UNIQUE (vin)
);