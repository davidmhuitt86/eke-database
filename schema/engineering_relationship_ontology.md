# Engineering Relationship Ontology

Documents every relationship type currently supported by the schema
(seeded in `V3__seed_reference_data.sql`, table `relationship_types`),
plus the relationship vocabulary the application layer already uses
in-memory that the schema does not yet support.

## Currently supported (seeded in `relationship_types`)

### PART_OF

- **Definition**: the source object is a physical or logical part of the
  target object (e.g. a Connector is `PART_OF` a Vehicle).
- **Direction**: source → target (asymmetric).
- **Inverse**: `HAS_PART` (stored in `relationship_types.inverse_name`,
  not a separate row — there is no reverse-direction row to query).
- **Database representation**: `object_relationships` row with
  `relationship_type_id` resolved from `relationship_types.name =
  'PART_OF'`.
- **Workspace representation**: `CandidateRelationshipType.PART_OF` in
  `eke-service`'s in-memory graph (`CandidateGraphBuilder`) — same
  semantic, same direction.
- **Future ontology status**: stable, no changes planned.

### CONNECTED_TO

- **Definition**: two objects are physically or logically connected (e.g.
  a Module `CONNECTED_TO` a Connector).
- **Direction**: symmetric (`is_symmetric = true`).
- **Inverse**: `CONNECTED_TO` (itself — symmetric relationships have no
  distinct inverse).
- **Database representation**: `object_relationships` row.
- **Workspace representation**: `CandidateRelationshipType.CONNECTED_TO`
  — same semantic.
- **Future ontology status**: stable. `CONNECTED_VIA` (see deferred
  section) will likely become a more specific sibling of this relationship
  once wiring-path detail is modeled, not a replacement for it.

### CAUSES

- **Definition**: one object causes another (e.g. a failed sensor causes
  a diagnostic code).
- **Direction**: source → target (asymmetric).
- **Inverse**: `CAUSED_BY`.
- **Database representation**: `object_relationships` row.
- **Workspace representation**: not currently produced by COIM or the
  Knowledge Candidate pipeline — seeded but unused by the application
  layer today.
- **Future ontology status**: stable; expected to become active once a
  Reasoning subsystem (EKL stage) exists to infer causal relationships
  deterministically or via engineer annotation.

### USES

- **Definition**: an object uses another (e.g. a Procedure `USES` a
  Component).
- **Direction**: source → target (asymmetric).
- **Inverse**: `USED_BY`.
- **Database representation**: `object_relationships` row.
- **Workspace representation**: `CandidateRelationshipType.USES` is
  defined in the Workspace graph model but not currently emitted by
  `CandidateGraphBuilder`'s heuristics (no detection rule produces it
  yet).
- **Future ontology status**: stable; needs a concrete detection rule
  before it appears in practice.

### REFERENCES

- **Definition**: an object references another without a structural
  (part-of) or physical (connected-to) relationship (e.g. a Vehicle
  `REFERENCES` a Diagnostic Trouble Code detected on it).
- **Direction**: source → target (asymmetric).
- **Inverse**: `REFERENCED_BY`.
- **Database representation**: `object_relationships` row. Also the
  **fallback target** for two workspace-only relationship types that
  aren't yet seeded (see below).
- **Workspace representation**: `CandidateRelationshipType.REFERENCES` —
  same semantic, produced today for DTC-to-Vehicle links.
- **Future ontology status**: stable, and will remain the persisted
  fallback for `MEASURED_AT`/`OBSERVED_IN` until Database Increment 002
  formally adds them (see below).

### DERIVED_FROM

- **Definition**: an object is derived from another (e.g. a corrected
  candidate derived from a misspelled observation).
- **Direction**: source → target (asymmetric).
- **Inverse**: `DERIVES`.
- **Database representation**: `object_relationships` row.
- **Workspace representation**: `CandidateRelationshipType.DERIVED_FROM`
  is defined but not currently emitted by any detection rule.
- **Future ontology status**: stable; a natural fit once the Knowledge
  Evolution subsystem (rename/merge history) exists.

### VALIDATES

- **Definition**: one object provides validation for another (e.g.
  Evidence `VALIDATES` a Universal Object).
- **Direction**: source → target (asymmetric).
- **Inverse**: `VALIDATED_BY`.
- **Database representation**: `object_relationships` row.
- **Workspace representation**: not currently produced.
- **Future ontology status**: stable; expected to activate once the
  Evidence/Validation EKL stages have real implementations.

### CONTAINS

- **Definition**: an object contains another (broader than `PART_OF` —
  e.g. a Document `CONTAINS` a Diagram).
- **Direction**: source → target (asymmetric).
- **Inverse**: `CONTAINED_BY`.
- **Database representation**: `object_relationships` row.
- **Workspace representation**: not currently produced.
- **Future ontology status**: stable; expected to activate once Document/
  Diagram objects are actually committed (currently type-only, see
  `engineering_object_model.md`).

---

## Persistence note: the Workspace graph is richer than the database (by design)

`eke-service`'s in-memory `CandidateGraphBuilder` (application code, not
this repository) can produce `MEASURED_AT` and `OBSERVED_IN` relationship
edges during workspace analysis. Neither exists in `relationship_types`.
Per explicit architect direction during AP-005, this is intentional, not a
bug:

- The Workspace graph is allowed to contain semantics the permanent
  database doesn't yet model.
- When committing to the permanent database, `eke-service` persists only
  relationship types that exist in `relationship_types` today (`PART_OF`,
  `CONNECTED_TO`, `USES`, `REFERENCES`, `DERIVED_FROM` are the ones its
  commit logic currently maps); `MEASURED_AT`/`OBSERVED_IN` edges are
  simply not written to `object_relationships`.
- No new relationship type is inserted at runtime, and no migration adds
  them here — that is explicitly deferred, see below.

## Planned relationships — deferred to Database Increment 002

Not defined anywhere in this schema yet. Listed here so the eventual
Increment 002 migration has a documented starting point, not because any
schema exists for them today:

| Relationship | Intended definition |
|---|---|
| `MEASURED_AT` | A measurement was taken at/against a subject object (e.g. Battery `MEASURED_AT` a 12.48V reading). Already produced in the Workspace graph today; not persisted. |
| `OBSERVED_IN` | An observation was made in the context of a subject object (e.g. an Observation `OBSERVED_IN` a Vehicle). Already produced in the Workspace graph today; not persisted. |
| `LOCATED_IN` | Physical/spatial location of one object relative to another (e.g. a Fuse `LOCATED_IN` a fuse box). |
| `INSTALLED_ON` | An object is installed on another, distinct from `PART_OF` (installation implies a maintenance action/history, not just structural composition). |
| `CONNECTED_VIA` | A more specific form of `CONNECTED_TO` naming the connecting medium (e.g. Module `CONNECTED_VIA` a specific Wire `TO` a Connector). |
| `FEEDS` | Directional power/signal flow (e.g. a Power Source `FEEDS` a Module). |
| `MONITORS` | A Sensor `MONITORS` a Component. |

This work package does not add these — no new migrations, no reference
data changes. They are documented here strictly as the recommended
starting point for whoever authors Database Increment 002.
