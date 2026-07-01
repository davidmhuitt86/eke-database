# Engineering Knowledge Lifecycle (EKL) — Schema Mapping

The Engineering Knowledge Lifecycle, as defined by the architect:

```
Reality
  ↓
Knowledge Event
  ↓
Capture
  ↓
Pending Knowledge Object
  ↓
Observation
  ↓
Reasoning
  ↓
Evidence
  ↓
Validation
  ↓
Universal Object
  ↓
Knowledge Object
  ↓
Knowledge Evolution
```

This document maps each stage to what currently exists in this schema.
**Only the Universal Object stage is implemented.** Every other stage is
either a Workspace-session-only application-layer concept with no
persistent schema, or entirely unimplemented.

## Reality

- **Current support**: none — by definition, this stage is the physical
  world, not data.
- **Future implementation**: N/A.
- **Owning subsystem**: N/A.

## Knowledge Event

- **Current support**: none. No table records "something happened that
  might be knowledge" as a distinct event.
- **Future implementation**: unimplemented. A candidate for a future
  event-log table once the Knowledge Evolution subsystem is designed.
- **Owning subsystem**: none yet.

## Capture

- **Current support**: application-layer only — raw text entering the
  Engineering Workspace editor (`divad-os`) is the capture mechanism.
  Nothing is persisted at this stage; text lives in browser local storage
  until analyzed.
- **Future implementation**: unimplemented in the database. No schema
  change proposed here.
- **Owning subsystem**: `divad-os` (Engineering Workspace UI).

## Pending Knowledge Object

- **Current support**: none directly. The closest schema concept is
  `knowledge_candidates` (V8, live), but a Knowledge Candidate is COIM's
  *already-detected-and-classified* entity, not a raw "something was
  captured, not yet processed" record — this stage sits conceptually
  *before* COIM runs, and nothing persists at that point today.
  `knowledge_candidates` is closer to the Observation stage in practice
  (see below).
- **Future implementation**: unimplemented as its own concept.
- **Owning subsystem**: none yet.

## Observation

- **Current support**: partial, application-layer. `eke-service`'s COIM
  pipeline deterministically detects entities (Vehicle, Component,
  Measurement, DTC, etc.) from raw text — this *is* the Observation stage
  in practice, but it runs entirely in memory during a `/analyze` or
  `/review` request and is not persisted. The `candidate_observations`
  table (V9) is defined for exactly this purpose (recording detection
  context per candidate) but is not live (see `migration_audit.md`).
- **Future implementation**: once V9 is live and `eke-service`'s commit
  path is unblocked, each reviewed candidate's originating observation is
  recorded via `candidate_observations`.
- **Owning subsystem**: `eke-service` (COIM pipeline + Knowledge Candidate
  pipeline), table `candidate_observations` (V9, not yet live).

## Reasoning

- **Current support**: none. No deterministic or other reasoning engine
  exists; the frontend's "Reasoning" page (`divad-os`) is an explicitly
  labeled placeholder with static mock data, not a real subsystem.
- **Future implementation**: unimplemented — explicitly out of scope for
  every work package to date (COIM and the Knowledge Candidate pipeline
  are both deterministic pattern-matching, not reasoning/inference).
- **Owning subsystem**: none yet.

## Evidence

- **Current support**: partial, application-layer. Each Knowledge
  Candidate carries `supportingEvidence` (free-text strings) produced by
  `eke-service`'s `CandidateBuilder`. The `candidate_evidence` table (V11)
  is defined to persist these per-candidate but is not live.
- **Future implementation**: once V11 is live, evidence strings persist
  alongside each reviewed candidate.
- **Owning subsystem**: `eke-service`, table `candidate_evidence` (V11,
  not yet live).

## Validation

- **Current support**: partial. `eke-service`'s `CommitValidator` performs
  *commit-time* structural validation (every candidate has a disposition,
  no duplicate targets, no invalid relationships, confidence present) —
  this is request validation, not engineering-knowledge validation in the
  EKL sense (e.g. no rule engine checks whether a claimed measurement is
  physically plausible).
- **Future implementation**: a true Validation stage (engineering-rule
  checking, not just request-shape checking) is unimplemented.
- **Owning subsystem**: `eke-service` (`CommitValidator`, request-shape
  validation only).

## Universal Object

- **Current support**: full. This is the only EKL stage with real,
  persistent schema: `universal_objects` (V4), extended by `vehicle_objects`
  (V7) for Vehicles, related to each other via `object_relationships`
  (V5). `eke-service`'s `CommitService` creates/updates these rows on a
  successful commit.
- **Future implementation**: N/A — implemented.
- **Owning subsystem**: `eke-database` (schema), `eke-service`
  (`CommitService`, `CommitRepository`).

## Knowledge Object

- **Current support**: none as a distinct concept from Universal Object.
  `object_types` seeds `'Knowledge Rule'` as a type, but no table or
  pipeline distinguishes "Universal Object" (a committed engineering
  entity) from a higher-order "Knowledge Object" (validated, reusable
  engineering knowledge derived from one or more Universal Objects).
- **Future implementation**: unimplemented; depends on Reasoning and
  Validation existing first.
- **Owning subsystem**: none yet.

## Knowledge Evolution

- **Current support**: minimal. The only concession today is
  `universal_objects.version_major`/`version_minor`, bumped by
  `eke-service`'s `CommitService` on a Merge disposition. There is no
  history table, no supersession tracking, no rename/merge audit trail
  at the Universal Object level.
- **Future implementation**: explicitly deferred to a first-class Knowledge
  Evolution subsystem (architect direction during AP-005) covering object
  revisions, supersession, merge/rename history, relationship history,
  validation history, evidence history, commit history, review history,
  and provenance. The existing `candidate_history` table (V12) is
  explicitly **not** to be repurposed as this subsystem — it's scoped to
  the temporary Workspace review process only.
- **Owning subsystem**: none yet — planned as its own future subsystem.

---

## Summary table

| Stage | Support | Owning subsystem |
|---|---|---|
| Reality | N/A | — |
| Knowledge Event | None | — |
| Capture | App-layer only (no schema) | `divad-os` |
| Pending Knowledge Object | None | — |
| Observation | Partial (in-memory; V9 not live) | `eke-service` |
| Reasoning | None | — |
| Evidence | Partial (in-memory; V11 not live) | `eke-service` |
| Validation | Partial (request-shape only) | `eke-service` |
| **Universal Object** | **Full** | **`eke-database` + `eke-service`** |
| Knowledge Object | None | — |
| Knowledge Evolution | Minimal (version columns only) | — (future subsystem) |
