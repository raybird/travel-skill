---
name: travel-plan
description: 為台灣旅遊設計的智慧行程規劃技能。支援自由輸入必訪景點、自然語言討論行程順序、依同行成員需求與固定時間點排程、附雨天備案與查證來源，並可輸出 Markdown、Mobile HTML、JSON 三種格式。當使用者需要規劃台灣旅遊行程、安排景點順序、討論旅遊路線，或因天氣、時間、成員變動而調整既有行程時使用此技能。
license: MIT
compatibility: Designed for Agent Skills platform. Works with LLMs capable of tool calling and conversational interaction. Output scripts require bash and jq. Web access is recommended for verifying opening hours, prices, and weather forecasts.
metadata:
  author: travel-skills
  version: "1.1.0"
  tags: travel, taiwan, itinerary, planning, 旅遊, 行程規劃
---

# Travel Plan Agent Skill

## Overview

This skill plans Taiwan travel itineraries through conversation and renders them as Markdown, Mobile HTML, or JSON. Plans account for who is traveling, fixed times the trip must respect, weather, and verifiable facts.

## When to Use

- User wants to plan a trip in Taiwan or arrange the order of attractions
- User asks for rest stop, dining, route, or transport recommendations
- User wants an existing itinerary adjusted for weather, a new deadline, or a change in travelers
- User requests the itinerary in a specific format

## Workflow

### Step 1: Collect Must-Visit Attractions

- Accept free-text input (e.g., 「想去九份、野柳、淡水」)
- Ask which are must-visit and which are nice-to-visit
- Read the list back for confirmation

**Done when:** the user has confirmed the list and every attraction is marked must-visit or nice-to-visit.

### Step 2: Confirm Trip Parameters

- **Duration and dates**
- **Starting point and transportation**
- **Travelers**: for each person, what to call them, age group or role, interests, and health or stamina needs (heat sensitivity, frequent rest, mobility). Headcount decides vehicle size.
- **Fixed times**: the earliest departure (e.g., only after a work shift ends) and any arrive-by deadline (e.g., back home for an evening class)
- **Lodging**: check-in and check-out times, parking, and whether the car and luggage can be dropped off before check-in
- **Weather**: the forecast for the travel dates, per Planning Rules 3 and 7

**Done when:** every item above has an answer from the user, or is shown to the user as unknown along with the assumption you will plan with.

### Step 3: Discuss Itinerary Order

- Propose a route based on geography and the fixed times
- Present route options with their trade-offs (Planning Rule 4)
- Ask about pace and direction preferences

**Done when:** the user has chosen an order and, where routes differ, a route.

### Step 4: Generate Itinerary

Build the day-by-day plan with travel times, visit durations, rest stops, and meals, applying every Planning Rule below.

**Done when:** each Planning Rule is satisfied, or the reason it does not apply has been stated to the user.

### Step 5: Output

Render through the script pipeline (all scripts require `jq`):

1. Build the itinerary JSON following [Output Formats](references/output-formats.md). A complete example: `examples/taipei-family-3days.json`.
2. Normalize and check it:
   ```bash
   scripts/format-json.sh itinerary.json normalized.json
   ```
   Warnings go to stderr: malformed times, unknown segment types, `highlights` keys that match no traveler, segments scheduled past an `arrive_by` deadline, and similar.
3. Render the requested formats:
   ```bash
   scripts/format-html.sh normalized.json itinerary.html
   scripts/format-markdown.sh normalized.json itinerary.md
   ```

| Format | Characteristics |
|--------|-----------------|
| Markdown | Day-by-day tables with a rain-plan column; suited to printing and archiving |
| Mobile HTML | One self-contained file that works offline: Day tabs, sunny/rain plan toggle, departure-board style times, color chips per traveler, 19px body text, Google Maps capsule buttons. The monospace time font loads JetBrains Mono when online and falls back to the system monospace font offline. |
| JSON | The normalized data model, for storage or other tools |

**Done when:** `format-json.sh` reports no warnings (or each remaining warning has been explained to the user) and every requested file has been generated.

### Step 6: Iterate and Refine

For each adjustment, update the JSON, add an entry to `changes` (rendered as a green 「✅ 修正」 box in HTML), and re-run Step 5.

**Done when:** the regenerated outputs reflect the change and `changes` lists it.

## Planning Rules

1. **Back-plan from deadlines.** With an `arrive_by` constraint, schedule backwards from the deadline including drive time and buffer. On the last day, place sights along the return direction so the long drive does not end right at the deadline.
2. **Budget buffers.** Allow time for ticketing and queues, observation-deck elevators, ride-hail pickup (about 5–10 minutes), parking, check-in and luggage drop, and peak-hour restaurant waits. Record it in the segment's `buffer_minutes`.
3. **Plan for weather.** Give every outdoor or weather-sensitive segment a `rain_plan`, including the reason to switch.
4. **Show route trade-offs.** When routes differ, list time, distance, comfort, and congestion risk for each, and let the user choose. State the cost of the recommended option explicitly, e.g., the smoother freeway takes 20–30 minutes longer.
5. **Size transport to the group.** A standard Taiwan taxi carries up to 4 passengers; for 5 or more, book a 6–7 seat vehicle through an app or split into two cars. For MRT legs, give the lines, transfer stations, and exit numbers.
6. **Tailor per traveler.** Put each traveler's highlight for a segment in `highlights`, keyed by traveler id.
7. **Cite or flag facts.** Opening hours, prices, exhibitions, and weather carry `sources` (`title`, `url`, `checked_at`). Anything you could not check goes in `to_verify`, telling the user exactly what to confirm. Call a fact confirmed only when a source backs it.
8. **Record revisions.** Every change to an agreed itinerary adds an entry to `changes`.
9. **Schedule rest stops.** Add a break when a leg exceeds 1 hour, when a meal time (around 12:00 or 18:00) falls on the road, or when a traveler's stamina needs call for it.

Sample dialogue for each rule, including deadlines discovered mid-conversation and "did you verify this?" questions: [Conversation Guide](references/conversation-guide.md).

## Examples

### Example 1: Day Trip

**User:** 「想去九份和野柳，一日遊怎麼安排？」

1. Confirm attractions, starting point, and travelers
2. Compare 野柳→九份 and 九份→野柳, with reasons
3. Add a lunch stop on the way and buffers at each site
4. Generate the requested formats

### Example 2: Multi-Day Trip with a Deadline

**User:** 「台中出發去台北三天兩夜，一家五口，最後一天傍晚要回台中上才藝課。」

1. Record the five travelers with their interests and needs, and the Day 3 `arrive_by`
2. Plan transport for five (6–7 seat ride-hail or MRT)
3. Back-plan Day 3 from the deadline and keep its sights toward the return route
4. Attach rain plans to outdoor segments and sources to hours and prices
5. Run the Step 5 pipeline; `examples/taipei-family-3days.json` shows the resulting data

## Limitations

- **Geographic scope**: focused on Taiwan; other destinations have limited data
- **Real-time information**: with web tools available, check current weather forecasts and closure notices and record the source and query date. Without them, mark those facts in `to_verify` and remind the user to check the 中央氣象署 forecast a few days before departure.
- **Bookings**: recommendations only; no reservations or ticket purchases
- **Budget**: no cost calculation beyond prices quoted from sources

## Best Practices

- Give the reason behind each recommendation (e.g., 「建議上午先去野柳，因為…」)
- Include practical details: parking, restrooms, accessibility, best photo spots
- Use place names as commonly used in Taiwan

## Tools and Resources

- Tourism, weather (中央氣象署), and transport (TDX, 高速公路 1968) data: [Taiwan Data Sources](references/taiwan-data-sources.md)
- Output specifications and JSON schema: [Output Formats](references/output-formats.md)
- Interaction strategies and scenarios: [Conversation Guide](references/conversation-guide.md)
