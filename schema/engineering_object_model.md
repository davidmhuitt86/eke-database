# Engineering Object Model

Documents every Engineering Object type currently represented in the
schema. "Represented" means one of two things:

- **First-class table** — has its own table (`universal_objects`,
  `vehicle_objects`, `knowledge_candidates`).
- **Typed row** — exists as a row in `universal_objects`, distinguished by
  `object_type_id` pointing at one of the 12 `object_types` seeded in
  `V3__seed_reference_data.sql`. Most Engineering Object concepts in this
  schema are typed rows, not dedicated tables — there is deliberately one
  general-purpose object table, not one table per concept.

Current implementation status uses these labels:
- **Live** — table/rows exist in the current live database (V1-V8 applied).
- **Defined, not live** — migration exists on disk (V9-V12) but is not yet
  applied to the live database (see `migration_audit.md`).
- **Type only** — the `object_types` row is seeded but no application code
  currently creates objects of this type.

---

## Universal Object (the base concept)

- **Purpose**: the single general-purpose engineering entity table. Every
  Vehicle, Component, Connector, Module, Document, Observation, Evidence,
  Measurement, Procedure, etc. is a row here, distinguished by
  `object_type_id`.
- **Owning table**: `universal_objects` (V4).
- **Relationships**: source or target of `object_relationships` (V5);
  optionally extended by `vehicle_objects` (V7) for the Vehicle type.
- **Current implementation status**: Live. This is the only stage of the
  Engineering Knowledge Lifecycle (EKL) implemented so far — see
  `engineering_lifecycle_mapping.md`.
- **Future planned expansion**: dedicated extension tables analogous to
  `vehicle_objects` for other types where type-specific structured fields
  become necessary (e.g. a `component_objects` table with
  part-family-specific columns), following the same pattern: one row in
  `universal_objects` plus one 1:1 extension row.

---

## Vehicle

- **Purpose**: a complete vehicle (the root subject most workspace
  sessions are organized around).
- **Owning table**: `universal_objects` row (`object_type_id` = Vehicle)
  extended 1:1 by `vehicle_objects` (year/make/model/trim/VIN/etc.).
- **Relationships**: typically the `PART_OF` target for Components,
  Modules, Connectors installed on it (application-layer convention from
  the COIM pipeline — not schema-enforced).
- **Current implementation status**: Live. The only object type with a
  dedicated extension table today.
- **Future planned expansion**: none currently planned beyond what
  `vehicle_objects` already covers.

## Component

- **Purpose**: generic mechanical/electrical part not covered by a more
  specific type (pumps, regulators, brackets, gaskets, filters, valves,
  and — by current application-layer convention — also Engine,
  Transmission, Fuse, Relay, Sensor, Switch, Ground, Battery, Power
  Source, and Part Numbers, none of which have their own `object_types`
  row; see "Entity-type mapping" note below).
- **Owning table**: `universal_objects` row (`object_type_id` = Component).
- **Relationships**: `PART_OF` a Vehicle or another Component;
  `CONNECTED_TO` other components.
- **Current implementation status**: Live.
- **Future planned expansion**: splitting the current catch-all mapping
  into their own `object_types` rows (Engine, Sensor, etc.) is a
  candidate for Database Increment 002, once the ontology work referenced
  in `engineering_relationship_ontology.md` is underway — not proposed
  here, just noted as a natural next step.

## Connector

- **Purpose**: electrical connector (e.g. "C104").
- **Owning table**: `universal_objects` row (`object_type_id` = Connector).
- **Relationships**: `CONNECTED_TO` a Module or another Connector;
  `PART_OF` a Vehicle.
- **Current implementation status**: Live.
- **Future planned expansion**: none currently planned.

## Wire

- **Purpose**: electrical conductor.
- **Owning table**: `universal_objects` row (`object_type_id` = Wire).
- **Relationships**: `CONNECTED_TO` Connectors/Modules; `PART_OF` a
  Vehicle.
- **Current implementation status**: Live (type seeded); no application
  code currently creates Wire objects (COIM's `WireDetector`-equivalent
  keyword bucket maps to this type but the commit pipeline that would
  actually create rows is blocked — see `migration_audit.md` §4).
- **Future planned expansion**: none currently planned beyond normal use.

## Module

- **Purpose**: electronic control module (PCM, ECM, BCM, TCM, etc.).
- **Owning table**: `universal_objects` row (`object_type_id` = Module).
- **Relationships**: `PART_OF` a Vehicle; `CONNECTED_TO` Connectors.
- **Current implementation status**: Live.
- **Future planned expansion**: none currently planned.

## Document

- **Purpose**: an imported engineering document (service manual, wiring
  diagram source, bulletin).
- **Owning table**: `universal_objects` row (`object_type_id` = Document).
- **Relationships**: `REFERENCES` other objects; `USES`/`VALIDATES` by
  other objects that cite it.
- **Current implementation status**: Type only. Detected by COIM
  (`Document` entity type) but not yet committed as objects (blocked on
  V9-V12 per `migration_audit.md`).
- **Future planned expansion**: structured document metadata (source
  file, page/section reference) likely needs its own extension table,
  analogous to `vehicle_objects`.

## Diagram

- **Purpose**: engineering diagram.
- **Owning table**: `universal_objects` row (`object_type_id` = Diagram).
- **Relationships**: same pattern as Document.
- **Current implementation status**: Type only — seeded, never referenced
  by any table or application code. No detector currently produces this
  type (COIM has no diagram-detection logic).
- **Future planned expansion**: undecided; flagged in
  `migration_audit.md` as currently-unused reference data.

## Observation

- **Purpose**: an observed engineering fact captured from raw text (e.g.
  "Customer states truck cranks but will not start.") or a Diagnostic
  Trouble Code, which the application layer treats as an observed
  diagnostic fact.
- **Owning table**: `universal_objects` row (`object_type_id` =
  Observation). Also has a dedicated *candidate-stage* table,
  `candidate_observations` (V9, not yet live) — see note below.
- **Relationships**: `REFERENCES`/`OBSERVED_IN` (workspace-only, not
  persisted — see `engineering_relationship_ontology.md`) a Vehicle.
- **Current implementation status**: Type only for the committed
  (Universal Object) form. The *pre-commit* form,
  `candidate_observations`, is defined but not live.
- **Future planned expansion**: see `engineering_lifecycle_mapping.md` —
  Observation is also a named EKL stage, not just an object type; the two
  concepts (Observation-the-object-type and Observation-the-lifecycle-
  stage) are related but distinct, and only the object-type side has any
  schema today.

## Evidence

- **Purpose**: supporting evidence for a candidate or committed object.
- **Owning table**: `universal_objects` row (`object_type_id` = Evidence)
  for committed evidence; `candidate_evidence` (V11, not yet live) for
  pre-commit evidence attached to a `knowledge_candidates` row.
- **Relationships**: `VALIDATES` the object it supports.
- **Current implementation status**: Type only / Defined, not live.
- **Future planned expansion**: none beyond bringing V11 live.

## Measurement

- **Purpose**: a recorded engineering measurement (e.g. "12.48 V",
  "40 PSI").
- **Owning table**: `universal_objects` row (`object_type_id` =
  Measurement).
- **Relationships**: `MEASURED_AT` its subject (workspace-only today —
  not a seeded relationship type; see
  `engineering_relationship_ontology.md`).
- **Current implementation status**: Type only. COIM detects measurements
  deterministically today; committing them as objects is blocked on
  V9-V12.
- **Future planned expansion**: a `measurement_objects` extension table
  (structured `value`/`unit` columns instead of free-text `description`)
  is a reasonable Increment 002 candidate.

## Procedure

- **Purpose**: an engineering procedure (inspect/replace/torque/etc.
  statements).
- **Owning table**: `universal_objects` row (`object_type_id` =
  Procedure).
- **Current implementation status**: Type only.
- **Future planned expansion**: none currently planned.

## Knowledge Rule

- **Purpose**: a validated engineering knowledge rule (the eventual output
  of the Reasoning/Validation EKL stages).
- **Owning table**: `universal_objects` row (`object_type_id` = Knowledge
  Rule).
- **Current implementation status**: Type only — seeded, unused. No
  detector or pipeline stage currently produces this type; Reasoning and
  Validation are unimplemented EKL stages (see
  `engineering_lifecycle_mapping.md`).
- **Future planned expansion**: this type is the natural home for
  whatever the future Reasoning/Validation subsystem produces.

## Knowledge Candidate (pre-commit staging concept)

- **Purpose**: a not-yet-approved engineering entity awaiting engineer
  review, as distinct from a committed Universal Object.
- **Owning table**: `knowledge_candidates` (V8, live) plus its four
  satellite tables — `candidate_observations` (V9), `candidate_
  relationships` (V10), `candidate_evidence` (V11), `candidate_history`
  (V12) — none of which are live yet.
- **Relationships**: `candidate_relationships` can point at either another
  candidate or an existing Universal Object.
- **Current implementation status**: Live for the base table only; the
  full candidate audit trail (observations/evidence/relationships/history)
  is defined but not live.
- **Future planned expansion**: this table family is explicitly scoped as
  a *temporary Workspace analysis artifact*, not the permanent Knowledge
  Evolution history (per architect direction during AP-005) — a separate,
  first-class Knowledge Evolution subsystem is planned for a future work
  package and will not repurpose these tables.
