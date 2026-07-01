-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Schema Verification
-- ==========================================================
--
-- Read-only. Run this after `flyway migrate` to confirm the database
-- matches the canonical schema defined by migrations/V1-V12. Every query
-- here is a SELECT — nothing is created, altered, or deleted.
--
-- Usage:
--   psql -f verification/verify_schema.sql <database>
--
-- A clean database should show all 12 tables, all 8 indexes from V6,
-- every FK/CHECK/UNIQUE constraint listed below, and zero rows in the
-- "missing_*" result sets at the bottom.

-- ----------------------------------------------------------
-- 1. Tables — expect exactly these 12
-- ----------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Expect: candidate_evidence, candidate_history, candidate_observations,
-- candidate_relationships, knowledge_candidates, knowledge_domains,
-- object_relationships, object_states, object_types, relationship_types,
-- universal_objects, vehicle_objects

-- ----------------------------------------------------------
-- 2. Indexes — expect the 8 explicit indexes from V6, plus the implicit
--    indexes Postgres creates for every PRIMARY KEY and UNIQUE constraint
-- ----------------------------------------------------------
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ----------------------------------------------------------
-- 3. Constraints (PK / UNIQUE / CHECK) per table
-- ----------------------------------------------------------
SELECT tc.table_name, tc.constraint_name, tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- ----------------------------------------------------------
-- 4. Foreign keys — source table/column -> target table/column
-- ----------------------------------------------------------
SELECT
    tc.table_name       AS source_table,
    kcu.column_name      AS source_column,
    ccu.table_name        AS target_table,
    ccu.column_name       AS target_column,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY source_table, source_column;

-- ----------------------------------------------------------
-- 5. Reference data sanity — row counts (see verify_reference_data.sql
--    for the full expected-name comparison)
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

-- ----------------------------------------------------------
-- 6. Missing indexes on foreign key columns
-- ----------------------------------------------------------
-- Known gap (documented in migration_audit.md): V7-V12 never received a
-- corresponding "create indexes" migration the way V4/V5 did in V6.
-- This query lists every FK column that has no index covering it as its
-- leading column — expect this to return rows until a future increment
-- adds the missing indexes (no new migration is added by this audit).
WITH fk_columns AS (
    SELECT tc.table_name, kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
),
indexed_columns AS (
    SELECT
        t.relname AS table_name,
        a.attname AS column_name
    FROM pg_index ix
    JOIN pg_class t ON t.oid = ix.indrelid
    JOIN pg_class i ON i.oid = ix.indexrelid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ix.indkey[0]
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
)
SELECT fk.table_name, fk.column_name AS missing_index_on
FROM fk_columns fk
LEFT JOIN indexed_columns ic ON ic.table_name = fk.table_name AND ic.column_name = fk.column_name
WHERE ic.column_name IS NULL
ORDER BY fk.table_name, fk.column_name;
