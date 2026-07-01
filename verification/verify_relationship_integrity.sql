-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Relationship Integrity Verification
-- ==========================================================
--
-- Read-only. Every result set below should be empty on a healthy
-- database. Covers object_relationships (the permanent graph) and, where
-- the tables exist, candidate_relationships (the pre-commit graph).
--
-- Usage:
--   psql -f verification/verify_relationship_integrity.sql <database>

-- ----------------------------------------------------------
-- 1. Broken foreign keys in object_relationships
-- ----------------------------------------------------------
-- Postgres FK constraints already prevent this from ever happening while
-- the constraints are in place — this query exists as a defense-in-depth
-- check (e.g. after a restore, a manual data load, or a constraint being
-- dropped and re-added incorrectly).
SELECT r.id, 'source_object_id not found' AS problem
FROM object_relationships r
LEFT JOIN universal_objects o ON o.id = r.source_object_id
WHERE o.id IS NULL
UNION ALL
SELECT r.id, 'target_object_id not found'
FROM object_relationships r
LEFT JOIN universal_objects o ON o.id = r.target_object_id
WHERE o.id IS NULL
UNION ALL
SELECT r.id, 'relationship_type_id not found'
FROM object_relationships r
LEFT JOIN relationship_types t ON t.id = r.relationship_type_id
WHERE t.id IS NULL;

-- ----------------------------------------------------------
-- 2. Self-relationships (source = target)
-- ----------------------------------------------------------
-- Not currently prevented by a CHECK constraint (documented gap in
-- migration_audit.md §9) — this query is how to detect them until that's
-- addressed.
SELECT id, source_object_id, target_object_id, relationship_type_id
FROM object_relationships
WHERE source_object_id = target_object_id;

-- ----------------------------------------------------------
-- 3. Duplicate relationships (identical source/target/type more than once)
-- ----------------------------------------------------------
-- Not currently prevented by a UNIQUE constraint (documented gap in
-- migration_audit.md §9).
SELECT source_object_id, target_object_id, relationship_type_id, COUNT(*) AS how_many
FROM object_relationships
GROUP BY source_object_id, target_object_id, relationship_type_id
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------
-- 4. Orphaned universal_objects — no relationship at all, in either
--    direction (informational, not necessarily a problem: a freshly
--    committed object may legitimately have no relationships yet)
-- ----------------------------------------------------------
SELECT o.id, o.object_number, o.name
FROM universal_objects o
WHERE o.is_deleted = false
  AND NOT EXISTS (SELECT 1 FROM object_relationships r WHERE r.source_object_id = o.id)
  AND NOT EXISTS (SELECT 1 FROM object_relationships r WHERE r.target_object_id = o.id);

-- ----------------------------------------------------------
-- 5. candidate_relationships integrity (only runs meaningfully once V10
--    is live — see migration_audit.md; on a V1-V8 database this table
--    doesn't exist and this block will error, so it's split out here
--    rather than combined with the object_relationships checks above)
-- ----------------------------------------------------------
-- Rows with neither a related Universal Object nor a related candidate —
-- the documented "floating relationship" gap (migration_audit.md §9).
-- Uncomment once V10 (candidate_relationships) is live:
--
-- SELECT id, knowledge_candidate_id
-- FROM candidate_relationships
-- WHERE related_universal_object_id IS NULL
--   AND related_candidate_id IS NULL;
--
-- Rows with both set simultaneously (ambiguous target):
--
-- SELECT id, knowledge_candidate_id, related_universal_object_id, related_candidate_id
-- FROM candidate_relationships
-- WHERE related_universal_object_id IS NOT NULL
--   AND related_candidate_id IS NOT NULL;
