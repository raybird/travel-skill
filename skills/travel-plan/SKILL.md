---
name: travel-plan
description: 為台灣旅遊設計的可重複執行智慧行程規劃技能。支援互動與 batch 模式、固定 reference date、外部資料查證與 snapshot replay、同行成員需求、固定時間倒推、雨天備案，以及 deterministic JSON → Markdown / Mobile HTML 輸出。當使用者需要規劃或調整台灣旅遊行程，或 Agent/CI 需要可驗證、可重播的旅遊規劃流程時使用此技能。
license: MIT
compatibility: Designed for Agent Skills platform. Works with LLMs capable of tool calling and conversational interaction. Output scripts require bash and jq 1.6+. Web access is recommended for live research but snapshot/offline replay is supported.
metadata:
  author: travel-skills
  version: "1.2.0"
  tags: travel, taiwan, itinerary, planning, reproducible, agent-skill, 旅遊, 行程規劃
---

# Travel Plan Agent Skill

## Overview

This skill plans Taiwan travel itineraries through one canonical data model and renders Markdown, Mobile HTML, or JSON from that model.

It is designed as an executable Agent Skill, not a prompt template. Separate live research from deterministic planning artifacts: external facts may change, but once the canonical itinerary and evidence are fixed, validation and rendering must be repeatable.

Read [Execution Contract](references/execution-contract.md) before implementing a batch integration or replay workflow.

## When to Use

- User wants to plan a trip in Taiwan or arrange attraction order
- User asks for rest stop, dining, route, lodging-area, or transport recommendations
- User wants an existing itinerary adjusted for weather, a deadline, or traveler changes
- User requests Markdown, Mobile HTML, or JSON output
- Another agent, workflow, or CI job needs a machine-readable and reproducible itinerary pipeline

## Execution Modes

### Interactive

Use normal conversation to collect only information that materially changes the plan. Unknown non-critical values may be handled with explicit assumptions. Keep one canonical itinerary JSON through every revision.

### Batch

Use `schemas/request.schema.json` as the preferred input contract. Do not ask follow-up questions and do not silently invent required facts. Missing hard requirements produce a `needs_input` result; unresolved external facts follow the selected research policy.

Batch/final output MUST pass strict validation before it is described as ready.

## State Machine

Every run follows the same conceptual phases:

`INGEST → RESEARCH → PLAN → VALIDATE → RENDER → COMPLETE`

Do not independently compose separate Markdown and HTML plans. Both must derive from the same canonical itinerary JSON.

## Workflow

### Step 1: Ingest the Request

Collect or normalize:

- trip duration and dates
- starting point and transportation
- attractions, each marked `must` or `nice`
- travelers: id/label, age group or role, interests, stamina/mobility needs
- fixed times: `depart_after`, `arrive_by`, or other hard constraints
- lodging: check-in/out, parking, luggage drop when relevant
- pace and other preferences that materially affect scheduling
- execution settings for automation: mode, reference date, research policy, requested formats

For replayable runs, resolve relative phrases against an explicit `reference_date`; do not depend on an implicit system date.

**Done when:** every material field has a user value, a recorded assumption, or is explicitly unknown. In batch mode, a missing hard requirement stops the run as `needs_input`.

### Step 2: Research External Facts

Verify only facts needed to make the itinerary feasible or useful: opening hours, closures, prices, booking requirements, weather, exhibitions, and transport conditions.

Research policies:

- `live`: query current sources and record evidence
- `snapshot`: use supplied evidence without silently refreshing it
- `offline`: do not query external sources; unresolved claims become `to_verify`

Every confirmed external fact should carry a source title, URL, and check date. If it cannot be confirmed, state exactly what remains to verify.

**Done when:** blocking facts are verified or explicitly unresolved according to policy.

### Step 3: Choose Route and Schedule

- Cluster attractions geographically.
- Apply hard time constraints before soft preferences.
- Compare meaningful route alternatives by time, distance, comfort, and congestion risk.
- Back-plan from `arrive_by` deadlines.
- Include queue, parking, ticketing, luggage, ride-hail, and meal-wait buffers.
- Add rest stops based on driving length and traveler needs.
- Give weather-sensitive segments a rain plan.

Record concise user-facing planning choices in `decisions`; record missing-input defaults in `assumptions`. These are rationale records, not hidden chain-of-thought.

**Done when:** one canonical day-by-day itinerary exists and every hard constraint is represented.

### Step 4: Build Canonical Itinerary JSON

Follow `schemas/itinerary.schema.json` and [Output Formats](references/output-formats.md).

The canonical JSON is the single source of truth for all artifacts. Preserve:

- `meta.revision`
- `meta.reference_date` and research policy when available
- travelers, lodging, constraints
- `assumptions` and `decisions`
- `changes`
- segment sources / `to_verify`
- rain plans

### Step 5: Validate

During interactive drafting:

```bash
scripts/format-json.sh itinerary.json normalized.json
```

Warnings are allowed while the user is still editing the trip.

Before batch/final publication:

```bash
scripts/format-json.sh --strict itinerary.json normalized.json
```

Strict mode exits `2` when semantic lint messages exist and does not write publishable output.

For a reproducible publication timestamp, let the caller supply it:

```bash
scripts/format-json.sh --strict \
  --generated-at 2026-09-16T06:30:00Z \
  itinerary.json normalized.json
```

Do not use `--stamp-now` in a replay/golden-test path.

**Done when:** strict validation passes, or every remaining issue is returned as `invalid` instead of being silently ignored.

### Step 6: Render

Render only from the normalized canonical JSON:

```bash
scripts/format-html.sh normalized.json itinerary.html
scripts/format-markdown.sh normalized.json itinerary.md
```

| Format | Characteristics |
|---|---|
| Markdown | Day-by-day tables with rain plan column; useful for printing/archiving |
| Mobile HTML | Self-contained offline file with Day tabs, sunny/rain toggle, large type, traveler chips, map buttons |
| JSON | Canonical normalized model for storage, replay, integrations, and tests |

### Step 7: Revise

For each user-approved change:

1. update the canonical JSON;
2. append a user-facing entry to `changes`;
3. increment `meta.revision` when the plan is versioned externally;
4. rerun strict validation for final output;
5. regenerate every requested artifact.

Never patch only one rendered format.

## Planning Rules

1. **Back-plan from deadlines.** With an `arrive_by` constraint, schedule backwards from the deadline including drive time and buffer. Keep the last day moving toward the return direction.
2. **Budget buffers.** Allow time for ticketing/queues, elevators, ride-hail pickup, parking, check-in/luggage drop, and peak restaurant waits. Record `buffer_minutes`.
3. **Plan for weather.** Every outdoor or weather-sensitive segment gets a `rain_plan` and a switch reason.
4. **Show route trade-offs.** When routes differ materially, compare time, distance, comfort, and congestion risk; state the cost of the chosen option.
5. **Size transport to the group.** A standard Taiwan taxi generally carries up to 4 passengers; for 5+ use an appropriate larger vehicle or split the group. For MRT legs include lines/transfers/exits when useful.
6. **Tailor per traveler.** Put per-person segment value in `highlights`, keyed by traveler id.
7. **Cite or flag facts.** Confirmed external facts carry evidence; unchecked facts go in `to_verify`.
8. **Record revisions.** Every change to an agreed itinerary adds a `changes` entry.
9. **Schedule rest stops.** Add a break for long driving legs, meal-time conflicts, or traveler stamina needs.
10. **Record assumptions.** Never hide a default that materially affects batch output.
11. **Keep a deterministic boundary.** Once canonical JSON is fixed, normalization/rendering must not depend on current wall-clock time or a fresh web lookup.
12. **Publish only validated output.** Batch/final output must pass strict validation.

## Machine Contracts

- Canonical request: `schemas/request.schema.json`
- Canonical itinerary: `schemas/itinerary.schema.json`
- Execution semantics: `references/execution-contract.md`
- Output model: `references/output-formats.md`
- Conversation patterns: `references/conversation-guide.md`
- Taiwan research sources: `references/taiwan-data-sources.md`

## Failure States

Use stable states for agent integrations:

- `needs_input`: hard request data is missing
- `needs_research`: a blocking external fact cannot be established under current policy
- `invalid`: canonical itinerary fails strict validation
- `ready`: strict validation passes and requested artifacts may be rendered

## Examples

### Interactive Day Trip

**User:** 「想去九份和野柳，一日遊怎麼安排？」

1. Ingest starting point, travelers, date, priorities, and any deadline.
2. Research hours/closures if a real date is supplied.
3. Compare route order.
4. Build one canonical itinerary.
5. Draft-validate while discussing.
6. Strict-validate and render the requested format when finalized.

### Batch Replay

Given a saved canonical itinerary and research snapshot:

```bash
scripts/format-json.sh --strict itinerary.json normalized.json
scripts/format-html.sh normalized.json itinerary.html
scripts/format-markdown.sh normalized.json itinerary.md
```

Running the first command repeatedly with identical input and formatter version must produce byte-identical normalized JSON unless the caller explicitly supplies different metadata.

## Limitations

- **Geographic scope:** optimized for Taiwan; other destinations have limited source guidance.
- **Live data:** weather, closures, traffic, and prices naturally change. Repeatability applies after evidence is fixed; `live` research itself is not promised to return identical facts later.
- **Bookings:** recommendations only unless the host Agent has a separate authorized booking capability.
- **Budget:** no full trip-cost optimizer yet; quoted prices remain source-backed facts.
- **Route solving:** current implementation applies planning rules and validation but is not a mathematical VRP/TSP optimizer.

## Validation of the Skill Itself

Repository checks are run with:

```bash
bash skills/travel-plan/validate.sh
```

The validator checks contract files, schemas, strict validation, deterministic canonical JSON, renderer golden files, and HTML escaping.
