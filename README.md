# Travel Skills

這是一個專門為 AI Agent 設計的旅遊技能庫 (Skill Library)。目前包含針對台灣旅遊優化的行程規劃技能，旨在透過 AI 協助使用者快速、專業地安排旅遊行程。

## 📂 技能列表 (Skills List)

### 1. 🗺️ Travel Plan (`skills/travel-plan`)
**專為台灣旅遊設計的智慧行程規劃技能。**

此技能讓 Agent 能夠像專業導遊一樣，從景點順序、交通時間到休息站建議，提供全方位的規劃服務。

- **✨ 功能亮點**：
  - **自然語言溝通**：支援用聊天的方式討論行程（例如：「不想太累、想晚點出門」）。
  - **同行成員需求**：記錄每位成員的興趣與體力、健康需求，並在每個行程點標出各自的亮點。
  - **固定時間點倒推**：有「幾點後才能出發」或「幾點前要回到家」時，從截止時間往回排，最後一天不壓線。
  - **排隊與等待緩衝**：預留買票排隊、等電梯、叫車、停車、入住寄放行李的時間。
  - **晴雨雙軌**：戶外行程附雨天備案與切換原因。
  - **查證來源**：營業時間、票價、天氣等資訊附來源與查詢日期，查不到的標示「待確認」。
  - **智慧路線優化**：根據地理位置建議順路排序，路線有多種選擇時列出時間、距離、舒適度的取捨。
  - **多格式輸出**：
    - 📝 **Markdown**：適合電腦閱讀、列印或存檔，含雨備欄位。
    - 📱 **Mobile HTML**：單一檔案、離線可開；Day 分頁切換、晴天／雨備一鍵切換、電子看板風格時刻、成員色標、大字級、Google Maps 膠囊按鈕。
    - ⚙️ **JSON**：結構化資料，便於程式串接或匯入其他工具。

- **🎯 適用場景**：
  - 週末家庭出遊規劃
  - 多日環島路線安排
  - 景點順序與交通時間估算
  - 依天氣或臨時行程變動調整既有行程

## 🏗️ 專案結構

```text
travel-skill/
├── skills/
│   └── travel-plan/                  # [核心] 行程規劃技能
│       ├── SKILL.md                  # 技能定義、工作流與規劃規則
│       ├── assets/                   # HTML 模板與樣式（產生時內嵌為單一檔案）
│       ├── examples/                 # 範例行程（皆為虛構）
│       │   ├── taipei-family-3days.json
│       │   ├── taipei-family-3days.html
│       │   ├── taipei-family-3days.md
│       │   └── pingtung-kenting-weekend-trip.md
│       ├── references/               # 參考文件
│       │   ├── conversation-guide.md # 對話策略與情境範例
│       │   ├── output-formats.md     # 輸出格式規範 (MD, HTML, JSON)
│       │   └── taiwan-data-sources.md# 觀光、天氣、交通資料來源
│       └── scripts/                  # 輸出腳本（需要 jq）
│           ├── format-json.sh
│           ├── format-html.sh
│           ├── format-markdown.sh
│           └── lib/
│               ├── common.sh
│               └── itinerary.jq
└── README.md                         # 專案說明文件
```

## 安裝方式 (Installation)

### 使用 Skill Linker (推薦)

您可以使用 [Skill Linker](https://github.com/raybird/skill-linker) 工具來自動偵測並安裝此專案中的技能到您的 Agent 環境中（支援 Mac, Linux, Windows）。

```bash
# 直接從 GitHub 安裝
npx skill-linker --from https://github.com/raybird/travel-skill

# 或是如果您已經下載到本地
npx skill-linker ./travel-skill
```

工具會自動偵測 `skills` 資料夾，並引導您選擇要安裝的技能（如 `travel-plan`）以及目標 Agent。

## 🚀 快速開始 (Quick Start)

載入此專案環境後，您即擁有 `travel-plan` 的能力。請嘗試對 Agent 說：

> 「我要規劃去台南和墾丁的三天兩夜行程，幫我安排順路的景點。」

或是：

> 「一家五口從台中去台北玩三天，最後一天傍晚要趕回來，幫我做一個手機好讀、有雨備的行程表。」

Agent 將會自動引用 `skills/travel-plan/SKILL.md` 中的指引與知識，為您生成最合適的行程。

## 📝 輸出範例

以下範例皆為虛構行程：

- [台北親子三日遊 JSON](./skills/travel-plan/examples/taipei-family-3days.json)
- [台北親子三日遊 手機版 HTML](./skills/travel-plan/examples/taipei-family-3days.html)
- [台北親子三日遊 Markdown](./skills/travel-plan/examples/taipei-family-3days.md)
- [屏東墾丁週末二日遊 Markdown](./skills/travel-plan/examples/pingtung-kenting-weekend-trip.md)

由行程 JSON 產生各格式（格式規範見 `skills/travel-plan/references/output-formats.md`，腳本需要安裝 [jq](https://jqlang.github.io/jq/)）：

```bash
skills/travel-plan/scripts/format-json.sh itinerary.json normalized.json
skills/travel-plan/scripts/format-html.sh normalized.json itinerary.html
skills/travel-plan/scripts/format-markdown.sh normalized.json itinerary.md
```

`format-json.sh` 會正規化資料並把檢查警告（時間格式、行程超過截止時間等）輸出到 stderr。

---
*Travel Skills Project - Designed for Intelligent Travel Planning*
