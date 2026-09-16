# Travel Skills

這是一個專門為 AI Agent 設計的旅遊技能庫（Skill Library）。目前核心技能 `travel-plan` 針對台灣旅遊規劃，重點不是只提供提示詞，而是提供一套可以被 Agent、CLI 與 CI 共用的可驗證執行契約。

## 🗺️ Travel Plan

`skills/travel-plan` 目前為 **v1.2.0**。

它把旅遊規劃拆成固定流程：

```text
INGEST → RESEARCH → PLAN → VALIDATE → RENDER → COMPLETE
```

核心設計：

- **互動模式**：可像一般旅遊顧問一樣自然討論需求。
- **Batch 模式**：可由另一個 Agent、workflow 或 CI 直接給 JSON request，不依賴人工追問。
- **Canonical Request Schema**：`schemas/request.schema.json`。
- **Canonical Itinerary Schema**：`schemas/itinerary.schema.json`。
- **單一資料來源**：Markdown、Mobile HTML、JSON 都由同一份 itinerary JSON 產生。
- **Deterministic normalization**：預設不偷偷寫入現在時間；同一輸入與 formatter 版本可得到相同 normalized JSON。
- **Strict validation**：final / batch 輸出可作為 CI publish gate。
- **Snapshot replay**：即時查證資料固定後，可以不重新上網就重播同一份行程。
- **Explicit assumptions / decisions**：batch default 與規劃選擇都可被追蹤，不靠隱藏假設。
- **來源與待確認**：營業時間、票價、天氣等外部資訊區分 confirmed evidence 與 `to_verify`。
- **家庭成員需求**：可針對每位成員記錄興趣、體力、行動需求與 segment highlights。
- **時間約束倒推**：支援 `depart_after` / `arrive_by`。
- **雨備與緩衝**：可記錄 queue、停車、叫車、入住與雨天替代方案。

## 📂 專案結構

```text
travel-skill/
├── .github/
│   └── workflows/
│       └── validate-travel-skill.yml
├── skills/
│   └── travel-plan/
│       ├── SKILL.md
│       ├── validate.sh
│       ├── schemas/
│       │   ├── request.schema.json
│       │   └── itinerary.schema.json
│       ├── assets/
│       │   ├── html-template.html
│       │   └── style.css
│       ├── examples/
│       │   ├── taipei-family-3days.json
│       │   ├── taipei-family-3days.html
│       │   ├── taipei-family-3days.md
│       │   └── pingtung-kenting-weekend-trip.md
│       ├── references/
│       │   ├── execution-contract.md
│       │   ├── conversation-guide.md
│       │   ├── output-formats.md
│       │   └── taiwan-data-sources.md
│       └── scripts/
│           ├── format-json.sh
│           ├── format-html.sh
│           ├── format-markdown.sh
│           └── lib/
│               ├── common.sh
│               └── itinerary.jq
└── README.md
```

## 安裝

### 使用 Skill Linker

```bash
npx skill-linker --from https://github.com/raybird/travel-skill
```

或已下載到本機：

```bash
npx skill-linker ./travel-skill
```

Skill Linker 會偵測 `skills` 目錄並讓你選擇要安裝到哪個 Agent。

## 🚀 互動使用

例如：

> 「一家五口從台中去台北玩三天，最後一天 17:30 前一定要回台中，幫我做有雨備的手機行程。」

Agent 會依 `SKILL.md` 與 execution contract 收集需求、查證資料、建立 canonical itinerary、驗證，再產生輸出。

## ⚙️ Reproducible Pipeline

### Draft

```bash
skills/travel-plan/scripts/format-json.sh \
  itinerary.json normalized.json
```

有 semantic 問題時會印 warning，但仍可繼續做互動草稿。

### Final / CI

```bash
skills/travel-plan/scripts/format-json.sh --strict \
  itinerary.json normalized.json

skills/travel-plan/scripts/format-html.sh \
  normalized.json itinerary.html

skills/travel-plan/scripts/format-markdown.sh \
  normalized.json itinerary.md
```

`--strict` 有 semantic 問題時會 exit `2`，並在驗證失敗時避免覆寫 publishable output。

### 固定 publication timestamp

如果需要 timestamp，又希望結果可 replay：

```bash
skills/travel-plan/scripts/format-json.sh --strict \
  --generated-at 2026-09-16T06:30:00Z \
  itinerary.json normalized.json
```

預設不會使用目前系統時間。`--stamp-now` 僅適合明確不要求 byte-reproducible 的發布流程。

## 🧪 驗證

```bash
bash skills/travel-plan/validate.sh
```

validator 會檢查：

- Skill / reference / schema 結構
- JSON schema 檔是否為合法 JSON
- golden example 是否通過 strict semantic validation
- 同一 canonical input 連跑兩次是否 byte-stable
- caller-controlled timestamp
- strict failure 是否阻止覆寫 output
- Markdown / HTML renderer 是否仍與 golden files 一致
- HTML escaping 與 unsafe URL 過濾

GitHub Actions 也會執行相同 validator。

## 即時資料與「可重複」的界線

天氣、營業時間、票價、交通與臨時休館本來就會改變，因此不能假裝「今天重新查網路」一定會得到與上次相同的結果。

本專案採用的界線是：

1. `live` research 可以取得最新資料；
2. 每個外部事實記錄來源與查證日期；
3. 一旦 canonical itinerary / evidence 固定，後面的 normalize、validate、render 必須 deterministic；
4. 要重播既有版本時使用 snapshot，不偷偷更新外部資料；
5. 要更新真實世界資訊時，視為新 revision，重新 research 並記錄 `changes`。

完整定義見 `skills/travel-plan/references/execution-contract.md`。

## 輸出範例

- `skills/travel-plan/examples/taipei-family-3days.json`
- `skills/travel-plan/examples/taipei-family-3days.html`
- `skills/travel-plan/examples/taipei-family-3days.md`
- `skills/travel-plan/examples/pingtung-kenting-weekend-trip.md`

---

*Travel Skills Project — executable, testable travel planning for AI Agents.*
