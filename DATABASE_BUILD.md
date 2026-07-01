# EKE Database — Build & Developer Workflow

This is the canonical process for creating an Engineering Knowledge Engine
database from nothing. Flyway is the **only** supported way to apply
schema — do not run migration files by hand and do not add manual
`\i` includes back to `setup.sql` (see `migration_audit.md` for why that
went wrong before).

## 1. Prerequisites

- PostgreSQL (any recent version; `pgcrypto` extension must be
  installable — it is on standard PostgreSQL installs).
- [Flyway CLI](https://flywaydb.org/documentation/usage/commandline/) on
  your `PATH`. Verify with:
  ```
  flyway -v
  ```
- Network access to the target Postgres instance.

## 2. Create an empty database

```sql
CREATE DATABASE eke;
```

Nothing else — no extensions, no tables. Flyway (via `V1__enable_extensions.sql`)
creates the `pgcrypto` extension used for UUID generation.

## 3. Configure Flyway

`flyway.conf` (repo root) already points at this repository's canonical
migration directory and target database:

```
flyway.url=jdbc:postgresql://localhost:5432/eke
flyway.user=postgres
flyway.password=1776
flyway.locations=filesystem:migrations
```

Adjust `flyway.url`/`flyway.user`/`flyway.password` for your environment
(a local override file or environment-specific `-configFiles` argument is
preferable to editing this file directly if your credentials differ).

## 4. Run the migrations

From the repository root:

```
flyway -configFiles=flyway.conf migrate
```

This applies every migration in `migrations/` in version order (V1
through V12) and creates Flyway's own `flyway_schema_history` tracking
table. On a truly empty database this is the entire build process — no
other scripts need to run first or after.

To see what Flyway will do / has done without applying anything:

```
flyway -configFiles=flyway.conf info
```

`migrations/setup.sql` documents this same command for anyone who lands
there out of habit from the old manual-include workflow — it no longer
applies any SQL itself.

## 5. Validate the result

Two read-only verification scripts live in `verification/`:

```
psql -f verification/verify_schema.sql eke
psql -f verification/verify_reference_data.sql eke
```

- `verify_schema.sql` — confirms all 12 tables, all indexes, every
  constraint (PK/UNIQUE/CHECK), and every foreign key exist, plus flags
  any FK column that has no supporting index (a known, documented gap —
  see `migration_audit.md`).
- `verify_reference_data.sql` — confirms `object_types`,
  `knowledge_domains`, `object_states`, and `relationship_types` contain
  exactly the rows seeded by `V3__seed_reference_data.sql`, no more and no
  fewer. Every result set should be empty on a correctly-migrated
  database.

Both scripts are pure `SELECT` statements — safe to run against any
environment, including production, at any time.

## 6. Developer workflow for adding new schema

1. Add a new file `migrations/V<next>__<description>.sql` — **exactly**
   two underscores after the version number, capital `V`. Flyway silently
   ignores or rejects anything else (this is exactly what happened to
   V8-V12 historically; see `migration_audit.md`).
2. Never edit an already-applied migration file. Flyway checksums each
   migration on first apply and will refuse to run if a previously-applied
   file's content changes underneath it.
3. Run `flyway -configFiles=flyway.conf migrate` against your local/dev
   database and confirm both verification scripts still pass.
4. Do not hand-apply the new file to any shared database — let Flyway do
   it, so `flyway_schema_history` stays the source of truth for what's
   actually been applied where.

## 7. What NOT to do

- Don't run `psql -f migrations/V4__create_universal_objects.sql` (or any
  single migration file) directly against a database Flyway is expected to
  manage — this creates exactly the drift documented in
  `migration_audit.md`, where a database can end up with tables Flyway
  itself doesn't know about (no `flyway_schema_history` row for them).
- Don't add manual `\i` includes to `setup.sql`.
- Don't renumber or rename an already-applied migration.
