#!/bin/bash
# Travel Plan - HTML Output Formatter
# Renders assets/html-template.html with itinerary JSON (schema: references/output-formats.md)
# style.css is inlined so the output is a single file that works offline.

set -euo pipefail

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"
TEMPLATE_DIR="${3:-$(dirname "$0")/../assets}"

# Color codes
RED='\033[0;31m'
NC='\033[0m'

# Every value is HTML-escaped (@html) or JSON-encoded for <script> (js),
# and placeholders are replaced in a single pass so values are never re-scanned.
JQ_PROGRAM=$(cat << 'JQ'
def esc: tostring | @html;
def js: tojson | gsub("<"; "\\u003c");

def duration_text:
    if . == null then null
    elif . >= 60 then "\(. / 60 | floor) 小時" + (if . % 60 > 0 then " \(. % 60) 分" else "" end)
    else "\(.) 分鐘"
    end;

def period:
    ((.time // "") | split(":")[0] | tonumber? // 0) as $h
    | if $h >= 17 then "evening" elif $h >= 12 then "afternoon" else "morning" end;

def tag:
    {
        attraction: ["景點", "tag-attraction"],
        meal: ["用餐", "tag-meal"],
        break: ["休息", "tag-break"],
        travel: ["交通", "tag-travel"],
        optional: ["選配", "tag-optional"]
    }[.type // ""];

def segment:
    (if .type == "meal" or .type == "break" then "break" else period end) as $class
    | (.duration_minutes | duration_text) as $duration
    | tag as $tag
    | "            <div class=\"time-card \($class)\">\n"
    + "                <span class=\"time-label\">\(.time // "" | esc)</span>\n"
    + "                <div class=\"spot-info\">\n"
    + "                    <h3>\(.name // "" | esc)</h3>\n"
    + (if .notes then "                    <p>\(.notes | esc)</p>\n" else "" end)
    + (if (.tips | length) > 0 then "                    <p>\(.tips | join("・") | esc)</p>\n" else "" end)
    + (if .type == "travel" and $duration then
        "                    <span class=\"travel-time\">約 \($duration | esc)</span>\n"
      elif $tag then
        "                    <span class=\"spot-tag \($tag[1])\">\($tag[0])\(if $duration then " · 約 \($duration | esc)" else "" end)</span>\n"
      else "" end)
    + "                </div>\n"
    + "            </div>";

def day_section:
    ([.title, .date] | map(select(. != null and . != "") | esc) | join(" · ")) as $title
    | "        <section class=\"day-section\">\n"
    + "            <div class=\"day-header\">\n"
    + "                <span class=\"day-badge\">Day \(.day | esc)</span>\n"
    + "                <span class=\"day-title\">\($title)</span>\n"
    + "            </div>\n"
    + ([.segments[]? | segment] | join("\n"))
    + (if .travel_notes then "\n            <p class=\"travel-time\">\(.travel_notes | esc)</p>" else "" end)
    + "\n        </section>";

(.trip.name // "旅遊行程") as $name
| (.trip.date // "") as $date
| (.trip.duration_days // ([.itinerary[]?] | length | select(. > 0)) // 1) as $days
| (.summary.notes // [
    "出發前請再次確認景點開放時間",
    "建議攜帶防曬用品及雨具",
    "交通資訊僅供參考，實際路況可能不同"
  ]) as $tips
| {
    STYLES: $css,
    TRIP_NAME: ($name | esc),
    TRIP_NAME_JSON: ($name | js),
    DURATION: ("\($days)天" | esc),
    DATE: ($date | esc),
    DATE_JSON: ($date | js),
    ITINERARY_SECTIONS: (
        [.itinerary // [] | to_entries[] | .value + {day: (.value.day // (.key + 1))} | day_section]
        | join("\n\n") | sub("^\\s+"; "")
    ),
    TRAVEL_TIPS: ([$tips[] | "<li>\(esc)</li>"] | join("\n                "))
  } as $vars
| $tpl | gsub("\\{\\{(?<key>[A-Z_]+)\\}\\}"; $vars[.key] // "{{\(.key)}}")
JQ
)

# Usage information
usage() {
    echo "Usage: $0 [input.json] [output.html] [template_dir]"
    echo ""
    echo "Arguments:"
    echo "  input.json    Itinerary JSON file (default: stdin)"
    echo "  output.html   Output HTML file (default: stdout)"
    echo "  template_dir  Directory containing html-template.html and style.css (default: assets/)"
    echo ""
    echo "Input JSON follows the schema in references/output-formats.md:"
    echo '  {'
    echo '    "trip": { "name": "行程名稱", "duration_days": 2, "date": "2026-01-25" },'
    echo '    "itinerary": [ { "day": 1, "title": "主題", "segments": [ ... ] } ],'
    echo '    "summary": { "notes": ["提醒事項"] }'
    echo '  }'
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.html"
    echo "  $0 itinerary.json plan.html ./assets"
    echo "  cat itinerary.json | $0 > plan.html"
}

die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Main execution
main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    command -v jq &> /dev/null || die "jq is required (https://jqlang.github.io/jq/)"

    local template="$TEMPLATE_DIR/html-template.html"
    local stylesheet="$TEMPLATE_DIR/style.css"
    [[ -f "$template" ]] || die "template not found: $template"
    [[ -f "$stylesheet" ]] || die "stylesheet not found: $stylesheet"

    # Read input; with no file and no piped/redirected stdin, render an empty itinerary
    local input_data='{}'
    if [[ "$INPUT_FILE" != "/dev/stdin" ]]; then
        [[ -f "$INPUT_FILE" ]] || die "input file not found: $INPUT_FILE"
        input_data=$(cat "$INPUT_FILE")
    elif [[ -p /dev/stdin || -f /dev/stdin ]]; then
        input_data=$(cat)
    fi
    [[ -n "${input_data//[[:space:]]/}" ]] || input_data='{}'

    printf '%s' "$input_data" \
        | jq -j --rawfile tpl "$template" --rawfile css "$stylesheet" "$JQ_PROGRAM" \
        > "$OUTPUT_FILE"
}

main "$@"
