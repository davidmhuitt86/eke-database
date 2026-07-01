-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Reference Data Verification
-- ==========================================================
--
-- Read-only. Confirms object_types, knowledge_domains, relationship_types
-- and object_states contain exactly the rows seeded by
-- V3__seed_reference_data.sql — no more, no fewer, no misspellings.
--
-- Usage:
--   psql -f verification/verify_reference_data.sql <database>
--
-- Every "missing_*" / "unexpected_*" query should return zero rows on a
-- correctly-migrated database.

-- ----------------------------------------------------------
-- object_types — expect exactly these 12 names
-- ----------------------------------------------------------
WITH expected(name) AS (VALUES
    ('Vehicle'), ('Component'), ('Connector'), ('Wire'), ('Module'),
    ('Document'), ('Diagram'), ('Observation'), ('Evidence'),
    ('Measurement'), ('Procedure'), ('Knowledge Rule')
)
SELECT 'object_types: missing' AS check_name, e.name
FROM expected e
LEFT JOIN object_types o ON o.name = e.name
WHERE o.id IS NULL
UNION ALL
SELECT 'object_types: unexpected', o.name
FROM object_types o
LEFT JOIN expected e ON e.name = o.name
WHERE e.name IS NULL;

-- ----------------------------------------------------------
-- knowledge_domains — expect exactly these 7 names
-- ----------------------------------------------------------
WITH expected(name) AS (VALUES
    ('Automotive'), ('Electrical'), ('Mechanical'), ('Electronics'),
    ('Hydraulics'), ('Manufacturing'), ('Software')
)
SELECT 'knowledge_domains: missing' AS check_name, e.name
FROM expected e
LEFT JOIN knowledge_domains d ON d.name = e.name
WHERE d.id IS NULL
UNION ALL
SELECT 'knowledge_domains: unexpected', d.name
FROM knowledge_domains d
LEFT JOIN expected e ON e.name = d.name
WHERE e.name IS NULL;

-- ----------------------------------------------------------
-- object_states — expect exactly these 9 names
-- ----------------------------------------------------------
WITH expected(name) AS (VALUES
    ('Captured'), ('Pending'), ('Observed'), ('Reasoned'), ('Validated'),
    ('Universal Object'), ('Published'), ('Deprecated'), ('Archived')
)
SELECT 'object_states: missing' AS check_name, e.name
FROM expected e
LEFT JOIN object_states s ON s.name = e.name
WHERE s.id IS NULL
UNION ALL
SELECT 'object_states: unexpected', s.name
FROM object_states s
LEFT JOIN expected e ON e.name = s.name
WHERE e.name IS NULL;

-- ----------------------------------------------------------
-- relationship_types — expect exactly these 8 names
-- (intentionally incomplete for Increment 1 — MEASURED_AT, OBSERVED_IN
-- and other richer relationship types are deferred to a future
-- Database Increment; their absence here is expected, not an error)
-- ----------------------------------------------------------
WITH expected(name) AS (VALUES
    ('PART_OF'), ('CONNECTED_TO'), ('CAUSES'), ('USES'),
    ('REFERENCES'), ('DERIVED_FROM'), ('VALIDATES'), ('CONTAINS')
)
SELECT 'relationship_types: missing' AS check_name, e.name
FROM expected e
LEFT JOIN relationship_types r ON r.name = e.name
WHERE r.id IS NULL
UNION ALL
SELECT 'relationship_types: unexpected', r.name
FROM relationship_types r
LEFT JOIN expected e ON e.name = r.name
WHERE e.name IS NULL;
