-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Index Verification
-- ==========================================================
--
-- Read-only. Verifies primary key indexes, foreign key indexes, unique
-- indexes; flags missing indexes on FK columns and duplicate indexes.
--
-- Usage:
--   psql -f verification/verify_indexes.sql <database>
--
-- "missing_fk_indexes" and "duplicate_indexes" should both return zero
-- rows on a fully-indexed schema. As of this writing, missing_fk_indexes
-- is expected to report every FK column added in V7-V12 (see
-- migration_audit.md §8) — this is documented, known technical debt, not
-- a surprise finding.

-- ----------------------------------------------------------
-- 1. Primary key indexes — one per table
-- ----------------------------------------------------------
SELECT
    tc.table_name,
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ----------------------------------------------------------
-- 2. Unique indexes (from UNIQUE constraints)
-- ----------------------------------------------------------
SELECT
    tc.table_name,
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'UNIQUE' AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- ----------------------------------------------------------
-- 3. Explicit (non-constraint-backed) indexes — from CREATE INDEX
--    statements, e.g. the ones in V6__create_indexes.sql
-- ----------------------------------------------------------
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    array_to_string(array_agg(a.attname ORDER BY a.attnum), ', ') AS columns
FROM pg_index ix
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND NOT ix.indisprimary
  AND NOT ix.indisunique
GROUP BY t.relname, i.relname
ORDER BY t.relname, i.relname;

-- ----------------------------------------------------------
-- 4. Missing indexes on foreign key columns
-- ----------------------------------------------------------
WITH fk_columns AS (
    SELECT tc.table_name, kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
),
indexed_leading_columns AS (
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
LEFT JOIN indexed_leading_columns ic ON ic.table_name = fk.table_name AND ic.column_name = fk.column_name
WHERE ic.column_name IS NULL
ORDER BY fk.table_name, fk.column_name;

-- ----------------------------------------------------------
-- 5. Duplicate indexes — two or more indexes on the same table covering
--    the exact same column set
-- ----------------------------------------------------------
WITH index_columns AS (
    SELECT
        t.relname AS table_name,
        i.relname AS index_name,
        array_to_string(array_agg(a.attname ORDER BY a.attnum), ',') AS column_signature
    FROM pg_index ix
    JOIN pg_class t ON t.oid = ix.indrelid
    JOIN pg_class i ON i.oid = ix.indexrelid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
    GROUP BY t.relname, i.relname
)
SELECT table_name, column_signature, array_agg(index_name) AS duplicate_indexes, COUNT(*) AS how_many
FROM index_columns
GROUP BY table_name, column_signature
HAVING COUNT(*) > 1
ORDER BY table_name;
