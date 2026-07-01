# EKE Database — Migration Audit (AP-005A)

Date: 2026-07-01
Scope: `eke-database` only. No live database changes were made to produce this report.

## 1. How this audit was performed

- Read every file under `migrations/`, `tests/`, `verification/`, `increments/`.
- Queried the live database's `information_schema.tables` and checked for a
  `flyway_schema_history` table (read-only queries only, no writes).
- Compared live schema state, `setup.sql`, `flyway.conf`, and the migration
  files on disk against each other.

## 2. Live database state (as observed, read-only)

Tables present: `object_types`, `knowledge_domains`, `object_states`,
`relationship_types`, `universal_objects`, `object_relationships`,
`vehicle_objects`, `knowledge_candidates` — i.e. the schema produced by
**V1–V8**.

**No `flyway_schema_history` table exists.** This database was never
successfully migrated by Flyway — not once. Every table in it was created
by some other means (most likely a manual `psql` run of `setup.sql` plus at
least two more manual steps, since `setup.sql` itself only covers V1–V6;
see §5).

## 3. Root cause: two independent reasons Flyway has never worked here

### 3a. `flyway.conf` points at the wrong directory

```
flyway.locations=filesystem:database/migrations
```

The migrations actually live at `migrations/` (repo root), not
`database/migrations/`. Pointed at the configured path, Flyway finds
**zero** migration files — not even the correctly-named V1–V7. This alone
would make `flyway migrate` a no-op against this location.

### 3b. Five migration files don't match Flyway's naming contract

Flyway's default versioned-migration filename pattern is
`V<version>__<description>.sql` — capital `V` prefix, exactly **two**
underscores after the version. Five files violate this:

| File | Defect |
|---|---|
| `V8_create_knowledge_candidates.sql` | single underscore (needs `V8__`) |
| `V9_create_candidate_observations.sql` | single underscore (needs `V9__`) |
| `V10_create_candidate_relationships.sql` | single underscore (needs `V10__`) |
| `v11_create_candidate_evidence.sql` | lowercase `v` **and** single underscore |
| `v12_create_candidate_history.sql` | lowercase `v` **and** single underscore |

With default settings, Flyway would either fail to recognize these files as
migrations at all (silently skipped) or reject the whole migration run
depending on configuration — either way, V8 through V12 could never have
been successfully applied via `flyway migrate`, even if `flyway.locations`
were fixed. **This is almost certainly why V9–V12 are missing live and why
V8 (`knowledge_candidates`) exists live despite being misnamed** — it was
evidently created by hand, not by Flyway, same as V7.

Combined with §3a, the practical history appears to be: Flyway has never
run successfully against this database at any point. Everything live today
was applied manually, outside the tool that's supposed to be the source of
truth.

## 4. Missing migrations (relative to what's on disk)

V9, V10, V11, V12 — `candidate_observations`, `candidate_relationships`,
`candidate_evidence`, `candidate_history`. Confirmed missing live via direct
`information_schema.tables` query on 2026-07-01.

## 5. `setup.sql` is stale and self-contradicting

Current content only includes V1 through V6:

```sql
\i migrations/V1__enable_extensions.sql
\i migrations/V2__create_reference_tables.sql
\i migrations/V3__seed_reference_data.sql
\i migrations/V4__create_universal_objects.sql
\i migrations/V5__create_object_relationships.sql
\i migrations/V6__create_indexes.sql
```

It doesn't even reference V7 or V8 — both of which exist live. Whoever
brought the live database to its current V1–V8 state did not do so by
running this file as written; they ran it plus at least two undocumented
manual steps. `setup.sql` has been silently drifting out of sync with
reality, and it duplicates Flyway's job (a version-tracked migration
runner) using an untracked, hand-maintained include list — the exact
failure mode that produced the current inconsistency. Per the work
package, this file is being replaced with a documentation-only bootstrap
stub (see `setup.sql` in this commit) rather than an executable include
list.

## 6. Duplicate schema

None found. Every `CREATE TABLE` and `CREATE INDEX` across all twelve
migration files defines a distinct name — no table or index is created
twice. (Checked via direct grep across all `.sql` files in `migrations/`.)

## 7. Inconsistent seed data

- No internal inconsistency in the seeded rows themselves (`V3`) — object
  types, domains, states, and relationship types are each seeded exactly
  once, with no duplicate names (all four reference tables have a
  `UNIQUE(name)` constraint that would reject a duplicate anyway).
- `relationship_types` is **intentionally incomplete** for Increment 1
  (confirmed with the architect during AP-005): it covers `PART_OF`,
  `CONNECTED_TO`, `CAUSES`, `USES`, `REFERENCES`, `DERIVED_FROM`,
  `VALIDATES`, `CONTAINS`, but not the richer relationship vocabulary the
  application layer's COIM pipeline can produce in-memory (`MEASURED_AT`,
  `OBSERVED_IN`, etc.). This isn't a defect in this migration set — it's
  explicitly deferred to a future Database Increment per the architect —
  but it's worth recording here since it constrains what the application
  can persist today.
- `object_types` seeds `'Diagram'` and `'Knowledge Rule'`, neither of which
  is referenced by any table, application code, or seed row currently.
  Not a bug, just currently-unused reference data — flagging so it isn't
  mistaken for dead/erroneous data later.

## 8. Undocumented tables

`schema/` exists as an empty directory (only a `.gitkeep`) — there is no
schema documentation (ER diagram, data dictionary, etc.) anywhere in this
repository. The migration files themselves are the only source of truth
for the schema shape. This is a documentation gap, not a schema defect,
but it's the reason an audit like this one has to be done by reading raw
SQL rather than a maintained reference.

## 9. Orphaned migrations / dead scaffolding

- `tests/T001_create_vehicle.sql`, `T002_create_component.sql`,
  `T003_create_relationship.sql`, `T004_verify_graph.sql` — **all four
  files are empty (0 bytes)**. They exist as placeholders only; nothing
  runs them, and there's nothing in them to run.
- `verification/verify_constraints.sql` — **empty (0 bytes)**, same
  situation.
- `verification/verify_increment_1.sql` — the one verification file with
  real content (a set of `SELECT` sanity queries). Not wired into any
  automated process (no CI config found in this repo) — it's a manual
  runbook, not an orphaned file, but worth noting it's the only
  verification asset that actually does anything.
- `migrations/increments/increment-001/`, `increment-002/`,
  `increment-003/` and `increments/increment-001/{changelog,notes,
  acceptance}.md` — all empty. Scaffolding for a documentation process
  that was never used.

## 10. Dependency problems

None found in the migration *sequence itself*. Checked every foreign key
across all twelve files against the version each referenced table is
created in:

| Migration | References | Defined in | OK? |
|---|---|---|---|
| V4 `universal_objects` | `object_types`, `knowledge_domains`, `object_states` | V2 | ✅ |
| V5 `object_relationships` | `universal_objects`, `relationship_types` | V4, V2 | ✅ |
| V7 `vehicle_objects` | `universal_objects` | V4 | ✅ |
| V9 `candidate_observations` | `knowledge_candidates` | V8 | ✅ |
| V10 `candidate_relationships` | `knowledge_candidates`, `universal_objects`, `relationship_types` | V8, V4, V2 | ✅ |
| V11 `candidate_evidence` | `knowledge_candidates` | V8 | ✅ |
| V12 `candidate_history` | `knowledge_candidates` | V8 | ✅ |

If the naming defects in §3b are corrected, the version ordering V1→V12 is
internally consistent and self-contained — every migration's foreign keys
point at tables created in an earlier-numbered migration. **The dependency
graph is sound; only the filenames and the Flyway config are broken.**

## 11. Minor file-quality issues

- `V1__enable_extensions.sql`: the header comment inside the file reads
  `V1__enapostgresble_extensions.sql` (a corrupted copy of the filename,
  apparently from a careless find/replace inserting "postgres" into
  "enable"), and the file has no trailing newline — its last line is
  `CREATE EXTENSION IF NOT EXISTS pgcrypto;-- ===...` with the closing
  comment banner glued directly onto the SQL statement with no line break.
  Harmless to execution (still parses as a statement followed by a
  comment), but it's a sign this file was hand-edited carelessly and is
  worth cleaning up when V1 is next touched.

## 12. Recommended migration sequence

The correct, complete apply order — unchanged from the version numbers
already on disk (no renumbering) — is:

```
V1  enable_extensions
V2  create_reference_tables
V3  seed_reference_data
V4  create_universal_objects
V5  create_object_relationships
V6  create_indexes
V7  create_vehicle_objects
V8  create_knowledge_candidates
V9  create_candidate_observations
V10 create_candidate_relationships
V11 create_candidate_evidence
V12 create_candidate_history
```

This is what's already implied by the version numbers themselves — the
sequence was never actually wrong, it just has never been reachable by
Flyway (§3) and `setup.sql` never caught up past V6 (§5).

## 13. Recommended next steps (not performed in this work package)

1. Fix the five malformed filenames (§3b) so Flyway can discover them —
   rename only, same version numbers, no renumbering. Not done in this
   audit since renaming migration files wasn't in this work package's
   deliverable list; flagging for an explicit follow-up decision.
2. Apply the corrected `flyway.conf` (this commit) and run `flyway migrate`
   against a **non-production** database first to confirm V1–V12 apply
   cleanly end-to-end with a real `flyway_schema_history` table, before
   touching the shared live database.
3. Only after that dry run succeeds, bring the live database used by
   `eke-service` up to V12 through Flyway (not manually) — this is what
   was blocking AP-005's commit-persistence work.
4. Fill in `schema/` with real documentation once the schema is
   Flyway-verified, so future audits don't require re-reading raw SQL.
5. Either delete the empty `tests/T00*.sql` and
   `verification/verify_constraints.sql` placeholders or write real
   content for them — as it stands they give a false impression of test
   coverage that doesn't exist.
