#!/bin/bash
# Travel Plan - HTML Output Formatter
# Renders assets/html-template.html with itinerary JSON (schema: references/output-formats.md)
# style.css is inlined so the output is a single file that works offline.

set -euo pipefail

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"
TEMPLATE_DIR="${3:-$(dirname "$0")/../assets}"

source "$(dirname "$0")/lib/common.sh"

# Every value is HTML-escaped (esc) or JSON-encoded for <script> (js),
# and placeholders are replaced in a single pass so values are never re-scanned.
JQ_PROGRAM=$(cat << 'JQ'
include "itinerary";

def board($time): "<span class=\"board-time\">\($time | esc)</span>";

def lines_html: map(select(present)) | join("\n");

def link($href; $class; $label): "<a class=\"\($class)\" href=\"\($href | esc)\" target=\"_blank\" rel=\"noopener\">\($label)</a>";

def member_chip: "<span class=\"member-chip\">\(member_label | esc)</span>";

def transit_html:
    .transit as $transit
    | if $transit == null then empty else
        "<div class=\"transit\">"
        + "<div class=\"transit-head\">"
        + (if $transit.mode then "<span class=\"transit-mode\">\($transit.mode | mode_label | esc)</span>" else "" end)
        + ([($transit.lines // [])[] | "<span class=\"line line-\(line_code)\">\(line_name | esc)</span>"] | join(""))
        + (if $transit.duration_minutes then "<span class=\"duration\">約 \($transit.duration_minutes | duration_text | esc)</span>" else "" end)
        + "</div>"
        + (if $transit.summary then "<p>\($transit.summary | esc)</p>" else "" end)
        + (if $transit.call_at then "<p class=\"call-at\">🚕 \(board($transit.call_at)) 叫車</p>" else "" end)
        + "</div>"
      end;

def highlights_html($travelers):
    (.highlights // {}) as $highlights
    | if ($highlights | length) == 0 then empty else
        "<ul class=\"highlights\">"
        + ([$travelers[] | select($highlights[.id] != null)
            | "<li class=\"member-\(.color | esc)\">\(member_chip)<span>\($highlights[.id] | esc)</span></li>"] | join(""))
        + "</ul>"
      end;

def links_html:
    [
        (map_url_for | link(.; "map-btn"; "📍 Google Maps")),
        (directions_url_for | link(.; "map-btn map-btn-route"; "🧭 路線導航")),
        ((.sources // [])[] | select(.url | is_safe_url)
            | link(.url; "source-link"; "🔗 \(.title // "資料來源" | esc)\(if .checked_at then "（\(.checked_at | esc) 查證）" else "" end)"))
    ]
    | if length > 0 then "<div class=\"links\">\(join(""))</div>" else empty end;

def segment_body($travelers; $badge):
    type_tag as $tag
    | [
        "<div class=\"segment-head\">"
            + (if .time then board(.time) else "" end)
            + (if $tag then "<span class=\"spot-tag \($tag[1])\">\($tag[0])</span>" else "" end)
            + (if .duration_minutes then "<span class=\"duration\">約 \(.duration_minutes | duration_text | esc)</span>" else "" end)
            + $badge
            + "</div>",
        "<h3>\(.name // "" | esc)</h3>",
        transit_html,
        (if .notes then "<p class=\"notes\">\(.notes | esc)</p>" else empty end),
        (if (.tips // []) | length > 0 then "<ul class=\"tips\">\([.tips[] | "<li>\(esc)</li>"] | join(""))</ul>" else empty end),
        (if .buffer_minutes then
            "<p class=\"buffer\">⏳ 已預留 \(.buffer_minutes | duration_text | esc)排隊／等候\(if .buffer_notes then "：\(.buffer_notes | esc)" else "" end)</p>"
         else empty end),
        highlights_html($travelers),
        (if .to_verify then "<p class=\"verify\">⚠️ 待確認：\(.to_verify | esc)</p>" else empty end),
        (if .reason then "<p class=\"plan-reason\">💡 切換原因：\(.reason | esc)</p>" else empty end),
        links_html
      ]
    | lines_html;

def segment_html($travelers):
    . as $segment
    | (if .type == "meal" or .type == "break" then "break" else period end) as $class
    | if .rain_plan then
        "<article class=\"segment \($class) has-rain\">\n"
        + "<div class=\"plan plan-sun\">\n"
        + segment_body($travelers; "<span class=\"badge badge-rain\">有雨備</span>")
        + "\n</div>\n<div class=\"plan plan-rain\">\n"
        + (.rain_plan | .time //= $segment.time | .type //= $segment.type
            | segment_body($travelers; "<span class=\"badge badge-rain-on\">⛈️ 雨備</span>"))
        + "\n</div>\n</article>"
      else
        "<article class=\"segment \($class)\">\n\(segment_body($travelers; ""))\n</article>"
      end;

def change_html:
    "<div class=\"callout callout-fix\"><span class=\"callout-title\">✅ 修正</span>"
    + "<p><strong>\(.title // "" | esc)</strong></p>"
    + (if .detail then "<p>\(.detail | esc)</p>" else "" end)
    + "</div>";

def constraint_html:
    "<div class=\"callout callout-time\"><span class=\"callout-title\">⏰ 固定時間</span>"
    + "<p>\(board(.time // "")) \(constraint_label)\(if .description then "｜\(.description | esc)" else "" end)</p></div>";

def weather_html:
    .weather as $weather
    | if $weather == null then empty else
        "<div class=\"weather\">"
        + "<span class=\"weather-summary\">🌦️ \($weather.summary // "" | esc)</span>"
        + (if $weather.temperature then "<span>\($weather.temperature | esc)</span>" else "" end)
        + (if $weather.rain_chance != null then "<span>降雨 \($weather.rain_chance | esc)%</span>" else "" end)
        + (if $weather.source then "<small>來源：\($weather.source | esc)\(if $weather.checked_at then "（\($weather.checked_at | esc) 查詢）" else "" end)</small>" else "" end)
        + "</div>"
      end;

def day_panel($trip):
    . as $day
    | [
        "<section class=\"day-panel\" id=\"day-\(.day | esc)\" role=\"tabpanel\" aria-labelledby=\"tab-day-\(.day | esc)\">",
        "<div class=\"day-header\"><span class=\"day-badge\">Day \(.day | esc)</span>"
            + "<h2 class=\"day-title\">\(.title // "Day \(.day)" | esc)</h2>"
            + (if .date then "<span class=\"day-date\">\(.date | short_date | esc)</span>" else "" end)
            + "</div>",
        weather_html,
        ($trip.changes[] | select(.day == $day.day) | change_html),
        ($trip.constraints[] | select(.day == $day.day) | constraint_html),
        (.segments[] | segment_html($trip.travelers)),
        (if .travel_notes then "<p class=\"travel-time\">🚗 \(.travel_notes | esc)</p>" else empty end),
        "</section>"
      ]
    | lines_html;

def day_tab:
    "<button type=\"button\" class=\"day-tab\" role=\"tab\" id=\"tab-day-\(.day | esc)\" data-target=\"day-\(.day | esc)\" aria-controls=\"day-\(.day | esc)\">"
    + "<span>Day \(.day | esc)</span>"
    + (if .date then "<small>\(.date | tab_date | esc)</small>" else "" end)
    + "</button>";

def overview_html($trip):
    [
        ($trip.changes[] | select(.day == null) | change_html),
        (if ($trip.travelers | length) > 0 then
            "<section class=\"info-card\"><h2>👨‍👩‍👧 同行成員</h2><ul class=\"traveler-list\">"
            + ([$trip.travelers[]
                | "<li class=\"member-\(.color | esc)\">\(member_chip)"
                  + (if .profile then "<p>\(.profile | esc)</p>" else "" end)
                  + (if (.interests // []) | length > 0 then "<p>興趣：\(.interests | join("、") | esc)</p>" else "" end)
                  + (if (.needs // []) | length > 0 then "<p>需要留意：\(.needs | join("、") | esc)</p>" else "" end)
                  + "</li>"] | join(""))
            + "</ul></section>"
         else empty end),
        (if ($trip.lodging | length) > 0 then
            "<section class=\"info-card\"><h2>🏨 住宿</h2>"
            + ([$trip.lodging[]
                | "<article class=\"lodging\"><h3>\(.name // "" | esc)</h3>"
                  + (if (.nights // []) | length > 0 then "<p>第 \(.nights | map(tostring) | join("、") | esc) 晚</p>" else "" end)
                  + (if .check_in or .check_out then
                        "<p>" + ([(.check_in | select(.) | "入住 \(board(.))"), (.check_out | select(.) | "退房 \(board(.))")] | join("　")) + "</p>"
                     else "" end)
                  + (if .address then "<p>📍 \(.address | esc)</p>" else "" end)
                  + (if .parking then "<p>🅿️ \(.parking | esc)</p>" else "" end)
                  + (if (.notes // []) | length > 0 then "<ul>\([.notes[] | "<li>\(esc)</li>"] | join(""))</ul>" else "" end)
                  + ([links_html] | join(""))
                  + "</article>"] | join(""))
            + "</section>"
         else empty end),
        (if ($trip.constraints | length) > 0 then
            "<section class=\"info-card\"><h2>⏰ 固定時間點</h2><ul class=\"constraint-list\">"
            + ([$trip.constraints[]
                | "<li><span class=\"day-badge\">Day \(.day | esc)</span>\(board(.time // "")) \(constraint_label)\(if .description then "｜\(.description | esc)" else "" end)</li>"] | join(""))
            + "</ul></section>"
         else empty end)
    ]
    | lines_html;

normalize
| . as $trip
| (.summary.notes // [
    "出發前請再次確認景點開放時間",
    "建議攜帶防曬用品及雨具",
    "交通資訊僅供參考，實際路況可能不同"
  ]) as $tips
| {
    STYLES: $css,
    TRIP_NAME: (.trip.name | esc),
    TRIP_NAME_JSON: (.trip.name | js),
    DATE_JSON: (.trip.date // "" | js),
    TRIP_META: (
        [
            "\(.trip.duration_days)天",
            (.trip.date | select(present) | short_date),
            (.trip.starting_point | select(present) | "\(.)出發"),
            (.trip.transportation | select(present))
        ] | join(" · ") | esc
    ),
    TRAVELER_LEGEND: (
        if (.travelers | length) > 0 then
            "<ul class=\"legend\">\([.travelers[] | "<li class=\"member-\(.color | esc)\">\(member_chip)</li>"] | join(""))</ul>"
        else "" end
    ),
    DAY_TABS: (
        [(.itinerary[] | day_tab),
         "<button type=\"button\" class=\"day-tab\" role=\"tab\" id=\"tab-info\" data-target=\"info\" aria-controls=\"info\"><span>須知</span><small>住宿・提醒</small></button>"]
        | join("\n")
    ),
    PLAN_TOGGLE: (
        if has_rain_plans then
            "<div class=\"plan-toggle\" role=\"group\" aria-label=\"晴天或雨備方案\">"
            + "<button type=\"button\" class=\"plan-btn\" data-plan=\"sun\" aria-pressed=\"true\">☀️ 晴天</button>"
            + "<button type=\"button\" class=\"plan-btn\" data-plan=\"rain\" aria-pressed=\"false\">⛈️ 雨備</button>"
            + "</div>"
        else "" end
    ),
    DAY_PANELS: ([.itinerary[] | day_panel($trip)] | join("\n\n")),
    OVERVIEW: overview_html($trip),
    TRAVEL_TIPS: ([$tips[] | "<li>\(esc)</li>"] | join("\n"))
  } as $vars
| $tpl | gsub("\\{\\{(?<key>[A-Z_]+)\\}\\}"; $vars[.key] // "{{\(.key)}}")
JQ
)

usage() {
    echo "Usage: $0 [input.json] [output.html] [template_dir]"
    echo ""
    echo "Arguments:"
    echo "  input.json    Itinerary JSON file (default: stdin)"
    echo "  output.html   Output HTML file (default: stdout)"
    echo "  template_dir  Directory containing html-template.html and style.css (default: assets/)"
    echo ""
    echo "Input JSON follows the schema in references/output-formats.md."
    echo "Run format-json.sh first to see warnings about the itinerary."
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.html"
    echo "  $0 itinerary.json plan.html ./assets"
    echo "  cat itinerary.json | $0 > plan.html"
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    require_jq

    local template="$TEMPLATE_DIR/html-template.html"
    local stylesheet="$TEMPLATE_DIR/style.css"
    [[ -f "$template" ]] || die "template not found: $template"
    [[ -f "$stylesheet" ]] || die "stylesheet not found: $stylesheet"

    local input_data
    input_data=$(read_input "$INPUT_FILE")

    printf '%s' "$input_data" \
        | itinerary_jq -j --rawfile tpl "$template" --rawfile css "$stylesheet" "$JQ_PROGRAM" \
        > "$OUTPUT_FILE"
}

main "$@"
