# Output Formats Specification

This document defines the three output formats supported by the Travel Plan agent: Markdown, Mobile HTML, and JSON.

## 1. Markdown Format

### Purpose
Standard formatted document for human readability, easy sharing, and printing.

### File Extension
`.md`

### Structure

```markdown
# [Trip Name]

---

## Day X: [Day Theme]

### 上午 (Morning)
| 時間 | 項目 | 說明 |
|------|------|------|
| HH:MM | 地點名稱 | 簡短說明 |

### 中途 (Midday)
| 時間 | 項目 | 說明 |
|------|------|------|
| HH:MM | 休息/用餐 | 簡短說明 |

### 下午 (Afternoon)
| 時間 | 項目 | 說明 |
|------|------|------|
| HH:MM | 地點名稱 | 簡短說明 |

---

## 旅遊注意事項 (Travel Tips)
- 提示項目 1
- 提示項目 2

---

*此行程由 Travel Plan Agent 產生*
```

### Styling Conventions
- `#` for main title
- `##` for day sections
- `###` for time period headers
- Tables for structured time slots
- Horizontal rules `---` for section separation

### Example Output

```markdown
# 台北海岸一日遊

---

## Day 1: 北海岸巡禮

### 上午 (Morning)
| 時間 | 景點 | 說明 |
|------|------|------|
| 09:00 | 野柳地質公園 | 世界級地質景觀，建議停留 2 小時 |
| 11:30 | 前往九份 | 車程約 50 分鐘 |

### 中途 (Midday)
| 時間 | 項目 | 說明 |
|------|------|------|
| 12:30 | 瑞芳美食廣場 | 午餐推薦，有多種選擇 |

### 下午 (Afternoon)
| 時間 | 景點 | 說明 |
|------|------|------|
| 14:00 | 九份老街 | 經典山城風情，建議停留 2-3 小時 |
| 17:00 | 賦歸 | - |

---

## 旅遊注意事項 (Travel Tips)
- 野柳天氣多變，建議攜帶雨具
- 九份老街假日人潮眾多，建議平日前往
- 停車位有限，建議使用大眾運輸

---

*此行程由 Travel Plan Agent 產生*
```

---

## 2. Mobile HTML Format

### Purpose
Responsive, phone-friendly version with touch-optimized UI.

### File Extension
`.html`

### Requirements
- Responsive meta tag for mobile viewport
- Touch-friendly button sizes (min 44px)
- Card-based layout for each day
- Easy copy/share functionality
- Works offline when saved

### Structure

```html
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>行程名稱</title>
    <style>
        /* Responsive CSS */
        :root {
            --primary: #FF6B6B;
            --secondary: #4ECDC4;
            --accent: #FFE66D;
            --background: #F7FFF7;
 --text: #2C           3E50;
        }
        body { font-family: system-ui, sans-serif; }
        .day-card { background: white; margin: 12px; border-radius: 12px; }
        .time-slot { padding: 12px; border-left: 4px solid var(--primary); }
    </style>
</head>
<body>
    <header style="background: var(--primary); color: white; padding: 16px;">
        <h1>行程名稱</h1>
    </header>
    <main>
        <div class="day-card">
            <h2>Day 1</h2>
            <div class="time-slot">
                <span class="time">09:00</span>
                <span class="spot">野柳地質公園</span>
            </div>
        </div>
    </main>
</body>
</html>
```

### Styling (Vibrant Color Scheme)

```css
/* Primary Colors */
--primary: #FF6B6B      /* Coral Red */
--secondary: #4ECDC4    /* Teal Green */
--accent: #FFE66D       /* Bright Yellow */
--background: #F7FFF7   /* Off White */
--text-dark: #2C3E50    /* Dark Blue Gray */
--text-light: #7F8C8D   /* Light Gray */

/* UI Elements */
.btn {
    background: var(--primary);
    color: white;
    border-radius: 8px;
    padding: 12px 24px;
}
.card {
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
```

### Example Output

```html
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>台北海岸一日遊</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header class="trip-header">
        <h1>台北海岸一日遊</h1>
        <p>2026/01/25 · 1天</p>
    </header>
    
    <main>
        <section class="day-section">
            <h2>Day 1</h2>
            
            <div class="time-card morning">
                <span class="time">09:00</span>
                <div class="spot-info">
                    <h3>野柳地質公園</h3>
                    <p>世界級地質景觀，建議停留 2 小時</p>
                </div>
            </div>
            
            <div class="rest-stop">
                <span class="time">12:00</span>
                <div class="spot-info">
                    <h3>瑞芳美食廣場</h3>
                    <p>午餐推薦</p>
                </div>
            </div>
            
            <div class="time-card afternoon">
                <span class="time">14:00</span>
                <div class="spot-info">
                    <h3>九份老街</h3>
                    <p>經典山城風情，建議停留 2-3 小時</p>
                </div>
            </div>
        </section>
        
        <section class="tips-section">
            <h2>旅遊注意事項</h2>
            <ul>
                <li>野柳天氣多變，建議攜帶雨具</li>
                <li>九份老街假日人潮眾多</li>
            </ul>
        </section>
    </main>
    
    <footer>
        <button class="btn-share">分享行程</button>
    </footer>
</body>
</html>
```

---

## 3. JSON Format

### Purpose
Structured data for programmatic use, storage, or further processing.

### File Extension
`.json`

### Schema

```json
{
  "meta": {
    "generated_at": "ISO8601 timestamp",
    "generator": "travel-plan-agent",
    "version": "string"
  },
  "trip": {
    "name": "string",
    "duration_days": "number",
    "date": "YYYY-MM-DD or YYYY/MM/DD",
    "starting_point": "string",
    "transportation": "string"
  },
  "itinerary": [
    {
      "day": "number",
      "date": "YYYY-MM-DD",
      "segments": [
        {
          "time": "HH:MM",
          "type": "attraction | break | travel | meal",
          "name": "string",
          "address": "string",
          "duration_minutes": "number",
          "coordinates": {
            "lat": "number",
            "lng": "number"
          },
          "notes": "string",
          "tips": ["string"]
        }
      ],
      "travel_notes": "string"
    }
  ],
  "summary": {
    "total_attractions": "number",
    "total_estimated_hours": "number",
    "rest_stops_recommended": "number",
    "notes": ["string"]
  }
}
```

### Type Values

| Type | Description |
|------|-------------|
| `attraction` | Must-visit tourist spot |
| `break` | Rest stop, rest area |
| `meal` | Restaurant or dining |
| `travel` | Transit between locations |
| `optional` | Nice-to-visit if time permits |

### Example Output

```json
{
  "meta": {
    "generated_at": "2026-01-25T10:30:00Z",
    "generator": "travel-plan-agent",
    "version": "1.0.0"
  },
  "trip": {
    "name": "台北海岸一日遊",
    "duration_days": 1,
    "date": "2026-01-25",
    "starting_point": "台北車站",
    "transportation": "自駕"
  },
  "itinerary": [
    {
      "day": 1,
      "date": "2026-01-25",
      "segments": [
        {
          "time": "09:00",
          "type": "travel",
          "name": "台北車站出發",
          "address": "台北市中正區北平西路3號",
          "duration_minutes": 15,
          "notes": "集合出發"
        },
        {
          "time": "09:30",
          "type": "attraction",
          "name": "野柳地質公園",
          "address": "新北市萬里區野柳里港東路167-1號",
          "duration_minutes": 150,
          "coordinates": {
            "lat": 25.2067,
            "lng": 121.6871
          },
          "notes": "女王頭、仙女鞋等奇岩怪石",
          "tips": ["建議上午參觀", "天氣炎熱時請多喝水"]
        },
        {
          "time": "12:30",
          "type": "meal",
          "name": "瑞芳美食廣場",
          "address": "新北市瑞芳區民生街",
          "duration_minutes": 60,
          "notes": "午餐選擇多元"
        },
        {
          "time": "14:00",
          "type": "attraction",
          "name": "九份老街",
          "address": "新北市瑞芳區基山街",
          "duration_minutes": 180,
          "coordinates": {
            "lat": 25.1086,
            "lng": 121.8465
          },
          "notes": "經典山城風情，芋圓、草仔粿推薦",
          "tips": ["建議平日前往", "傍晚可看夕陽"]
        }
      ],
      "travel_notes": "全程自駕，約 1.5 小時車程"
    }
  ],
  "summary": {
    "total_attractions": 2,
    "total_estimated_hours": 7,
    "rest_stops_recommended": 1,
    "notes": [
      "出發前請再次確認景點開放時間",
      "建議攜帶防曬用品及雨具"
    ]
  }
}
```

---

## Format Selection Guide

| Use Case | Recommended Format |
|----------|-------------------|
| Share via LINE/Email | Mobile HTML |
| Print or PDF export | Markdown |
| Import to apps (日曆, Notion) | JSON |
| Documentation存档 | Markdown |
| Programmatic processing | JSON |
| Quick phone viewing | Mobile HTML |

---

## Conversion Between Formats

All formats contain the same core data:
- Markdown: Human-readable text representation
- JSON: Structured data representation
- HTML: Visual/interactive representation

When user requests a specific format, convert from the internal data model to the requested format.

---

## Related Documentation

- See [Taiwan Data Sources](taiwan-data-sources.md) for data input
- See [Conversation Guide](conversation-guide.md) for presentation tips
