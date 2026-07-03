# Database Status

Last updated: 2026-07-01, after the AP-005E baseline-and-migrate operation.
This is a point-in-time snapshot of the **development** database
(`jdbc:postgresql://localhost:5432/eke`). Re-run `flyway info` for the
live current state — this file will drift the moment a new migration
ships.

## Current schema version

**12** — fully synchronized with the canonical migration set on disk
(V1 through V12, all applied).

## How it got there

1. **Before this operation**: the database had the schema produced by
   V1-V8, applied by an undocumented manual process, never tracked by
   Flyway (no `flyway_schema_history` table existed at all — see
   `migration_audit.md`).
2. **Root cause fixed**: five migration files (V8-V12) violated Flyway's
   naming contract (missing double underscore; V11/V12 additionally
   lowercase `v`), which is why Flyway could never recognize or apply
   them, independent of any `flyway.conf` issue. Renamed via `git mv`
   (verified zero content diff — `0 insertions(+), 0 deletions(-)`):
   - `V8_create_knowledge_candidates.sql` → `V8__create_knowledge_candidates.sql`
   - `V9_create_candidate_observations.sql` → `V9__create_candidate_observations.sql`
   - `V10_create_candidate_relationships.sql` → `V10__create_candidate_relationships.sql`
   - `v11_create_candidate_evidence.sql` → `V11__create_candidate_evidence.sql`
   - `v12_create_candidate_history.sql` → `V12__create_candidate_history.sql`
3. **Baselined** at version 8 (justification: this is exactly what was
   verifiably, already correctly applied — confirmed via
   `verify_reference_data.sql` matching the V3 seed exactly before this
   operation began):
   ```
   flyway -configFiles=flyway.conf baseline -baselineVersion=8 -baselineDescription="Manually applied V1-V8 prior to Flyway management (see migration_audit.md)"
   ```
4. **Validated**, then **migrated** — V9, V10, V11, V12 applied cleanly:
   ```
   flyway -configFiles=flyway.conf validate
   flyway -configFiles=flyway.conf migrate
   ```

A full logical backup (JSON dump of every row in every pre-existing
table) was taken immediately before this operation, before any command
that could alter schema was run.

## Applied migrations

| Version | Description | State | Installed On |
|---|---|---|---|
| 1-7 | enable extensions ... create vehicle objects | Below Baseline (pre-existing, not individually tracked) | — |
| 8 | create knowledge candidates | Baseline | 2026-07-01 18:52:38 |
| 9 | create candidate observations | Success | 2026-07-01 18:53:52 |
| 10 | create candidate relationships | Success | 2026-07-01 18:53:52 |
| 11 | create candidate evidence | Success | 2026-07-01 18:53:52 |
| 12 | create candidate history | Success | 2026-07-01 18:53:53 |

`flyway_schema_history` now exists and records baseline + all 4 migrated
versions (5 rows, all `success: true`).

## Pending migrations

None. V1-V12 is the complete migration set currently on disk; all are
applied.

## Verification results

All five scripts in `verification/` ran clean (zero SQL errors) against
the post-migration database:

- **`verify_schema.sql`**: all 13 tables present (12 schema + `flyway_
  schema_history`), all 14 foreign keys present, reference data counts
  correct (object_types=12, knowledge_domains=7, object_states=9,
  relationship_types=8).
- **`verify_reference_data.sql`**: zero missing/unexpected rows across
  all four reference tables — exact match to `V3__seed_reference_data.sql`.
- **`verify_indexes.sql`**: all 13 PK indexes and 8 unique indexes present;
  9 explicit indexes from V6 confirmed; **7 missing FK indexes on V9-V12
  columns confirmed present as a real, now-live gap** (previously this
  check returned 0 rows only because those tables didn't exist yet — see
  Known Issues below).
- **`verify_relationship_integrity.sql`**: zero broken FKs, zero
  self-relationships, zero duplicate relationships, zero orphaned
  Universal Objects.
- **`verify_engineering_objects.sql`**: 2 Universal Objects (1 Vehicle, 1
  Component, both state "Universal Object"), 1 relationship (no self/
  duplicate), zero integrity problems, reference data counts confirmed
  again.

## Known issues (carried forward, not fixed by this operation)

Per this work package's restrictions (rename only — no migration content
changes), the following technical debt documented in `migration_audit.md`
is now **live and confirmed** rather than theoretical:

- **Missing FK indexes** on `candidate_observations.knowledge_candidate_id`,
  `candidate_relationships.knowledge_candidate_id`/`.related_candidate_id`/
  `.related_universal_object_id`/`.relationship_type_id`,
  `candidate_evidence.knowledge_candidate_id`,
  `candidate_history.knowledge_candidate_id` — confirmed via
  `verify_indexes.sql` against the live schema. Candidate for a future
  migration (V13+).
- **Missing constraints** (self-relationship prevention, duplicate
  relationship prevention, `candidate_relationships` nullable-exclusivity,
  unconstrained `status` columns) — unchanged from `migration_audit.md`
  §9, not addressed here.
- **`setup.sql` naming warning**: Flyway reports "1 SQL migrations were
  detected but not run because they did not follow the filename
  convention" on every command. This is `setup.sql` itself, which lives
  inside `migrations/` but is intentionally not a migration (see
  `DATABASE_BUILD.md`). Harmless — Flyway correctly skips it rather than
  attempting to run it — but noisy. Not fixed here since moving or
  renaming `setup.sql` wasn't part of this work package's scope.
- **`vehicle_objects` discrepancy resolved**: `migration_audit.md`/
  `database_object_matrix.md` (written during AP-005C) documented
  `vehicle_objects` as empty. It is not empty as of this operation (1
  row, matching the seeded Vehicle). The exact point this row was added
  between AP-005C and now wasn't investigated as part of this operation
  — noting the discrepancy here rather than leaving the earlier
  documentation silently wrong. `database_object_matrix.md` should be
  corrected in a future pass.
