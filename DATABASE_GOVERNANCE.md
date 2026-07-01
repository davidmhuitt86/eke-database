# EKE Database Governance

This document establishes the long-term rules for how this database's
schema and reference data are managed. It exists because every problem
found during the AP-005A/B/C audits — the missing V9-V12 tables, the
untracked manual application of V7/V8, `setup.sql` silently drifting out
of sync — traces back to there having been no written policy. See
`migration_audit.md` for the full incident history this policy is
responding to.

## 1. Migration policy

- **Flyway is the only supported mechanism for changing schema.** No
  exceptions, including "just this once" manual `psql -f` runs against a
  shared database. See `DATABASE_BUILD.md` for the actual commands.
- **Every schema change is a new, sequentially-numbered migration file**
  named exactly `V<next-integer>__<description>.sql` — capital `V`,
  exactly two underscores. Flyway silently fails to recognize anything
  else (this is precisely how V8-V12 ended up unusable).
- **Migrations are immutable once applied anywhere.** Flyway checksums
  each applied migration; editing a file after it's been applied to any
  shared environment breaks that environment's ability to migrate further.
  If a mistake ships, fix it forward with a new migration, don't edit
  history.
- **No renumbering, ever.** A migration's version number is permanent
  from the moment it's committed, whether or not it's been applied
  anywhere yet.
- **No skipping the sequence.** Every migration must be self-contained
  and depend only on migrations with a lower version number (verified for
  V1-V12 in `migration_audit.md` §7 — this is the standard to maintain
  going forward).

## 2. Reference data policy

- Reference tables (`object_types`, `knowledge_domains`, `object_states`,
  `relationship_types`) are seeded exclusively through versioned
  migrations (`V3__seed_reference_data.sql` today), never through ad hoc
  `INSERT` statements run by hand or by application code at runtime.
- Adding a new reference value (a new object type, a new relationship
  type, etc.) is a schema change and requires a new migration — see
  `engineering_relationship_ontology.md` for the specific relationship
  types already identified as deferred to Database Increment 002.
- Application code must resolve reference data **by name**, never by
  hardcoded UUID (already the pattern `eke-service`'s `CommitRepository`
  follows — `resolveObjectTypeId(name)`, `resolveDomainId(name)`, etc.).
  This is what makes reference data safely re-seedable/reviewable without
  coordinating UUIDs across environments.

## 3. Schema modification policy

- Every new table needs, in the same migration or an immediately
  following one: a primary key, foreign key constraints for every
  relationship, indexes on every foreign key column, and `CHECK`
  constraints for every value with a known valid range or set (see
  `migration_audit.md` §8-§9 for the current backlog of tables that
  predate this expectation).
- Schema changes affecting a table application code already writes to
  require the corresponding repository/service code to be updated in the
  same change set where practical — but this repository (`eke-database`)
  never depends on application repositories; the coordination is a
  process expectation, not a technical one.
- No migration may be added to make a specific work package's application
  code "just work" if it doesn't match this repository's actual reviewed
  schema design — see `BASELINE_PLAN.md`'s risk assessment for what
  happens when that discipline slips (this is exactly how AP-005 got
  blocked).

## 4. Developer responsibilities

- Before writing a new migration, read `schema/database_object_matrix.md`
  and `schema/engineering_object_model.md` to check whether the concept
  you need already has a home.
- Run both verification scripts most relevant to your change (`verify_
  schema.sql` + `verify_indexes.sql` for structural changes;
  `verify_reference_data.sql` for seed data changes; `verify_
  relationship_integrity.sql` / `verify_engineering_objects.sql` for
  anything touching `object_relationships` or `universal_objects`)
  against your local database before proposing a change.
- Never apply a migration file directly to a database other people share.
  If you're not sure whether a database is "yours," treat it as shared.
- If you discover the live database doesn't match what Flyway believes
  is applied (no `flyway_schema_history` row for a table that exists, or
  vice versa), stop and report it — don't try to reconcile it by hand.
  This is exactly the failure mode `migration_audit.md` documents.

## 5. Release process

1. Author the migration file(s) following the naming/immutability rules
   above.
2. Run `flyway -configFiles=flyway.conf migrate` against a disposable
   local/dev database created fresh for this purpose.
3. Run all five verification scripts in `verification/` against that
   database; all should report zero problems (aside from any explicitly
   documented, known-and-accepted gaps).
4. Get the migration reviewed like any other code change.
5. Apply to shared/staging environments via `flyway migrate` only —
   never manually. Confirm `flyway_schema_history` reflects the new
   version.
6. Only after staging is verified, apply to production the same way.

## 6. Database versioning strategy

- The Flyway version number (`V1`, `V2`, ... `V12`, ...) *is* the
  database's version — there is no separate semantic-version scheme
  layered on top.
- "Increments" (`increment-001`, `increment-002`, ...) as referenced in
  this repository's `increments/` folder and by the architect (e.g.
  "Database Increment 002" for the expanded relationship ontology) are a
  coarser grouping label for a batch of related migrations delivered
  together — they are documentation/planning groupings, not a competing
  version number. A given increment corresponds to a contiguous range of
  Flyway versions once it ships.
- `flyway_schema_history` is the single source of truth for "what version
  is this database actually at" — not `setup.sql`, not a README, not
  institutional memory. Every environment's state should be answerable by
  running `flyway info` against it.
