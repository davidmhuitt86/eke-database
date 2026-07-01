# Database Object Matrix

Every table defined across `migrations/V1`-`V12`, whether or not it is
currently live (see `migration_audit.md` for live/not-live status — V1-V8
live, V9-V12 not live as of this writing).

---

## object_types

- **Purpose**: reference table — the 12 kinds of Universal Object.
- **Owner**: `eke-database` (schema); read by `eke-service`'s
  `CommitRepository`/COIM entity mapping.
- **Migration**: V2 (created), V3 (seeded, 12 rows).
- **Primary key**: `id` (UUID).
- **Foreign keys**: none (referenced by `universal_objects.object_type_id`).
- **Indexes**: PK index only (no explicit index migration targets this
  table — none needed at current scale; `UNIQUE(name)` auto-indexes name).
- **Constraints**: `UNIQUE(name)`.
- **Lifecycle stage**: reference data supporting the Universal Object
  stage.

## knowledge_domains

- **Purpose**: reference table — engineering domain classification
  (Automotive, Electrical, Mechanical, etc.).
- **Owner**: `eke-database`; read by `eke-service`'s `CommitRepository`
  (domain resolution, currently always "Automotive" — see
  `CommitService`).
- **Migration**: V2 (created), V3 (seeded, 7 rows).
- **Primary key**: `id` (UUID).
- **Foreign keys**: none (referenced by `universal_objects.domain_id`).
- **Indexes**: PK index; `UNIQUE(name)` auto-index.
- **Constraints**: `UNIQUE(name)`.
- **Lifecycle stage**: reference data supporting the Universal Object
  stage.

## object_states

- **Purpose**: reference table — lifecycle state of a Universal Object
  (Captured, Pending, Observed, Reasoned, Validated, Universal Object,
  Published, Deprecated, Archived).
- **Owner**: `eke-database`; read by `eke-service`'s `CommitRepository`
  (state resolution — new commits use `'Universal Object'`).
- **Migration**: V2 (created), V3 (seeded, 9 rows).
- **Primary key**: `id` (UUID).
- **Foreign keys**: none (referenced by `universal_objects.current_state_id`).
- **Indexes**: PK index; `UNIQUE(name)` auto-index.
- **Constraints**: `UNIQUE(name)`.
- **Lifecycle stage**: reference data — notably, its own row values (e.g.
  "Reasoned", "Validated") name several EKL stages that have no other
  schema representation yet (see `engineering_lifecycle_mapping.md`).

## relationship_types

- **Purpose**: reference table — the 8 relationship types current object
  relationships can use.
- **Owner**: `eke-database`; read by `eke-service`'s `CommitRepository`.
- **Migration**: V2 (created), V3 (seeded, 8 rows).
- **Primary key**: `id` (UUID).
- **Foreign keys**: none (referenced by `object_relationships.
  relationship_type_id` and `candidate_relationships.relationship_type_id`).
- **Indexes**: PK index; `UNIQUE(name)` auto-index.
- **Constraints**: `UNIQUE(name)`.
- **Lifecycle stage**: reference data supporting the Universal Object
  stage. Intentionally incomplete relative to the application's
  in-memory relationship vocabulary — see
  `engineering_relationship_ontology.md`.

## universal_objects

- **Purpose**: the core Engineering Object table — every committed
  Vehicle, Component, Connector, Module, Document, Observation, Evidence,
  Measurement, Procedure, etc.
- **Owner**: `eke-database` (schema); written by `eke-service`'s
  `CommitService`/`CommitRepository`; read by `UniversalObjectRepository`
  (COIM resolution) and `CommitRepository`.
- **Migration**: V4 (created), indexed by V6.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `object_type_id` → `object_types.id`; `domain_id` →
  `knowledge_domains.id`; `current_state_id` → `object_states.id`.
- **Indexes**: `idx_universal_objects_name`,
  `idx_universal_objects_object_type`, `idx_universal_objects_domain`,
  `idx_universal_objects_state`, `idx_universal_objects_checksum` (all
  V6), plus the PK index and the `UNIQUE(object_number)` auto-index.
- **Constraints**: `UNIQUE(object_number)`.
- **Lifecycle stage**: **Universal Object** — the only fully-implemented
  EKL stage.

## object_relationships

- **Purpose**: the permanent, committed relationship graph between
  Universal Objects.
- **Owner**: `eke-database` (schema); written by `eke-service`'s
  `CommitRepository.insertObjectRelationship`.
- **Migration**: V5 (created), indexed by V6.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `source_object_id` → `universal_objects.id`;
  `target_object_id` → `universal_objects.id`; `relationship_type_id` →
  `relationship_types.id`.
- **Indexes**: `idx_relationships_source`, `idx_relationships_target`,
  `idx_relationships_type` (all V6), plus the PK index.
- **Constraints**: `CHECK (confidence >= 0 AND confidence <= 100)`. **Gap**
  (documented in `migration_audit.md`): no constraint prevents
  `source_object_id = target_object_id` (self-relationship) or an exact
  duplicate `(source, target, type)` triple.
- **Lifecycle stage**: Universal Object.

## vehicle_objects

- **Purpose**: 1:1 extension of `universal_objects` for the Vehicle type
  — structured year/make/model/trim/VIN/etc.
- **Owner**: `eke-database` (schema); not currently written by
  `eke-service` (no application code creates `vehicle_objects` rows yet).
  **Verified empty**: the one seeded Vehicle-typed `universal_objects` row
  ("2002 Dodge Ram 1500") predates any commit pipeline and has no matching
  `vehicle_objects` extension row (`verify_engineering_objects.sql` §2
  confirms this live) — informational, not an error, but worth knowing
  before assuming VIN/year/make/model data is populated anywhere today.
- **Migration**: V7.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `universal_object_id` → `universal_objects.id`.
- **Indexes**: PK index; `UNIQUE(universal_object_id)` and
  `UNIQUE(vin)` auto-indexes. No explicit index migration targets this
  table (V6 predates V7).
- **Constraints**: `UNIQUE(universal_object_id)`, `UNIQUE(vin)`.
- **Lifecycle stage**: Universal Object (Vehicle extension).

## knowledge_candidates

- **Purpose**: the Workspace-review-stage record of a detected entity
  awaiting or having received an engineer's disposition (Accept/Reject/
  Merge/Rename/Change Type).
- **Owner**: `eke-database` (schema); written by `eke-service`'s
  `CommitRepository.insertKnowledgeCandidate` during commit.
- **Migration**: V8.
- **Primary key**: `id` (UUID).
- **Foreign keys**: none (referenced by all four V9-V12 tables).
- **Indexes**: PK index; `UNIQUE(candidate_number)` auto-index. **Gap**:
  no index on `status` or `observed_name`, the two most likely
  filter/lookup columns for a future review-queue UI.
- **Constraints**: `UNIQUE(candidate_number)`,
  `CHECK (confidence >= 0 AND confidence <= 100)`. **Gap**: `status` is
  unconstrained free-text `VARCHAR(30)` — no `CHECK` restricting it to a
  known set of values.
- **Lifecycle stage**: bridges Observation → Universal Object (the
  Workspace review process). Explicitly **not** the permanent Knowledge
  Evolution history — see `engineering_lifecycle_mapping.md`.

## candidate_observations *(not live)*

- **Purpose**: records the detection context (source text, source type,
  confidence) for a Knowledge Candidate.
- **Owner**: `eke-database` (schema); intended to be written by
  `eke-service`'s `CommitRepository.insertCandidateObservation`
  (implemented in application code, currently unreachable because this
  table doesn't exist live — see `migration_audit.md`).
- **Migration**: V9 *(defined, not applied — malformed filename,
  see `migration_audit.md` §3b)*.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `knowledge_candidate_id` → `knowledge_candidates.id`.
- **Indexes**: PK index only. **Gap**: no index on
  `knowledge_candidate_id` (the FK column).
- **Constraints**: `CHECK (confidence >= 0 AND confidence <= 100)`.
- **Lifecycle stage**: Observation.

## candidate_relationships *(not live)*

- **Purpose**: inferred relationships between a Knowledge Candidate and
  either another candidate or an existing Universal Object, captured
  during the Workspace review process.
- **Owner**: `eke-database` (schema); not currently written by
  `eke-service` (`CommitService` persists to `object_relationships`
  directly for committed relationships — this table is unused by current
  application code even conceptually; see `engineering_object_model.md`).
- **Migration**: V10 *(defined, not applied)*.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `knowledge_candidate_id` → `knowledge_candidates.id`;
  `related_universal_object_id` → `universal_objects.id` (nullable);
  `related_candidate_id` → `knowledge_candidates.id` (nullable);
  `relationship_type_id` → `relationship_types.id`.
- **Indexes**: PK index only. **Gap**: no index on any of the four FK
  columns.
- **Constraints**: `CHECK (confidence >= 0 AND confidence <= 100)`.
  **Gap**: no constraint requiring exactly one of
  `related_universal_object_id`/`related_candidate_id` to be set.
- **Lifecycle stage**: Observation / Evidence (pre-commit relationship
  inference).

## candidate_evidence *(not live)*

- **Purpose**: supporting evidence strings attached to a Knowledge
  Candidate.
- **Owner**: `eke-database` (schema); intended to be written by
  `eke-service`'s `CommitRepository.insertCandidateEvidence` (implemented,
  currently unreachable — table doesn't exist live).
- **Migration**: V11 *(defined, not applied — malformed filename)*.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `knowledge_candidate_id` → `knowledge_candidates.id`.
- **Indexes**: PK index only. **Gap**: no index on
  `knowledge_candidate_id`.
- **Constraints**: `CHECK (confidence >= 0 AND confidence <= 100)`.
- **Lifecycle stage**: Evidence.

## candidate_history *(not live)*

- **Purpose**: records every status transition for a Knowledge Candidate
  (e.g. `UNCLASSIFIED` → `PROMOTED`).
- **Owner**: `eke-database` (schema); not currently written by
  `eke-service` (explicitly not treated as the permanent Knowledge
  Evolution history per architect direction — current `CommitService`
  does not write to this table).
- **Migration**: V12 *(defined, not applied — malformed filename)*.
- **Primary key**: `id` (UUID).
- **Foreign keys**: `knowledge_candidate_id` → `knowledge_candidates.id`.
- **Indexes**: PK index only. **Gap**: no index on
  `knowledge_candidate_id`.
- **Constraints**: none beyond `NOT NULL` on `new_status`. **Gap**: no
  `CHECK` constraining `previous_status`/`new_status` to known values.
- **Lifecycle stage**: Workspace review audit trail — not Knowledge
  Evolution (see `engineering_lifecycle_mapping.md`).
