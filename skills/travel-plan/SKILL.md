---
name: travel-plan
description: 為台灣旅遊設計的智慧行程規劃技能。支援自由輸入必訪景點、自然語言討論行程順序、智能建議休息站與用餐地點，並可輸出 Markdown、Mobile HTML、JSON 三種格式。適用於個人旅遊規劃、團體行程討論。當使用者需要規劃台灣旅遊行程、安排景點順序、討論旅遊路線時使用此技能。
license: MIT
compatibility: Designed for Agent Skills platform. Works with LLMs capable of tool calling and conversational interaction. Requires access to Taiwan tourism open data APIs for best results.
metadata:
  author: travel-skills
  version: "1.0.0"
  tags: travel, taiwan, itinerary, planning, 旅遊, 行程規劃
---

# Travel Plan Agent Skill

## Overview

This skill helps users plan travel itineraries for Taiwan with intelligent conversation and flexible output formats. It supports:
- Natural language input for must-visit attractions
- Conversational discussion of itinerary order
- Smart recommendations for rest stops and dining
- Multiple output formats: Markdown, Mobile HTML, JSON

## When to Use

Use this skill when:
- User wants to plan a trip to Taiwan
- User needs help arranging the order of attractions
- User asks for rest stop or restaurant recommendations
- User requests travel itinerary in specific formats
- User wants to discuss and optimize travel plans

## Workflow

### Step 1: Collect Must-Visit Attractions

Gather all attractions the user must visit:
- Accept free-text input (e.g., "想去九份、野柳、淡水")
- Ask clarifying questions to identify all required destinations
- Confirm the list before proceeding

### Step 2: Confirm Trip Parameters

Clarify essential details:
- **Duration**: Number of days for the trip
- **Date/Season**: Specific dates or general time frame
- **Starting Point**: Where the user will depart from
- **Transportation**: Driving, public transport, or mixed

### Step 3: Discuss Itinerary Order

Engage in natural conversation about route optimization:
- Propose logical route based on geography
- Ask for user preferences on direction and pace
- Discuss rest stops, meal locations, and breaks
- Be flexible and responsive to user input

### Step 4: Generate Itinerary

Create a structured itinerary based on discussion:
- Organize by day, time slot, or logical segments
- Include travel time estimates between locations
- Suggest optimal visiting times for each attraction
- Add recommended rest stops and dining options

### Step 5: Output in Requested Format

Generate output in the format the user requests:
- **Markdown**: Standard formatted document
- **Mobile HTML**: Responsive, phone-friendly version
- **JSON**: Structured data for programmatic use

### Step 6: Iterate and Refine

Continue discussing and improving the itinerary:
- Accept user feedback and adjustments
- Re-generate outputs as needed
- Provide additional recommendations

## Input Guidelines

### Acceptable Input Formats

```markdown
# Free text examples:
"想去九份和野柳"
"我要去台南三天兩夜，必去赤崁樓和安平古堡"
"計畫去花蓮太魯閣，需要幫忙安排"
"從台北出發，往宜蘭方向三天兩夜"
```

### Required Information to Collect

1. **Must-visit attractions**: List of non-negotiable destinations
2. **Trip duration**: Number of days
3. **Approximate dates**: Month or specific dates
4. **Travel preferences**: Pace, priorities, restrictions

### Questions to Ask

- 「請問您想去哪些景點？」（Collect attractions）
- 「這次旅遊大概幾天？」（Confirm duration）
- 「有特定的日期嗎？還是只要確定天數就好？」（Dates）
- 「您偏好什麼樣的旅遊節奏？」（Pace preference）
- 「交通方式是自己開車還是大眾運輸？」（Transportation）

## Interaction Modes

### Conversational Discussion

Engage in natural dialogue about itinerary order:
- Propose routes based on geography
- Ask: 「由北到南還是反方向您覺得怎麼樣？」
- Discuss: 「這幾個點的距離都不近，要不要分兩天走？」
- Suggest: 「考慮到車程，我建議上午先去九份，下午再去野柳」

### Rest Stop Recommendations

Automatically suggest rest stops when:
- Travel time between destinations exceeds 1 hour
- User explicitly requests breaks
- Meal times approach (around 12:00 or 18:00)

Include in recommendations:
- Convenience stores
- Rest areas
- Local restaurants
- Scenic viewpoints for stretching

### Flexible Replanning

Always be ready to adjust:
- Change order based on user preference
- Add or remove attractions
- Shift time slots
- Recalculate routes

## Output Formats

### Markdown Output

Standard formatted document with:
- Trip overview (name, duration, dates)
- Day-by-day breakdown
- Time slots with attractions
- Rest stop and dining recommendations
- Travel tips and notes

### Mobile HTML Output

Responsive, phone-friendly version with:
- Single-column card-based layout
- Touch-friendly buttons
- Copy/share functionality
- Quick access to all days

### JSON Output

Structured data format with:
- Trip metadata
- Itinerary array with full details
- Location coordinates (if available)
- Time slots and durations

See [Output Formats](references/output-formats.md) for detailed specifications.

## Examples

### Example 1: Simple Day Trip

**User Input:**
```
「想去九份和野柳，一日遊怎麼安排？」
```

**Expected Workflow:**
1. Confirm all must-visit attractions
2. Ask about starting location and preferences
3. Discuss optimal order (e.g.,野柳→九份 or 九份→野柳)
4. Suggest rest stops based on route
5. Generate itinerary in all three formats

**Sample Output (Markdown):**
```markdown
# 台北海岸一日遊

## Day 1 - 2026/01/25

### 上午
| 時間 | 景點 | 說明 |
|------|------|------|
| 09:00 | 野柳地質公園 | 世界級地質景觀，建議停留 2 小時 |

### 中途
| 時間 | 項目 | 說明 |
|------|------|------|
| 12:00 | 瑞芳美食廣場 | 午餐推薦，多種選擇 |

### 下午
| 時間 | 景點 | 說明 |
|------|------|------|
| 14:00 | 九份老街 | 經典山城風情，建議停留 2-3 小時 |
```

---

### Example 2: Multi-Day Trip

**User Input:**
```
「我要去台南三天兩夜，必去景點：赤崁樓、安平古堡、奇美博物館、神農街。住宿訂在赤崁樓附近。」
```

**Expected Workflow:**
1. List all required attractions with locations
2. Group by geographic proximity
3. Create day-by-day breakdown
4. Consider hotel location for daily planning
5. Suggest restaurants and rest stops
6. Generate comprehensive itinerary

**Sample Output Structure:**
```markdown
# 台南文化美食之旅 - 三天兩夜

## Day 1: 赤崁樓與周邊
- 上午：赤崁樓歷史巡禮
- 中午：附近武廟肉圓午餐
- 下午：祀典武廟、大天后宮
- 傍晚：神農街散步 + 晚餐

## Day 2: 安平文化體驗
- 上午：安平古堡、安平樹屋
- 中午：安平老街美食
- 下午：億載金城
- 傍晚：安平運河夕陽

## Day 3: 奇美博物館與告別
- 上午：奇美博物館（建議早場）
- 中午：仁德交流道周邊午餐
- 下午：啟程返回
```

## Limitations

### Geographic Scope
- Primary focus on Taiwan destinations
- International destinations may have limited data

### Data Freshness
- Relies on Taiwan government open data
- Always verify current hours and closures before recommending

### Real-Time Information
- Cannot check live availability for reservations
- Cannot access real-time traffic or weather

### Booking Capabilities
- Does not make actual bookings
- Provides recommendations only

### Budget Planning
- Does not calculate costs
- Can provide rough time estimates only

## Best Practices

1. **Always confirm requirements first** before generating any itinerary
2. **Ask follow-up questions** when input is ambiguous
3. **Provide rationale** for recommendations (e.g., 「建議上午先去野柳因為...」)
4. **Be flexible** and ready to adjust based on user feedback
5. **Offer multiple options** when appropriate (e.g., 「有兩種走法...」)
6. **Include practical tips** like parking, restrooms, and best photo spots
7. **Use local terms** and names as commonly used in Taiwan

## Tools and Resources

This skill may use:
- Taiwan tourism open data APIs for attraction information
- Geographic knowledge for route planning
- General knowledge for recommendations

See [Taiwan Data Sources](references/taiwan-data-sources.md) for details on available data.

## See Also

- [Conversation Guide](references/conversation-guide.md) - Detailed interaction strategies
- [Output Formats](references/output-formats.md) - Format specifications
- [Taiwan Data Sources](references/taiwan-data-sources.md) - Data resources
