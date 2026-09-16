# Travel Plan Execution Contract

This document defines how `travel-plan` behaves as a repeatable Agent Skill rather than a prompt-only workflow.

The central rule is simple:

> Live research may change because the outside world changes. Once a request and its research evidence are fixed, canonicalization, validation, and rendering must be deterministic.

## 1. Execution Model

The skill has five phases. Agents MUST keep these phases separate even when they are performed in one conversation.

1. **INGEST** — turn user intent into a canonical request.
2. **RESEARCH** — verify external facts and record evidence.
3. **PLAN** — produce one canonical itinerary JSON.
4. **VALIDATE** — run structural and semantic checks.
5. **RENDER** — derive Markdown / Mobile HTML / normalized JSON from the validated itinerary.

The canonical itinerary is the only source of truth for rendered artifacts. Do not independently compose the Markdown and HTML versions.

## 2. Execution Modes

### Interactive mode

Use when a user is actively discussing the trip.

- Ask only for information that materially changes the plan.
- Confirm must-visit vs. nice-to-visit attractions and hard time constraints.
- If the user leaves a non-critical field unknown, record an explicit assumption instead of silently inventing a fact.
- Revisions update the same canonical itinerary and append to `changes`.

### Batch mode

Use for CI, automation, another agent, or a pre-filled request JSON.

- Do not ask follow-up questions.
- Never silently invent a required fact.
- If a hard requirement is missing, return `needs_input` with the missing JSON paths and stop before rendering.
- If an optional planning choice is missing, use a documented default only when the request or this contract permits it, and record it in `assumptions`.
- Strict validation is mandatory before publishable output.

## 3. Canonical Request

Machine-driven runs SHOULD begin with `schemas/request.schema.json`.

Important execution fields:

- `request_id`: stable caller-supplied identifier when available.
- `execution.mode`: `interactive` or `batch`.
- `execution.reference_date`: the date used to resolve relative phrases and judge freshness. Record it; never depend on an implicit system date in a replayable run.
- `execution.research_policy`:
  - `live`: external facts may be queried now.
  - `snapshot`: use the evidence supplied in the request and do not refresh it.
  - `offline`: do not query external sources; unresolved facts become `to_verify`.
- `execution.output_formats`: requested artifacts.

A request is ready for planning when the agent knows, or has explicitly marked unknown, the trip duration/dates, starting point, transport approach, travelers, must-visit places, fixed times, lodging constraints, and pace/preferences that materially affect scheduling.

## 4. Evidence and Freshness

External facts are nondeterministic inputs and MUST be treated as data.

For opening hours, prices, closures, exhibitions, reservations, weather, and transport facts:

- store `title`, `url`, and `checked_at`;
- state exactly which claim the source supports;
- if the fact is time-sensitive, prefer evidence checked for the actual travel date or close enough that the claim is still meaningful;
- if no source is available, put the uncertainty in `to_verify` rather than presenting it as confirmed.

A replay with `research_policy: snapshot` MUST not silently replace recorded evidence with newer web results.

## 5. Assumptions and Decisions

The canonical itinerary may contain:

```json
{
  "assumptions": [
    {
      "id": "a1",
      "field": "preferences.pace",
      "value": "balanced",
      "reason": "request omitted pace; batch default applied"
    }
  ],
  "decisions": [
    {
      "id": "d1",
      "topic": "route-order",
      "decision": "野柳 → 九份",
      "reason": "shorter backtracking under the Day 1 deadline",
      "evidence": ["route-1"]
    }
  ]
}
```

Rules:

- An **assumption** fills an unspecified value. It is never a claim that an external fact is true.
- A **decision** records a planning choice and why it was made.
- Do not put hidden chain-of-thought in these fields. Record concise, user-facing rationale and inputs only.

## 6. Determinism Boundary

The deterministic boundary begins at canonical itinerary JSON.

For the same canonical input and the same formatter version:

- traveler color assignment is stable;
- day numbering is stable;
- summaries are stable;
- normalized JSON is byte-stable except for fields explicitly supplied by the caller;
- Markdown and HTML are derived only from canonical data.

`format-json.sh` therefore does **not** insert the current wall-clock time by default. Use `--generated-at <ISO8601>` for a caller-controlled timestamp, or `--stamp-now` only when a non-replayable publication timestamp is explicitly desired.

## 7. Validation Levels

### Draft validation

`format-json.sh` without `--strict` emits warnings to stderr but still renders a normalized draft. This is useful during an interactive planning conversation.

### Strict validation

`format-json.sh --strict` treats every semantic lint message as a blocking error and exits non-zero before writing publishable normalized JSON.

Strict validation checks at least:

- valid `HH:MM` time fields;
- known segment types;
- traveler highlight references;
- duplicate traveler IDs and day numbers;
- valid source URLs and source check dates;
- segment ordering;
- constraints pointing to real days;
- weather evidence metadata;
- basic non-negative duration/buffer values;
- required segment names.

An agent MUST use strict validation before claiming that a batch run or final artifact is ready.

## 8. Stable Failure Contract

For automation, classify failures as:

| State | Meaning | Agent behavior |
|---|---|---|
| `needs_input` | Required planning input is absent | Return missing JSON paths; do not fabricate values |
| `needs_research` | A required external fact cannot be established under the selected policy | Record `to_verify` or stop if it blocks feasibility |
| `invalid` | Canonical itinerary fails strict validation | Return validator messages; do not publish |
| `ready` | Strict validation passes | Render requested formats |

Shell formatter exit codes:

- `0`: success
- `2`: strict semantic validation failed
- other non-zero: malformed input, missing dependency, or execution failure

## 9. Replay Procedure

To reproduce an existing plan:

1. Use the saved canonical itinerary JSON.
2. Keep its external evidence and assumptions unchanged.
3. Run:

```bash
scripts/format-json.sh --strict itinerary.json normalized.json
scripts/format-html.sh normalized.json itinerary.html
scripts/format-markdown.sh normalized.json itinerary.md
```

4. Compare generated artifacts with the stored artifacts.

To intentionally refresh a plan, start a new RESEARCH phase, update evidence, append an entry to `changes`, increment `meta.revision`, validate again, and regenerate all requested artifacts.

## 10. Agent Invariants

A compliant agent MUST NOT:

- render separate versions from separate internal plans;
- claim an unchecked external fact is confirmed;
- silently ignore an `arrive_by` / `depart_after` constraint;
- silently invent missing hard requirements in batch mode;
- rerun live research during a snapshot replay;
- mutate a previously agreed plan without recording the change.

A compliant agent SHOULD:

- keep one canonical JSON object throughout the run;
- expose concise assumptions and decisions;
- use a caller-supplied `reference_date` in replayable automation;
- preserve evidence sufficient to understand why the plan was valid when produced;
- run strict validation immediately before final rendering.