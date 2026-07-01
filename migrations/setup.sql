-- ==========================================================
-- Engineering Knowledge Engine (EKE)
-- Bootstrap helper
-- ==========================================================
--
-- This file is NOT a migration runner. It used to manually \i each
-- migration file in order, which is exactly how this database ended up
-- out of sync with the files in migrations/ (see MIGRATION_AUDIT.md at
-- the repo root) — new migrations were added on disk and never added
-- here, so running this file stopped reflecting reality.
--
-- Flyway is the only supported migration mechanism for this database.
-- Do not add \i includes back to this file.
--
-- To apply all migrations:
--
--   flyway -configFiles=flyway.conf migrate
--
-- To check current status without applying anything:
--
--   flyway -configFiles=flyway.conf info
--
-- Running this file directly (e.g. `psql -f setup.sql`) is safe — it is a
-- no-op. It will attempt to invoke the Flyway CLI below if psql is run
-- interactively with shell access; if Flyway isn't installed or on PATH,
-- that line simply fails harmlessly and the instructions above still
-- apply.

\echo 'setup.sql no longer applies migrations directly.'
\echo 'Run: flyway -configFiles=flyway.conf migrate'
\! flyway -configFiles=flyway.conf info
