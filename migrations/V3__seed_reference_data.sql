-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V3__seed_reference_data.sql
-- Purpose : Seed reference data
-- ==========================================================

-- ==========================================================
-- Object Types
-- ==========================================================

INSERT INTO object_types (name, description)
VALUES
('Vehicle', 'A complete vehicle'),
('Component', 'Individual engineering component'),
('Connector', 'Electrical connector'),
('Wire', 'Electrical conductor'),
('Module', 'Electronic control module'),
('Document', 'Imported engineering document'),
('Diagram', 'Engineering diagram'),
('Observation', 'Observed engineering fact'),
('Evidence', 'Supporting evidence'),
('Measurement', 'Recorded engineering measurement'),
('Procedure', 'Engineering procedure'),
('Knowledge Rule', 'Validated engineering knowledge rule');

-- ==========================================================
-- Knowledge Domains
-- ==========================================================

INSERT INTO knowledge_domains (name, description)
VALUES
('Automotive', 'Automotive engineering'),
('Electrical', 'Electrical engineering'),
('Mechanical', 'Mechanical engineering'),
('Electronics', 'Electronic engineering'),
('Hydraulics', 'Hydraulic systems'),
('Manufacturing', 'Manufacturing processes'),
('Software', 'Software engineering');

-- ==========================================================
-- Object States
-- ==========================================================

INSERT INTO object_states (name, description)
VALUES
('Captured', 'Knowledge has been captured'),
('Pending', 'Awaiting processing'),
('Observed', 'Observation recorded'),
('Reasoned', 'Reasoning completed'),
('Validated', 'Knowledge validated'),
('Universal Object', 'Promoted to Universal Object'),
('Published', 'Available for use'),
('Deprecated', 'No longer recommended'),
('Archived', 'Retained for historical purposes');

-- ==========================================================
-- Relationship Types
-- ==========================================================

INSERT INTO relationship_types
(name, inverse_name, is_symmetric, description)
VALUES
('PART_OF', 'HAS_PART', FALSE, 'Object forms part of another object'),
('CONNECTED_TO', 'CONNECTED_TO', TRUE, 'Objects are physically or logically connected'),
('CAUSES', 'CAUSED_BY', FALSE, 'One object causes another'),
('USES', 'USED_BY', FALSE, 'Object uses another'),
('REFERENCES', 'REFERENCED_BY', FALSE, 'Object references another'),
('DERIVED_FROM', 'DERIVES', FALSE, 'Derived from another object'),
('VALIDATES', 'VALIDATED_BY', FALSE, 'Provides validation'),
('CONTAINS', 'CONTAINED_BY', FALSE, 'Contains another object');