# Travel Skills

這是一個專門為 AI Agent 設計的旅遊技能庫 (Skill Library)。目前包含針對台灣旅遊優化的行程規劃技能，旨在透過 AI 協助使用者快速、專業地安排旅遊行程。

## 📂 技能列表 (Skills List)

### 1. 🗺️ Travel Plan (`skills/travel-plan`)
**專為台灣旅遊設計的智慧行程規劃技能。**

此技能讓 Agent 能夠像專業導遊一樣，從景點順序、交通時間到休息站建議，提供全方位的規劃服務。

- **✨ 功能亮點**：
  - **自然語言溝通**：支援用聊天的方式討論行程（例如：「不想太累、想晚點出門」）。
  - **智慧路線優化**：根據地理位置建議最順路的景點排序。
  - **休息站與餐飲建議**：自動判斷長途車程，建議適合的休息點（如便利商店、風景區）。
  - **多格式輸出**：
    - 📝 **Markdown**：適合電腦閱讀、列印或存檔。
    - 📱 **Mobile HTML**：專為手機設計的大字體、卡片式介面，方便旅途中即時查看。
    - ⚙️ **JSON**：結構化資料，便於程式串接或匯入其他工具。

- **🎯 適用場景**：
  - 週末家庭出遊規劃
  - 多日環島路線安排
  - 景點順序與交通時間估算

## 🏗️ 專案結構

```text
/home/kevin/Documents/RCodes/travel-skills/
├── skills/
│   └── travel-plan/              # [核心] 行程規劃技能
│       ├── SKILL.md              # 技能定義、Prompt 指令與工作流
│       ├── assets/               # 相關素材資源
│       ├── references/           # 參考文件
│       │   ├── output-formats.md # 輸出格式規範 (MD, HTML, JSON)
│       │   └── ...
│       └── scripts/              # 輔助腳本
├── pingtung-kenting-weekend-trip.md    # (範例) 產出的行程 Markdown
└── README.md                           # 專案說明文件
```

## 安裝方式 (Installation)

### 使用 Skill Linker (推薦)

您可以使用 [Skill Linker](https://github.com/raybird/skill-linker) 工具來自動偵測並安裝此專案中的技能到您的 Agent 環境中（支援 Mac, Linux, Windows）。

```bash
# 直接從 GitHub 安裝
npx skill-linker --from https://github.com/raybird/travel-skills

# 或是如果您已經下載到本地
npx skill-linker ./travel-skills
```

工具會自動偵測 `skills` 資料夾，並引導您選擇要安裝的技能（如 `travel-plan`）以及目標 Agent。

## �🚀 快速開始 (Quick Start)

載入此專案環境後，您即擁有 `travel-plan` 的能力。請嘗試對 Agent 說：

> 「我要規劃去台南和墾丁的三天兩夜行程，幫我安排順路的景點。」

或是：

> 「我明天要去花蓮太魯閣，幫我做一個手機好讀版的行程表。」

Agent 將會自動引用 `skills/travel-plan/SKILL.md` 中的指引與知識，為您生成最合適的行程。

## 📝 輸出範例

本專案包含實際生成的行程範例：
- [Markdown 行程表](./pingtung-kenting-weekend-trip.md)
- [手機版網頁行程表](./pingtung-kenting-weekend-trip.html)

---
*Travel Skills Project - Designed for Intelligent Travel Planning*
