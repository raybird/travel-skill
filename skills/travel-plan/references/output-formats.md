# Output Formats Specification

This document defines the itinerary JSON that the Travel Plan agent builds, and the three outputs rendered from it: Markdown, Mobile HTML, and JSON.

## Pipeline

All three formats come from one itinerary JSON. Build the JSON first, then render:

```bash
scripts/format-json.sh itinerary.json normalized.json      # normalize + warnings on stderr
scripts/format-html.sh normalized.json itinerary.html
scripts/format-markdown.sh normalized.json itinerary.md
```

- All scripts read stdin when no input file is given and write stdout when no output file is given.
- All scripts require `jq` (1.6+). Shared helpers live in `scripts/lib/` (`common.sh`, `itinerary.jq`).
- A complete example with every field: `examples/taipei-family-3days.json`, plus its rendered `.html` and `.md`.

---

## 1. JSON Format

### Purpose
Structured data for programmatic use, storage, and as the single source for the other formats.

### File Extension
`.json`

### Schema

Only `trip.name` and `itinerary[].segments[]` are needed to render something useful; every other field is optional and v1.0 itineraries still render.

```json
{
  "meta": {
    "generated_at": "ISO8601 timestamp (filled by format-json.sh)",
    "generator": "travel-plan-agent",
    "version": "1.1.0",
    "revision": "number (optional, 第幾版)"
  },
  "trip": {
    "name": "string",
    "duration_days": "number",
    "date": "YYYY-MM-DD (first day)",
    "starting_point": "string",
    "transportation": "string"
  },
  "travelers": [
    {
      "id": "string (used as highlights key)",
      "label": "string, e.g. 姊姊",
      "emoji": "string (optional)",
      "color": "rose | blue | cyan | violet | amber | green | orange | slate (optional)",
      "profile": "string, e.g. 國二、駕駛",
      "interests": ["string"],
      "needs": ["string: health, stamina, mobility"]
    }
  ],
  "lodging": [
    {
      "name": "string",
      "address": "string",
      "nights": ["number: day numbers"],
      "check_in": "HH:MM",
      "check_out": "HH:MM",
      "parking": "string",
      "notes": ["string: luggage drop, facilities"],
      "map_url": "string (optional)",
      "sources": [{ "title": "string", "url": "string", "checked_at": "YYYY-MM-DD" }]
    }
  ],
  "constraints": [
    {
      "day": "number",
      "time": "HH:MM",
      "kind": "depart_after | arrive_by | other",
      "description": "string"
    }
  ],
  "changes": [
    { "day": "number (optional; omit for trip-wide)", "title": "string", "detail": "string" }
  ],
  "itinerary": [
    {
      "day": "number",
      "title": "string (day theme)",
      "date": "YYYY-MM-DD",
      "weather": {
        "summary": "string",
        "temperature": "string, e.g. 24–29°C",
        "rain_chance": "number (percent)",
        "source": "string",
        "checked_at": "YYYY-MM-DD"
      },
      "segments": ["Segment"],
      "travel_notes": "string"
    }
  ],
  "summary": {
    "total_attractions": "number (computed when omitted)",
    "total_estimated_hours": "number (computed when omitted)",
    "rest_stops_recommended": "number (computed when omitted)",
    "notes": ["string: travel tips"]
  }
}
```

**Segment**

```json
{
  "time": "HH:MM",
  "type": "attraction | break | meal | travel | optional",
  "name": "string",
  "address": "string",
  "duration_minutes": "number",
  "coordinates": { "lat": "number", "lng": "number" },
  "map_url": "string (optional; generated from coordinates/address/name)",
  "notes": "string",
  "tips": ["string"],
  "buffer_minutes": "number: queue/ticket/wait time already included in the schedule",
  "buffer_notes": "string",
  "transit": {
    "mode": "drive | mrt | bus | train | hsr | taxi | rideshare | walk",
    "lines": ["BL", "R", { "code": "R", "name": "紅線" }],
    "duration_minutes": "number",
    "summary": "string: transfers, exits",
    "call_at": "HH:MM (when to book the ride)",
    "origin": "string (optional)",
    "waypoints": ["string (optional; pins the route, e.g. a service area on the chosen freeway)"],
    "map_url": "string (optional; overrides generated directions)"
  },
  "highlights": { "<traveler id>": "string" },
  "sources": [{ "title": "string", "url": "https://...", "checked_at": "YYYY-MM-DD" }],
  "to_verify": "string: what the user still needs to confirm",
  "rain_plan": "Segment without rain_plan, plus reason (time and type fall back to the parent)"
}
```

### Field Rules

| Field | Rule |
|-------|------|
| `transit` | How to reach this segment from the previous one |
| `rain_plan.reason` | Why to switch, e.g. 「午後雷雨時戶外設施可能暫停」 |
| `buffer_minutes` | Already counted inside the schedule, not added on top |
| `sources` / `to_verify` | Every opening hour, price, exhibition, or forecast has a source; anything unchecked goes in `to_verify` |
| `constraints.arrive_by` | The day's last segment must start no later than this time |
| `constraints.depart_after` | The day's first segment must start no earlier than this time |
| `transit.lines` | Codes default to Taipei Metro names (BL 板南線, R 淡水信義線, G 松山新店線, O 中和新蘆線, BR 文湖線, Y 環狀線, A 機場捷運, V 淡海輕軌, K 安坑輕軌); use `{code, name}` for other systems |

### Type Values

| Type | Description |
|------|-------------|
| `attraction` | Must-visit tourist spot |
| `break` | Rest stop, rest area |
| `meal` | Restaurant or dining |
| `travel` | Transit between locations |
| `optional` | Nice-to-visit if time permits |

### What `format-json.sh` Does

- Fills `meta.generated_at`, `generator`, `version`; numbers days; assigns traveler colors in order.
- Computes `summary` counts unless provided.
- Warns on stderr (exit code stays 0):
  - `time` / `call_at` not `HH:MM`, unknown `type`
  - `highlights` keys that match no traveler
  - `sources` without an `http(s)` URL
  - segments out of time order
  - last segment later than `arrive_by`, first segment earlier than `depart_after`
  - `weather` without `source` and `checked_at`
- Reports how many items are still `to_verify`.

### Example (excerpt)

```json
{
  "trip": { "name": "台北親子三日遊（虛構範例）", "duration_days": 3, "date": "2026-10-14", "starting_point": "台中", "transportation": "自駕＋捷運" },
  "travelers": [
    { "id": "mom", "label": "媽媽", "emoji": "👩", "color": "violet", "needs": ["怕悶熱"] },
    { "id": "kid", "label": "妹妹", "emoji": "🧒", "color": "cyan", "profile": "小一" }
  ],
  "constraints": [
    { "day": 3, "time": "17:30", "kind": "arrive_by", "description": "妹妹 18:00 有才藝課" }
  ],
  "itinerary": [
    {
      "day": 2,
      "title": "動物園上午場與室內下午",
      "date": "2026-10-15",
      "weather": { "summary": "午後雷陣雨", "rain_chance": 60, "source": "中央氣象署", "checked_at": "2026-10-11" },
      "segments": [
        {
          "time": "09:00",
          "type": "attraction",
          "name": "臺北市立動物園",
          "duration_minutes": 180,
          "buffer_minutes": 20,
          "buffer_notes": "入園與遊園列車排隊",
          "transit": { "mode": "rideshare", "duration_minutes": 30, "call_at": "08:25", "summary": "5 人叫 6 人座車直達正門" },
          "highlights": { "kid": "企鵝館、大貓熊館", "mom": "每走一段就進室內館休息" },
          "to_verify": "遊園列車班次與票價以官網公告為準",
          "sources": [{ "title": "臺北市立動物園", "url": "https://www.zoo.gov.taipei/" }],
          "rain_plan": {
            "time": "09:30",
            "name": "國立臺灣博物館 鐵道部園區",
            "duration_minutes": 150,
            "reason": "出門時已經下大雨，動物園戶外路段濕滑又耗體力"
          }
        }
      ]
    }
  ]
}
```

---

## 2. Markdown Format

### Purpose
Standard formatted document for human readability, easy sharing, and printing.

### File Extension
`.md`

### Structure

```markdown
# [Trip Name]

> 3天 · 10/14（三） · 台中出發 · 自駕＋捷運

## 同行成員
| 成員 | 說明 | 興趣 | 需要留意 |

## 住宿
- **旅店名稱**（第 1、2 晚）　入住 15:00／退房 11:00

## 固定時間點
- Day 3 17:30 前抵達：說明

## 修正重點
- ✅ **標題**：說明（trip-wide changes only）

---

## Day X: [Day Theme] · 10/15（四）

> 🌦️ 天氣 · 氣溫 · 降雨 60%（來源，查詢日期）

> ✅ **修正：標題** — 說明（this day's changes）

> ⏰ **固定時間：17:30 前抵達** — 說明

### 上午 (Morning)
| 時間 | 項目 | 說明 | ⛈️ 雨備 |
|------|------|------|------|
| HH:MM | 類型｜地點名稱 | 說明<br>交通<br>⏳ 緩衝<br>成員亮點<br>⚠️ 待確認 | **雨備地點**<br>說明<br>💡 切換原因 |

### 中途 (Midday)
### 下午 (Afternoon)

交通說明：...

**資料來源**
- [標題](url)（查證日期）

---

## 旅遊注意事項 (Travel Tips)
- 提示項目

---

*此行程由 Travel Plan Agent 產生*
```

### Styling Conventions
- `#` for main title, `##` for sections and days, `###` for time periods
- Periods: 上午 before 11:00, 中途 11:00–14:00, 下午 from 14:00; empty periods are omitted
- The ⛈️ 雨備 column appears only on days that have a `rain_plan`
- Multi-line details use `<br>` inside table cells
- Horizontal rules `---` separate days

See `examples/taipei-family-3days.md` for full output.

---

## 3. Mobile HTML Format

### Purpose
Phone-first itinerary to open during the trip.

### File Extension
`.html`

### Requirements
- Single self-contained file: `style.css` is inlined, no local assets; works offline once saved
- Large type: body 19px, headings 21–30px; tap targets at least 44px
- Top tabs switch between Day 1 / Day 2 / … / 須知 instead of one long page (`#day-2` links open that day)
- ☀️ 晴天 / ⛈️ 雨備 toggle replaces each segment with its `rain_plan`; the choice is remembered on the device
- Times use a departure-board style: dark background, amber JetBrains Mono digits. The font loads from Google Fonts when online and falls back to the system monospace font offline
- Each traveler keeps one color across all days (legend in the header, chips on highlights)
- `changes` show as green 「✅ 修正」 boxes; `constraints` as amber 「⏰ 固定時間」 boxes
- Every place gets a Google Maps capsule button; segments with `transit.origin` or `waypoints` also get a 路線導航 button
- Without JavaScript all days and both plans are shown in order; printing always shows everything
- Dark mode follows the system setting

### Template Placeholders

`assets/html-template.html` is filled in a single pass, so values containing `{{...}}` are never substituted again.

| Placeholder | Source | Encoding |
|-------------|--------|----------|
| `{{STYLES}}` | `assets/style.css` | raw |
| `{{TRIP_NAME}}` | `trip.name` | HTML-escaped |
| `{{TRIP_META}}` | `duration_days`, `date`, `starting_point`, `transportation` (empty parts skipped) | HTML-escaped |
| `{{TRIP_NAME_JSON}}` / `{{DATE_JSON}}` | `trip.name` / `trip.date` | JSON string literal for `<script>` |
| `{{TRAVELER_LEGEND}}` | `travelers[]` | generated markup |
| `{{DAY_TABS}}` | `itinerary[]` + 須知 tab | generated markup |
| `{{PLAN_TOGGLE}}` | shown only when any segment has `rain_plan` | generated markup |
| `{{DAY_PANELS}}` | `itinerary[]`, day `changes` and `constraints` | generated markup |
| `{{OVERVIEW}}` | trip-wide `changes`, `travelers`, `lodging`, all `constraints` | generated markup |
| `{{TRAVEL_TIPS}}` | `summary.notes[]` | `<li>` items |

### Segment Rendering

| `type` | Card accent | Tag |
|--------|-------------|-----|
| `attraction` | by time: morning (<12:00), afternoon (12–17), evening (≥17) | 景點 |
| `optional` | by time | 選配 |
| `meal` | break color | 用餐 |
| `break` | break color | 休息 |
| `travel` | by time | 交通 |

Card order: board-style time, tag, duration, rain badge → name → transit box (mode, line badges, duration, summary, 叫車 time) → notes → tips → ⏳ buffer → traveler highlights → ⚠️ 待確認 → 💡 切換原因 (rain plan only) → map and source buttons.

Only `http(s)` URLs are rendered as links.

### Styling (Vibrant Color Scheme)

```css
--primary: #FF6B6B      /* Coral Red: header, active tab */
--secondary: #4ECDC4    /* Teal: morning accent, map buttons */
--accent: #FFE66D       /* Yellow: afternoon accent, 晴天 toggle */
--board-bg: #0B0F17     /* Departure board background */
--board-text: #FBBF24   /* Amber digits */
```

Traveler colors: `rose`, `blue`, `cyan`, `violet`, `amber`, `green`, `orange`, `slate`. Full stylesheet: `assets/style.css`.

See `examples/taipei-family-3days.html` for full output.

---

## Format Selection Guide

| Use Case | Recommended Format |
|----------|-------------------|
| Share via LINE/Email | Mobile HTML |
| Check the plan on the road | Mobile HTML |
| Print or PDF export | Markdown |
| Import to apps (日曆, Notion) | JSON |
| Documentation archive | Markdown |
| Programmatic processing | JSON |

---

## Related Documentation

- See [Taiwan Data Sources](taiwan-data-sources.md) for data input and where to verify facts
- See [Conversation Guide](conversation-guide.md) for presentation tips
