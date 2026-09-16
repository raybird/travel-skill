# Output Formats Specification

This document defines the canonical itinerary model and the three artifacts rendered from it: JSON, Markdown, and Mobile HTML.

For execution semantics, replay behavior, and batch failure states, read [Execution Contract](execution-contract.md). Machine-readable contracts live in `schemas/request.schema.json` and `schemas/itinerary.schema.json`.

## Pipeline

All rendered formats MUST come from one canonical itinerary JSON.

Draft mode:

```bash
scripts/format-json.sh itinerary.json normalized.json
```

Final / batch mode:

```bash
scripts/format-json.sh --strict itinerary.json normalized.json
scripts/format-html.sh normalized.json itinerary.html
scripts/format-markdown.sh normalized.json itinerary.md
```

All scripts read stdin when no input file is given and write stdout when no output file is given. They require Bash and `jq` 1.6+.

## Determinism

`format-json.sh` is deterministic by default. It does not insert the current wall-clock time.

If a publication timestamp is needed, prefer a caller-controlled value:

```bash
scripts/format-json.sh --strict \
  --generated-at 2026-09-16T06:30:00Z \
  itinerary.json normalized.json
```

`--stamp-now` exists for convenience but makes the normalized JSON intentionally non-replayable and should not be used in golden tests or snapshot replay.

For identical canonical input and formatter version, normalized JSON must be byte-stable.

---

# 1. Canonical JSON

## Purpose

The JSON document is the source of truth for storage, replay, validation, integrations, Markdown, and Mobile HTML.

## Top-level shape

```json
{
  "meta": {
    "generator": "travel-plan-agent",
    "version": "1.2.0",
    "revision": 1,
    "request_id": "optional caller id",
    "reference_date": "2026-09-16",
    "research_policy": "live | snapshot | offline",
    "generated_at": "optional caller-controlled ISO8601 timestamp"
  },
  "trip": {
    "name": "string",
    "duration_days": 3,
    "date": "YYYY-MM-DD",
    "starting_point": "string",
    "transportation": "string"
  },
  "travelers": [],
  "lodging": [],
  "constraints": [],
  "changes": [],
  "assumptions": [],
  "decisions": [],
  "itinerary": [],
  "summary": {}
}
```

Only `trip.name` and at least one itinerary day with segments are needed to render a basic document, but final batch output should satisfy the stricter execution contract.

## Travelers

```json
{
  "id": "kid",
  "label": "妹妹",
  "emoji": "🧒",
  "color": "cyan",
  "profile": "小一",
  "interests": ["動物", "太空"],
  "needs": ["午後容易累"]
}
```

`id` is used as the key in segment `highlights`. If `color` is omitted, normalization assigns a stable color based on traveler order.

Supported automatic colors:

`rose | blue | cyan | violet | amber | green | orange | slate`

## Lodging

```json
{
  "name": "旅店名稱",
  "address": "地址或區域",
  "nights": [1, 2],
  "check_in": "15:00",
  "check_out": "11:00",
  "parking": "停車說明",
  "notes": ["可否先寄放行李"],
  "map_url": "https://...",
  "sources": [
    {
      "title": "旅店官網",
      "url": "https://...",
      "checked_at": "2026-09-16"
    }
  ]
}
```

## Constraints

```json
{
  "day": 3,
  "time": "17:30",
  "kind": "arrive_by",
  "description": "18:00 前要回家"
}
```

Kinds:

- `depart_after`
- `arrive_by`
- `other`

## Assumptions

Assumptions make batch defaults explicit.

```json
{
  "id": "a1",
  "field": "preferences.pace",
  "value": "balanced",
  "reason": "request omitted pace; batch default applied"
}
```

An assumption is never evidence that an external fact is true.

## Decisions

Decisions record concise, user-facing planning rationale.

```json
{
  "id": "d1",
  "topic": "route-order",
  "decision": "野柳 → 九份",
  "reason": "reduces backtracking under the Day 1 deadline",
  "evidence": ["route-1"]
}
```

Do not store hidden chain-of-thought. Keep only the decision, concise reason, and relevant evidence identifiers.

## Day

```json
{
  "day": 2,
  "title": "動物園上午場與室內下午",
  "date": "2026-10-15",
  "weather": {
    "summary": "午後雷陣雨",
    "temperature": "23–28°C",
    "rain_chance": 60,
    "source": "中央氣象署",
    "checked_at": "2026-10-11"
  },
  "segments": [],
  "travel_notes": "string"
}
```

## Segment

```json
{
  "time": "09:00",
  "type": "attraction",
  "name": "臺北市立動物園",
  "address": "臺北市立動物園",
  "duration_minutes": 180,
  "coordinates": { "lat": 25.0, "lng": 121.5 },
  "map_url": "https://...",
  "notes": "string",
  "tips": ["string"],
  "buffer_minutes": 20,
  "buffer_notes": "入園與遊園列車排隊",
  "transit": {
    "mode": "rideshare",
    "lines": [],
    "duration_minutes": 30,
    "summary": "6 人座車直達正門",
    "call_at": "08:25",
    "origin": "旅店",
    "waypoints": [],
    "map_url": "https://..."
  },
  "highlights": {
    "kid": "企鵝館、大貓熊館"
  },
  "sources": [
    {
      "title": "臺北市立動物園",
      "url": "https://www.zoo.gov.taipei/",
      "checked_at": "2026-09-16",
      "claim": "營業時間"
    }
  ],
  "to_verify": "若仍有未確認事項，精確寫在這裡",
  "rain_plan": {
    "name": "國立臺灣博物館 鐵道部園區",
    "duration_minutes": 150,
    "reason": "大雨時改走室內",
    "notes": "string"
  }
}
```

### Segment types

- `attraction` — main attraction
- `break` — rest stop
- `meal` — meal or restaurant
- `travel` — explicit travel block
- `optional` — nice-to-visit if schedule allows

### Rain plan fallback

A rain plan may omit `time` and `type`; renderers fall back to the parent segment values. It must have its own `name` and a human-readable `reason`.

### Transit semantics

`transit` describes how to reach the current segment from the previous point. Supported modes:

`drive | mrt | bus | train | hsr | taxi | rideshare | walk`

For rail/MRT legs, `lines` can be strings such as `"R"` or objects like `{ "code": "R", "name": "紅線" }`.

## Sources and `to_verify`

Confirmed time-sensitive claims should include source metadata. Legacy data may omit `checked_at`, but new final plans should include it whenever available.

If a fact could not be verified, do not turn it into an assertion. Put the unresolved item in `to_verify`.

## Summary

When omitted, normalization computes:

```json
{
  "total_attractions": 4,
  "total_estimated_hours": 11.5,
  "rest_stops_recommended": 3,
  "notes": []
}
```

Caller-provided summary fields override computed values.

---

# 2. Normalization and Validation

`format-json.sh` normalizes:

- `meta.generator = travel-plan-agent`
- `meta.version = 1.2.0`
- day numbers when omitted
- traveler colors when omitted
- empty arrays for lodging / constraints / changes / assumptions / decisions
- summary counts

It intentionally does not inject `generated_at` unless requested.

Draft mode prints semantic warnings and still produces normalized output.

Strict mode:

```bash
scripts/format-json.sh --strict input.json output.json
```

Strict mode exits `2` before writing `output.json` if semantic lint messages exist.

Semantic checks include:

- `HH:MM` time syntax
- known segment and constraint kinds
- non-empty segment names
- duplicate traveler IDs and itinerary day numbers
- non-negative duration/buffer values
- highlight keys referencing known travelers
- `http(s)` source URLs
- malformed source check dates
- out-of-order segment times
- invalid day references from constraints
- basic deadline checks
- weather source/check-date metadata
- trip duration matching itinerary day count

`to_verify` is reported separately as unresolved work; it is not automatically a validation failure because offline/snapshot planning may intentionally preserve unknowns.

---

# 3. Markdown Format

## Purpose

Human-readable and printable itinerary.

## Structure

```markdown
# [Trip Name]

> 3天 · 10/14（三） · 台中出發 · 自駕＋捷運

## 同行成員
...

## 住宿
...

## 固定時間點
...

## 修正重點
...

---

## Day 1: [Day Theme]

> 🌦️ 天氣資訊
> ⏰ 固定時間
> ✅ 修正

### 上午
| 時間 | 項目 | 說明 | ⛈️ 雨備 |
...
```

Conventions:

- Empty day periods are omitted.
- The rain-plan column appears only when that day has a rain plan.
- Multi-line table details use `<br>`.
- Sources appear under the relevant day.
- `to_verify` is rendered visibly instead of being hidden.

See `examples/taipei-family-3days.md`.

---

# 4. Mobile HTML Format

## Purpose

Phone-first itinerary that can be saved and opened during the trip.

## Requirements

- one self-contained HTML file;
- CSS embedded, no required local assets;
- Day tabs instead of a single long scrolling document;
- sunny / rain-plan toggle when rain plans exist;
- minimum comfortable mobile typography and tap targets;
- stable traveler colors and highlight chips;
- visible `changes`, constraints, and `to_verify` notices;
- Google Maps place buttons and route buttons when enough transit data exists;
- safe escaping of untrusted itinerary values;
- unsafe URLs such as `javascript:` are not emitted;
- without JavaScript, content remains accessible;
- print mode shows all days;
- system dark mode is supported.

The template is `assets/html-template.html`; presentation tokens are in `assets/style.css`.

See `examples/taipei-family-3days.html`.

---

# 5. Replay and Golden Tests

A saved canonical itinerary can be replayed without live research:

```bash
scripts/format-json.sh --strict itinerary.json normalized-a.json
scripts/format-json.sh --strict itinerary.json normalized-b.json
cmp normalized-a.json normalized-b.json
```

The repository validator performs this check automatically:

```bash
bash skills/travel-plan/validate.sh
```

When intentionally refreshing real-world facts, update the canonical source data, append a `changes` entry, increment revision if used, and regenerate every requested artifact.