#!/bin/bash
# Travel Plan - Markdown Output Formatter
# Renders itinerary JSON (schema: references/output-formats.md) as a printable Markdown document

set -euo pipefail

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"

source "$(dirname "$0")/lib/common.sh"

JQ_PROGRAM=$(cat << 'JQ'
include "itinerary";

# Table cells: escape pipes, keep line breaks as <br>
def cell: tostring | gsub("\\|"; "\\|") | gsub("\n"; "<br>");

def bucket: ((.time | minutes_of_day) // 0) as $m | if $m < 11 * 60 then 0 elif $m < 14 * 60 then 1 else 2 end;

def bucket_title: ["上午 (Morning)", "中途 (Midday)", "下午 (Afternoon)"][.];

def transit_text:
    .transit as $transit
    | select($transit)
    | [
        ($transit.mode | select(.) | mode_label),
        ([($transit.lines // [])[] | line_name] | select(length > 0) | join("→")),
        ($transit.duration_minutes | duration_text | select(.) | "約 \(.)"),
        $transit.summary,
        ($transit.call_at | select(.) | "\(.) 叫車")
      ]
    | map(select(present)) | join("｜");

def details($travelers):
    . as $segment
    | [
        .notes,
        (transit_text),
        ((.tips // []) | select(length > 0) | "・" + join("<br>・")),
        (.buffer_minutes | duration_text | select(.) | "⏳ 已預留 \(.)排隊／等候\(if $segment.buffer_notes then "：\($segment.buffer_notes)" else "" end)"),
        ($travelers[] | select($segment.highlights[.id]? != null) | "\(member_label)：\($segment.highlights[.id])"),
        (.to_verify | select(present) | "⚠️ 待確認：\(.)"),
        (.reason | select(present) | "💡 切換原因：\(.)")
      ]
    | map(select(present)) | join("\n");

def segment_row($travelers; $with_rain):
    [
        (.time // ""),
        ((type_tag | select(.) | "\(.[0])｜") // "") + (.name // ""),
        details($travelers)
    ]
    + (if $with_rain then
        [ .rain_plan | if . then "**\(.name // "")**" + ([details($travelers)] | map(select(present) | "\n" + .) | join("")) else "—" end ]
       else [] end)
    | map(cell) | "| " + join(" | ") + " |";

def day_section($trip):
    . as $day
    | ([.segments[] | select(.rain_plan)] | length > 0) as $with_rain
    | [
        "## Day \(.day): \(.title // "Day \(.day)")\(if .date then " · \(.date | short_date)" else "" end)",
        "",
        (.weather | select(.) | "> 🌦️ \(.summary // "")\(if .temperature then " · \(.temperature)" else "" end)\(if .rain_chance != null then " · 降雨 \(.rain_chance)%" else "" end)\(if .source then "（\(.source)\(if .checked_at then "，\(.checked_at) 查詢" else "" end)）" else "" end)\n"),
        ($trip.changes[] | select(.day == $day.day) | "> ✅ **修正：\(.title // "")**\(if .detail then " — \(.detail)" else "" end)\n"),
        ($trip.constraints[] | select(.day == $day.day) | "> ⏰ **固定時間：\(.time // "") \(constraint_label)**\(if .description then " — \(.description)" else "" end)\n"),
        (
            .segments | group_by(bucket)[]
            | "### \(.[0] | bucket | bucket_title)",
              "| 時間 | 項目 | 說明 |\(if $with_rain then " ⛈️ 雨備 |" else "" end)",
              "|------|------|------|\(if $with_rain then "------|" else "" end)",
              (.[] | segment_row($trip.travelers; $with_rain)),
              ""
        ),
        (.travel_notes | select(present) | "交通說明：\(.)\n"),
        (
            [.segments[] | (., .rain_plan // empty) | (.sources // [])[] | select(.url | is_safe_url)]
            | unique_by(.url)
            | select(length > 0)
            | "**資料來源**", (.[] | "- [\(.title // .url)](\(.url))\(if .checked_at then "（\(.checked_at) 查證）" else "" end)"), ""
        ),
        "---",
        ""
      ]
    | join("\n");

normalize
| . as $trip
| (.summary.notes // [
    "出發前請再次確認景點開放時間",
    "建議攜帶防曬用品及雨具",
    "交通資訊僅供參考，實際路況可能不同",
    "餐廳建議可事先訂位以確保有位"
  ]) as $tips
| [
    "# \(.trip.name)",
    "",
    "> " + ([
        "\(.trip.duration_days)天",
        (.trip.date | select(present) | short_date),
        (.trip.starting_point | select(present) | "\(.)出發"),
        (.trip.transportation | select(present))
      ] | join(" · ")),
    "",
    (select((.travelers | length) > 0)
        | "## 同行成員", "",
          "| 成員 | 說明 | 興趣 | 需要留意 |",
          "|------|------|------|------|",
          (.travelers[] | [member_label, (.profile // ""), ((.interests // []) | join("、")), ((.needs // []) | join("、"))] | map(cell) | "| " + join(" | ") + " |"),
          ""),
    (select((.lodging | length) > 0)
        | "## 住宿", "",
          (.lodging[]
            | "- **\(.name // "")**\(if (.nights // []) | length > 0 then "（第 \(.nights | map(tostring) | join("、")) 晚）" else "" end)"
              + ([(.check_in | select(.) | "入住 \(.)"), (.check_out | select(.) | "退房 \(.)")] | if length > 0 then "　" + join("／") else "" end),
              (.address | select(present) | "  - 地址：\(.)"),
              (.parking | select(present) | "  - 停車：\(.)"),
              ((.notes // [])[] | "  - \(.)")),
          ""),
    (select((.constraints | length) > 0)
        | "## 固定時間點", "",
          (.constraints[] | "- Day \(.day) \(.time // "") \(constraint_label)\(if .description then "：\(.description)" else "" end)"),
          ""),
    (select([.changes[] | select(.day == null)] | length > 0)
        | "## 修正重點", "",
          (.changes[] | select(.day == null) | "- ✅ **\(.title // "")**\(if .detail then "：\(.detail)" else "" end)"),
          ""),
    "---",
    "",
    (.itinerary[] | day_section($trip)),
    "## 旅遊注意事項 (Travel Tips)",
    "",
    ($tips[] | "- \(.)"),
    "",
    "---",
    "",
    "*此行程由 Travel Plan Agent 產生*",
    ""
  ]
| join("\n")
JQ
)

usage() {
    echo "Usage: $0 [input.json] [output.md]"
    echo ""
    echo "Arguments:"
    echo "  input.json   Itinerary JSON file (default: stdin)"
    echo "  output.md    Output Markdown file (default: stdout)"
    echo ""
    echo "Input JSON follows the schema in references/output-formats.md."
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.md"
    echo "  cat itinerary.json | $0 > plan.md"
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    require_jq

    local input_data
    input_data=$(read_input "$INPUT_FILE")

    printf '%s' "$input_data" | itinerary_jq -j "$JQ_PROGRAM" > "$OUTPUT_FILE"
}

main "$@"
