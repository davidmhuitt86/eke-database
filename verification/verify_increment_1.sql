-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Increment 1 Verification
-- ==========================================================

-- List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

------------------------------------------------------------

-- Object Types
SELECT *
FROM object_types
ORDER BY name;

------------------------------------------------------------

-- Knowledge Domains
SELECT *
FROM knowledge_domains
ORDER BY name;

------------------------------------------------------------

-- Object States
SELECT *
FROM object_states
ORDER BY name;

------------------------------------------------------------

-- Relationship Types
SELECT *
FROM relationship_types
ORDER BY name;

------------------------------------------------------------

-- Universal Objects
SELECT *
FROM universal_objects;

------------------------------------------------------------

-- Relationships
SELECT *
FROM object_relationships;