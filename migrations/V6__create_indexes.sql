-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Migration: V6__create_indexes.sql
-- Purpose : Create indexes for Increment 1
-- ==========================================================

CREATE INDEX idx_universal_objects_name
ON universal_objects(name);

CREATE INDEX idx_universal_objects_object_type
ON universal_objects(object_type_id);

CREATE INDEX idx_universal_objects_domain
ON universal_objects(domain_id);

CREATE INDEX idx_universal_objects_state
ON universal_objects(current_state_id);

CREATE INDEX idx_universal_objects_checksum
ON universal_objects(checksum);

CREATE INDEX idx_relationships_source
ON object_relationships(source_object_id);

CREATE INDEX idx_relationships_target
ON object_relationships(target_object_id);

CREATE INDEX idx_relationships_type
ON object_relationships(relationship_type_id);