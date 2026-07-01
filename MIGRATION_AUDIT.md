# EKE Database — Migration Audit

Date: 2026-07-01 (AP-005A), expanded 2026-07-01 (AP-005B)
Scope: `eke-database` only. No live database changes were made to produce
this report; no application code was touched.

> Note on filename: the work package that requested this expanded audit
> asked for `migration_audit.md` (lowercase). This filesystem is
> case-insensitive, so that is the same file as the `MIGRATION_AUDIT.md`
> created for AP-005A — there is only one audit document, expanded here
> rather than duplicated under a second name.

## 1. How this audit was performed

- Read every file under `migrations/`, `tests/`, `verification/`,
  `increments/`.
- Queried the live database's `information_schema`/`pg_catalog` (read-only
  — tables, indexes, constraints, foreign keys, row counts) and checked
  for a `flyway_schema_history` table.
- Compared live schema state, `setup.sql`, `flyway.conf`, and the
  migration files on disk against each other.
- Cross-checked every foreign key in every migration against the table it
  references, and checked every FK column for a supporting index.

## 2. Migration order (canonical sequence)

The version numbers on disk already define the correct order — nothing
needs renumbering:

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

Every migration's foreign keys point only at tables created in an
earlier-numbered migration (verified table-by-table in §7) — the sequence
is internally self-contained and correct. The problems are entirely in
tooling and file naming (§3), not in the ordering or dependency design.

## 3. Repository inconsistencies

### 3a. `flyway.conf` pointed at the wrong directory (fixed in AP-005A)

`flyway.locations` was `filesystem:database/migrations`, a path that
doesn't exist in this repository — migrations live at `migrations/`
(repo root). Corrected to `filesystem:migrations`.

### 3b. Five migration files violate Flyway's naming contract

Flyway's default versioned-migration pattern is
`V<version>__<description>.sql` — capital `V`, exactly two underscores.

| File | Defect |
|---|---|
| `V8_create_knowledge_candidates.sql` | single underscore |
| `V9_create_candidate_observations.sql` | single underscore |
| `V10_create_candidate_relationships.sql` | single underscore |
| `v11_create_candidate_evidence.sql` | lowercase `v`, single underscore |
| `v12_create_candidate_history.sql` | lowercase `v`, single underscore |

Not corrected in either audit — renaming migration files wasn't in either
work package's authorized task list (renumbering is explicitly forbidden;
renaming without renumbering was never explicitly requested either), so
this is flagged as a decision for an explicit follow-up rather than done
unilaterally. **This is the most consequential open item in this repo** —
until these five files are renamed to match Flyway's contract, `flyway
migrate` cannot apply V8-V12 no matter how correct `flyway.conf` is.

### 3c. `setup.sql` was stale and duplicated Flyway's job (fixed in AP-005A)

It manually `\i`-included only V1-V6, and had silently drifted out of sync
with both the migrations directory (which has 12 files) and the live
database (which had 8 tables' worth of migrations applied by some other
means). Replaced with a documentation-only stub that points at
`flyway migrate`/`flyway info` and performs no SQL execution itself.

### 3d. `V1__enable_extensions.sql` file-quality issue

Header comment reads `V1__enapostgresble_extensions.sql` (corrupted copy
of the filename — looks like a careless find/replace inserted "postgres"
into "enable"), and the file has no trailing newline: its last line is
`CREATE EXTENSION IF NOT EXISTS pgcrypto;-- ===...` with the closing
comment banner glued directly onto the SQL statement. Harmless to
execution, but worth a cleanup pass whenever V1 is next touched (V1 is
already applied everywhere, so this is cosmetic only, not urgent).

### 3e. Documentation/scaffolding gaps

- `schema/` — empty (only `.gitkeep`). No ER diagram or data dictionary
  exists anywhere; the migration files are the only source of truth.
- `tests/T001_create_vehicle.sql`, `T002_create_component.sql`,
  `T003_create_relationship.sql`, `T004_verify_graph.sql` — all four
  **empty (0 bytes)**.
- `verification/verify_constraints.sql` (pre-existing, distinct from the
  new `verify_schema.sql`/`verify_reference_data.sql` added in AP-005B) —
  **empty (0 bytes)**.
- `increments/increment-001/{changelog,notes,acceptance}.md` and
  `migrations/increments/increment-00{1,2,3}/` — all empty scaffolding,
  never used.
- No CI configuration anywhere in this repository — the only way any of
  this gets validated today is a human running scripts by hand.

## 4. Live database inconsistencies

Checked 2026-07-01, read-only, against the database `eke-service` connects
to (`localhost:5432/eke`):

- **No `flyway_schema_history` table exists at all.** Flyway has never
  successfully run against this database, ever.
- Tables present: `object_types`, `knowledge_domains`, `object_states`,
  `relationship_types`, `universal_objects`, `object_relationships`,
  `vehicle_objects`, `knowledge_candidates` — the schema produced by
  **V1-V8**, applied by some undocumented manual process (see §3c — even
  `setup.sql` as it existed before AP-005A only covers V1-V6, so V7 and V8
  were applied through at least one additional, unrecorded manual step
  beyond what any file in this repo describes).
- Missing relative to the full migration set: **V9, V10, V11, V12** —
  `candidate_observations`, `candidate_relationships`, `candidate_evidence`,
  `candidate_history` do not exist live. This directly blocked application
  work in `eke-service` (AP-005) that assumed their existence.
- Why V7/V8 exist while `setup.sql` stops at V6 (explicitly asked in
  AP-005B): because whoever brought the database to its current state ran
  more than just `setup.sql` — they applied V7 and V8 by some additional
  manual step (most plausibly `psql -f migrations/V7__....sql` and
  `psql -f migrations/V8_....sql` run directly, given V8's Flyway-invalid
  filename means Flyway could never have applied it either way). No commit,
  script, or document in this repository records that step happening —
  it is untracked history.

## 5. Duplicate objects

None. Every `CREATE TABLE` and `CREATE INDEX` across all twelve migration
files defines a distinct name.

## 6. Missing objects

Relative to the full V1-V12 migration set: `candidate_observations`,
`candidate_relationships`, `candidate_evidence`, `candidate_history`
tables (§4). No table defined by any migration file is missing from the
files themselves — the gap is entirely in what's been applied live, not in
what's been authored.

## 7. Broken references

None. Every foreign key in every migration references a table created in
an earlier-numbered migration:

| Migration | References | Defined in | OK? |
|---|---|---|---|
| V4 `universal_objects` | `object_types`, `knowledge_domains`, `object_states` | V2 | ✅ |
| V5 `object_relationships` | `universal_objects`, `relationship_types` | V4, V2 | ✅ |
| V7 `vehicle_objects` | `universal_objects` | V4 | ✅ |
| V9 `candidate_observations` | `knowledge_candidates` | V8 | ✅ |
| V10 `candidate_relationships` | `knowledge_candidates`, `universal_objects`, `relationship_types` | V8, V4, V2 | ✅ |
| V11 `candidate_evidence` | `knowledge_candidates` | V8 | ✅ |
| V12 `candidate_history` | `knowledge_candidates` | V8 | ✅ |

## 8. Missing indexes

V6 (`create_indexes`) only indexes columns from V4/V5 (`universal_objects`,
`object_relationships`) — it predates V7-V12, and no later migration ever
added indexes for the tables introduced after it. Postgres does not
automatically index foreign key columns (only the referenced/primary-key
side is auto-indexed) — so every FK column below currently has no
supporting index:

- `candidate_observations.knowledge_candidate_id`
- `candidate_relationships.knowledge_candidate_id`,
  `.related_universal_object_id`, `.related_candidate_id`,
  `.relationship_type_id`
- `candidate_evidence.knowledge_candidate_id`
- `candidate_history.knowledge_candidate_id`

(`vehicle_objects.universal_object_id` is fine — its `UNIQUE` constraint
auto-creates a supporting index.)

Also worth noting as a query-pattern gap rather than a correctness bug:
`knowledge_candidates` has no index on `status` or `observed_name`,
both likely lookup/filter columns for any future review-queue UI.

`verification/verify_schema.sql` (added in this work package) includes a
live query that lists exactly which FK columns currently lack a
supporting index, so this can be re-checked mechanically rather than by
re-reading migration files each time.

## 9. Missing constraints

- `object_relationships`: no constraint prevents a self-relationship
  (`source_object_id = target_object_id`), and no `UNIQUE(source_object_id,
  target_object_id, relationship_type_id)` prevents inserting the exact
  same relationship twice.
- `candidate_relationships` (V10): `related_universal_object_id` and
  `related_candidate_id` are both nullable with no `CHECK` requiring
  exactly one to be set — the schema currently allows a relationship row
  pointing at nothing (both null) or ambiguously at both a universal
  object and another candidate simultaneously.
- `universal_objects.version_major`/`version_minor`: no `CHECK (>= 0)` —
  nothing stops a future `UPDATE` from driving these negative.
- `knowledge_candidates.status` and `candidate_history.previous_status`/
  `new_status`: plain `VARCHAR`, no `CHECK` constraining values to a known
  set (e.g. `UNCLASSIFIED`, `PROMOTED`, `REJECTED`, `MERGED`). Currently
  enforced only by application-layer convention, not the database.

None of these are being fixed here — no new migrations are in scope for
this audit — but they're concrete, actionable items for whoever picks up
the schema next.

## 10. Incorrect seed data

None found. `V3__seed_reference_data.sql` seeds each of the four reference
tables exactly once with no duplicate names (and each has a `UNIQUE(name)`
constraint that would reject a duplicate anyway). Two data points worth
flagging as context, not defects:

- `relationship_types` is **intentionally incomplete** for Increment 1
  (confirmed with the architect): `MEASURED_AT`, `OBSERVED_IN`, and other
  richer relationship types used by the application's in-memory COIM
  pipeline are deferred to a future Database Increment.
- `object_types` seeds `'Diagram'` and `'Knowledge Rule'`, neither
  currently referenced by any table or application code — unused, not
  wrong.

`verification/verify_reference_data.sql` (added in this work package)
mechanically checks all four reference tables against the exact expected
name lists above.

## 11. Technical debt (summary)

In priority order:

1. **Five Flyway-invalid filenames (§3b)** — blocks V8-V12 from ever being
   applied via Flyway, the single biggest open risk in this repository.
2. **Live database at V8 with no `flyway_schema_history`** — the database
   `eke-service` depends on cannot currently be reproduced from an empty
   Postgres instance using Flyway alone, which is this repository's
   stated objective. Blocked entirely by item 1 plus needing an actual
   migration run against a fresh database to establish tracking.
3. **Missing FK indexes on V7-V12 tables (§8)** — a performance/scale
   concern, not a correctness one; low urgency until data volumes grow.
4. **Missing constraints (§9)** — data-integrity gaps that currently rely
   on the application layer behaving correctly; moderate priority.
5. **No schema documentation (§3e)** — makes every future audit like this
   one more expensive than it needs to be.
6. **Empty test/verification placeholder files (§3e)** — give a false
   impression of coverage; either delete or fill in.
7. **Untracked manual DB changes (§4)** — at least one manual step applied
   V7 and V8 to the live database with no record of who, when, or how.
   This is a process risk independent of the schema files themselves.

## 12. Recommended corrections

1. Rename the five malformed files to Flyway's naming contract (same
   version numbers, no renumbering) — this needs an explicit go-ahead
   since renaming migration files hasn't been part of either audit work
   package's authorized scope.
2. With `flyway.conf` now correct (§3a) and the naming fixed (item 1),
   run `flyway -configFiles=flyway.conf migrate` against a **fresh,
   non-production** database first, and confirm `flyway_schema_history`
   and both new verification scripts pass cleanly end-to-end.
3. Only after that dry run succeeds, bring the actual live database used
   by `eke-service` up to V12 through Flyway — not manually. This
   directly unblocks the AP-005 commit-persistence work that is currently
   stopped waiting on V9-V12.
4. Add the missing FK indexes (§8) and constraints (§9) via a new,
   properly-numbered migration (V13+) in a future work package — not
   invented here, since this audit's scope forbids new migrations.
5. Fill in `schema/` with real documentation once the live database is
   Flyway-verified.
6. Delete or fill in the empty `tests/T00*.sql` and
   `verification/verify_constraints.sql` placeholders.
