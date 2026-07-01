# Flyway Baseline Plan

**This document is a recommendation only. No commands in this file have
been run. No migration files have been renamed. No live database has been
touched to produce this plan** — it is written entirely from the read-only
findings in `migration_audit.md`.

## 1. The situation this plan responds to

- The live database (`eke` @ `localhost:5432`, per `flyway.conf`) has the
  schema produced by V1-V8, applied by an undocumented manual process —
  never through Flyway. It has no `flyway_schema_history` table.
- V9-V12 exist as files on disk but were never applied anywhere, live or
  otherwise, and currently cannot be applied by Flyway due to five
  malformed filenames (`migration_audit.md` §3b).
- `flyway.conf`'s `flyway.locations` was pointed at a nonexistent
  directory until AP-005A corrected it.

Two separate problems need two separate treatments: getting the
**existing** database under Flyway management (baselining), and getting
**new** databases (dev, CI, future environments) built correctly from
scratch (standard migration).

## 2. Recommended Flyway baseline version

**V8**, applied specifically to the one existing live database that
already has the V1-V8 schema.

Rationale: `flyway baseline` tells Flyway "trust that everything up to
and including this version is already correctly applied here — start
tracking from this point without re-running that SQL." That's exactly
this database's actual state: V1-V8's tables genuinely exist and (per
`verify_reference_data.sql`, already run read-only against it) match the
expected seed data exactly. Baselining at V8 is truthful; baselining at
any other version would either re-attempt SQL that's already applied
(V1-V7, which would error on `CREATE TABLE` collisions) or claim
migrations are applied that aren't (anything above V8).

This baseline recommendation applies **only** to this one already-existing
database. It does not apply to any newly-created database — see §4.

## 3. Migration strategy going forward

1. Fix the five malformed filenames first (§7, risk-assessed below) — a
   baseline at V8 is useless if Flyway still can't parse V9-V12
   afterward.
2. Baseline the existing live database at V8 (§5).
3. From that point forward, every environment's state is exactly what
   `flyway_schema_history` says it is — no more manual `psql -f` runs,
   per `DATABASE_GOVERNANCE.md`.
4. `flyway migrate` against the now-baselined live database applies V9
   through V12 (assuming step 1 is done first), bringing it fully current.
5. All future schema changes are new migrations (V13+) following the
   policy in `DATABASE_GOVERNANCE.md` — never manual, never renumbered.

## 4. Developer migration procedure (new/local databases)

For any database that does **not** already have V1-V8 applied (a fresh
local dev database, a CI database, a new environment):

1. `CREATE DATABASE eke;` — completely empty, no baseline needed.
2. `flyway -configFiles=flyway.conf migrate` — applies V1 through V12 in
   full, in order, and creates `flyway_schema_history` naturally as it
   goes.
3. Run all five scripts in `verification/` and confirm expected results
   (`DATABASE_BUILD.md` documents this end-to-end).

No baselining is involved here at all — baselining is specifically for
reconciling a database that already has un-tracked schema, which a fresh
database by definition does not.

## 5. Existing database conversion procedure (recommendation, not performed)

For the one live database currently at the untracked V1-V8 state:

1. **Back up first.** `pg_dump` the live database before anything else in
   this procedure, regardless of how low-risk the current data volume is
   (2 `universal_objects` rows as of this writing, but the procedure
   should be identical regardless of size — get in the habit now).
2. Fix the five malformed migration filenames (§7).
3. Dry-run against a **copy** of the live database (restored from the
   backup in step 1, not the live one) — run
   `flyway -configFiles=flyway.conf baseline -baselineVersion=8`, then
   `flyway -configFiles=flyway.conf migrate`, then all five verification
   scripts. Confirm V9-V12 apply cleanly and every verification script
   passes.
4. Only after step 3 succeeds on the copy, run the same two Flyway
   commands against the actual live database.
5. Re-run all five verification scripts against the live database as
   final confirmation.

Every step above is a recommendation for a future work package to
execute — none of it has been run as part of producing this plan.

## 6. Risk assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Renaming V8-V12 breaks something that already depends on the exact current filenames | Low | Low | Nothing outside this repository references migration filenames directly (checked: `eke-service` reads table/column names, never migration filenames). Application code is unaffected by a rename. |
| `flyway baseline -baselineVersion=8` run against the wrong database (e.g. accidentally the live DB before a dry run) | Low if the dry-run step is followed; Medium if skipped | Medium — baseline itself doesn't modify data, but it changes what Flyway believes it can safely do next | Always dry-run against a restored copy first (§5 step 3), never the live database directly |
| V9-V12 fail to apply cleanly once naming is fixed (undiscovered issue in migrations that were never actually tested end-to-end) | Medium — these files have literally never been executed by anything, ever | Medium — a failed `flyway migrate` mid-run leaves the target database in a partially-migrated state for that one migration (Flyway wraps each migration in its own transaction by default for Postgres, so a failure rolls back *that* migration, not earlier ones — but this should still be verified, not assumed) | The dry-run against a restored copy (§5 step 3) is designed to catch exactly this before it ever touches the live database |
| Someone re-introduces a manual `psql -f` habit after baselining | Medium — this is exactly what caused the current situation | High — silently re-creates drift between `flyway_schema_history` and reality | `DATABASE_GOVERNANCE.md` §1 and §4 codify this as policy; enforcement is a team-process matter, not something this repository's files can technically prevent |
| New reference data or relationship types get added outside a migration (e.g. an ad hoc `INSERT` to unblock a deadline) | Medium | Medium — reference data drift is exactly as hard to audit as the schema drift documented in `migration_audit.md` | `DATABASE_GOVERNANCE.md` §2 codifies reference data as migration-only |

## 7. Renaming the five malformed files — scope note

This plan recommends renaming `V8_create_knowledge_candidates.sql`,
`V9_create_candidate_observations.sql`,
`V10_create_candidate_relationships.sql`,
`v11_create_candidate_evidence.sql`, and
`v12_create_candidate_history.sql` to the correct `V<n>__<description>.sql`
form (same version numbers — this is a rename, not a renumbering, and
doesn't create new migrations or modify their SQL content). This has been
flagged as a recommendation in every audit so far
(`migration_audit.md` §12 item 1) but has not been authorized as an action
in any work package to date, including this one — this section restates
it here because it is the single blocking prerequisite for the rest of
this baseline plan, not because it's being performed now.

## 8. Rollback strategy

- **Baselining is reversible in principle** — `flyway_schema_history` is
  just a table; if a baseline is applied incorrectly, the row(s) it added
  can be corrected or the table dropped and the process restarted,
  **provided no `migrate` has run since** that would have assumed the
  incorrect baseline was correct.
- **Once `migrate` has applied V9-V12 on top of an incorrect baseline**,
  rollback means restoring from the pre-baseline backup taken in §5 step 1
  — Flyway (open-source/community edition, which is what's configured
  here) does not support automated `undo` migrations. This is why §5's
  procedure insists on a dry run against a restored copy before touching
  the live database at all: the actual rollback strategy for the live
  database is "don't apply anything to it that hasn't already been proven
  safe against a copy."
- If a specific migration (V9-V12) is found to be broken only after
  reaching the live database despite the dry run, the correct response
  per `DATABASE_GOVERNANCE.md` §1 is a new forward-fixing migration
  (V13+), not editing or reverting the broken one in place — unless the
  live database's backup is restored first, in which case the "broken"
  migration can still be corrected before it's ever been applied anywhere,
  same as any other migration that hasn't shipped yet.
