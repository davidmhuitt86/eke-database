-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Engineering Object Verification
-- ==========================================================
--
-- Read-only. A combined health check across Universal Objects, Vehicle
-- Objects, Knowledge Candidates, relationship integrity, and reference
-- data integrity — the "is the engineering data itself sane" companion
-- to verify_schema.sql (which checks structure) and
-- verify_relationship_integrity.sql (which this script's §4 summarizes).
--
-- Usage:
--   psql -f verification/verify_engineering_objects.sql <database>

-- ----------------------------------------------------------
-- 1. Universal Objects — summary by type and state
-- ----------------------------------------------------------
SELECT ot.name AS object_type, os.name AS state, COUNT(*) AS how_many
FROM universal_objects uo
JOIN object_types ot ON ot.id = uo.object_type_id
JOIN object_states os ON os.id = uo.current_state_id
WHERE uo.is_deleted = false
GROUP BY ot.name, os.name
ORDER BY ot.name, os.name;

-- Universal Objects with a dangling object_type_id / domain_id /
-- current_state_id — FK constraints should prevent this; defense-in-depth.
SELECT uo.id, uo.object_number, 'object_type_id not found' AS problem
FROM universal_objects uo
LEFT JOIN object_types ot ON ot.id = uo.object_type_id
WHERE ot.id IS NULL
UNION ALL
SELECT uo.id, uo.object_number, 'domain_id not found'
FROM universal_objects uo
LEFT JOIN knowledge_domains kd ON kd.id = uo.domain_id
WHERE kd.id IS NULL
UNION ALL
SELECT uo.id, uo.object_number, 'current_state_id not found'
FROM universal_objects uo
LEFT JOIN object_states os ON os.id = uo.current_state_id
WHERE os.id IS NULL;

-- Duplicate object_number (UNIQUE constraint should prevent this; sanity check)
SELECT object_number, COUNT(*) AS how_many
FROM universal_objects
GROUP BY object_number
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------
-- 2. Vehicle Objects — every vehicle_objects row must point at a
--    universal_objects row whose type is actually 'Vehicle'
-- ----------------------------------------------------------
SELECT vo.id, vo.universal_object_id, ot.name AS actual_object_type
FROM vehicle_objects vo
JOIN universal_objects uo ON uo.id = vo.universal_object_id
JOIN object_types ot ON ot.id = uo.object_type_id
WHERE ot.name <> 'Vehicle';

-- Universal Objects typed 'Vehicle' with no matching vehicle_objects
-- extension row (informational — not necessarily an error, but worth
-- knowing about since every Vehicle-typed object is expected to have one)
SELECT uo.id, uo.object_number, uo.name
FROM universal_objects uo
JOIN object_types ot ON ot.id = uo.object_type_id
LEFT JOIN vehicle_objects vo ON vo.universal_object_id = uo.id
WHERE ot.name = 'Vehicle' AND vo.id IS NULL AND uo.is_deleted = false;

-- ----------------------------------------------------------
-- 3. Knowledge Candidates — status distribution and orphan check
-- ----------------------------------------------------------
SELECT status, COUNT(*) AS how_many
FROM knowledge_candidates
GROUP BY status
ORDER BY status;

-- Candidates with confidence outside 0-100 (CHECK constraint should
-- prevent this; sanity check)
SELECT id, candidate_number, confidence
FROM knowledge_candidates
WHERE confidence < 0 OR confidence > 100;

-- ----------------------------------------------------------
-- 4. Relationship integrity summary (see verify_relationship_integrity.sql
--    for the detailed per-row breakdown)
-- ----------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM object_relationships) AS total_relationships,
    (SELECT COUNT(*) FROM object_relationships r
        WHERE r.source_object_id = r.target_object_id) AS self_relationships,
    (SELECT COUNT(*) FROM (
        SELECT 1 FROM object_relationships
        GROUP BY source_object_id, target_object_id, relationship_type_id
        HAVING COUNT(*) > 1
    ) dup) AS duplicate_relationship_groups;

-- ----------------------------------------------------------
-- 5. Reference data integrity (see verify_reference_data.sql for the
--    detailed expected-name comparison)
-- ----------------------------------------------------------
SELECT 'object_types' AS table_name, COUNT(*) AS row_count FROM object_types
UNION ALL
SELECT 'knowledge_domains', COUNT(*) FROM knowledge_domains
UNION ALL
SELECT 'object_states', COUNT(*) FROM object_states
UNION ALL
SELECT 'relationship_types', COUNT(*) FROM relationship_types;

-- Expect: object_types=12, knowledge_domains=7, object_states=9,
-- relationship_types=8 (per V3__seed_reference_data.sql)
