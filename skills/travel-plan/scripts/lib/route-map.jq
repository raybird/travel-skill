# Travel Plan - route map (路線圖) layout for the Mobile HTML.
# One dashed lane per day, one node per segment, edges labelled with the transit
# into the next stop. A day wider than rm_max_width continues on the next row, so
# the diagram fits the page width and never scrolls sideways. Coordinates are computed here from estimated text widths so
# the SVG is deterministic and needs no layout code in the browser.
# Loaded by format-html.sh after "itinerary"; uses esc / type_tag / mode_label / duration_text.

include "itinerary";

# ---- geometry -------------------------------------------------------------

def rm_lane_gap: 14;
def rm_top: 14;
def rm_left: 26;
def rm_node_h: 70;
def rm_node_min: 120;
def rm_node_max: 232;
def rm_pad: 13;
def rm_max_width: 1100;
def rm_head_h: 36;
def rm_row_gap: 46;

# Approximate text width in em: CJK and emoji ≈ 1, Latin ≈ 0.6, joiners/selectors 0
def rm_units:
    explode
    | map(
        if . == 8205 or (. >= 65024 and . <= 65039) then 0
        elif . < 128 then 0.6
        elif . < 11904 then 0.7
        elif . >= 127744 then 1.25
        else 1
        end)
    | add // 0;

def rm_clip($max):
    if rm_units <= $max then .
    else . as $s
        | ([range($s | length; 0; -1) | $s[0:.] | select(rm_units <= $max - 1)] | first // "") + "…"
    end;

def rm_name_max: (rm_node_max - 2 * rm_pad) / 14;

# ---- per-variant content --------------------------------------------------

def rm_mode_class:
    if . == null then "plain"
    elif IN("mrt", "bus", "train", "hsr") then "transit"
    elif . == "walk" then "walk"
    else "drive"
    end;

def rm_sub:
    [(type_tag | select(.) | .[0]), (.duration_minutes | duration_text | select(.) | "約 \(.)")] | join(" · ");

# Edge label lines: [mode, duration], either may be missing
def rm_edge_lines:
    [(.transit.mode | select(.) | mode_label), (.transit.duration_minutes | duration_text | select(.) | sub(" 分鐘$"; " 分"))];

# The variants a segment renders as: [sun] or [sun, rain]
def rm_variants:
    . as $segment
    | [{ plan: (if .rain_plan then "sun" else null end) } + $segment]
      + (if .rain_plan then
            [{ plan: "rain" } + (.rain_plan | .time //= $segment.time | .type //= $segment.type)]
         else [] end);

def rm_node_width:
    [rm_variants[]
        | ((.name // "") | rm_clip(rm_name_max) | rm_units) * 14,
          (rm_sub | rm_units) * 11.5,
          50 + ([(.highlights // {}) | length, 6] | min) * 11 + (if .plan then 52 else 0 end)]
    | max + 2 * rm_pad
    | ceil
    | if . < rm_node_min then rm_node_min elif . > rm_node_max then rm_node_max else . end;

def rm_edge_gap:
    ([rm_variants[] | rm_edge_lines[] | rm_units] | max // 0) as $units
    | if $units == 0 then 44 else ($units * 11 + 22 | ceil | if . > 160 then 160 elif . < 44 then 44 else . end) end;

# ---- layout ---------------------------------------------------------------

def rm_lane_label:
    . as $day
    | [
        "\(if .day < 10 then "0" else "" end)\(.day) / Day \(.day)",
        (.title | select(present)),
        (.date | select(present) | short_date)
      ]
    | join(" · ");

def rm_label_max: (rm_max_width - 2 * rm_left) / 12;

def rm_row_y($row): rm_head_h + $row * (rm_node_h + rm_row_gap);

# [{day, top, height, label, segments:[{seg, id, x, w, gap, row}]}]; a node that
# would cross rm_max_width starts a new row at the left edge.
def rm_layout($constraints):
    [.itinerary[]
        | . as $day
        | ([$constraints[] | select(.day == $day.day) | "⏰ \(.time // "") \(constraint_label)"] | join("　")) as $constraint_text
        | ([.segments | to_entries[] | { seg: .value, id: "d\($day.day)-\(.key + 1)", w: (.value | rm_node_width), gap: (.value | rm_edge_gap) }]
            | reduce .[] as $node ({ x: rm_left, row: 0, out: [] };
                (if (.out | length) == 0 then { x: rm_left, row: 0 }
                 elif .x + $node.gap + $node.w > rm_max_width - rm_left then { x: rm_left, row: (.row + 1) }
                 else { x: (.x + $node.gap), row: .row } end) as $at
                | { x: ($at.x + $node.w), row: $at.row, out: (.out + [$node + $at]) })
            | .out) as $segments
        | {
            day: .day,
            label: (rm_lane_label + (if $constraint_text != "" then "｜\($constraint_text)" else "" end) | rm_clip(rm_label_max)),
            segments: $segments,
            height: (rm_row_y(([$segments[].row] | max // 0)) + rm_node_h + 12)
          }]
    | reduce .[] as $lane ({ top: rm_top, out: [] };
        { top: (.top + $lane.height + rm_lane_gap), out: (.out + [$lane + { top: .top }]) })
    | .out;

def rm_canvas_width($lanes):
    [$lanes[]
        | (.segments[] | .x + .w),
          (.label | rm_units) * 12 + rm_left]
    | (max // 0) + rm_left
    | ceil
    | if . < 320 then 320 else . end;

# ---- SVG ------------------------------------------------------------------

def rm_text($x; $y; $class; $text): "<text x=\"\($x)\" y=\"\($y)\" class=\"\($class)\">\($text | esc)</text>";

def rm_dots($travelers; $x; $y):
    (.highlights // {}) as $highlights
    | [$travelers[] | select($highlights[.id] != null) | .color] as $colors
    | [range(0; [$colors | length, 6] | min)
        | "<circle class=\"rm-dot member-\($colors[.] | esc)\" cx=\"\($x + . * 11)\" cy=\"\($y)\" r=\"4\"/>"]
    | join("");

def rm_node_variant($x; $y; $w; $travelers):
    [
        "<rect class=\"rm-box\" x=\"\($x)\" y=\"\($y)\" width=\"\($w)\" height=\"\(rm_node_h)\" rx=\"10\"/>",
        (if .time then rm_text($x + rm_pad; $y + 20; "rm-time"; .time) else empty end),
        (if .plan == "sun" then "<text x=\"\($x + $w - rm_pad)\" y=\"\($y + 20)\" class=\"rm-flag\" text-anchor=\"end\">有雨備</text>"
         elif .plan == "rain" then "<text x=\"\($x + $w - rm_pad)\" y=\"\($y + 20)\" class=\"rm-flag rm-flag-rain\" text-anchor=\"end\">⛈️ 雨備</text>"
         else empty end),
        rm_text($x + rm_pad; $y + 42; "rm-name"; (.name // "") | rm_clip(rm_name_max)),
        rm_text($x + rm_pad; $y + 60; "rm-sub"; rm_sub),
        rm_dots($travelers; $x + rm_pad + 50; $y + 16)
    ]
    | join("");

def rm_aria:
    [rm_variants[]
        | (if .plan == "rain" then "雨備：" else "" end)
          + ([.time, .name, (rm_sub | select(present))] | map(select(present)) | join("，"))]
    | join("；");

def rm_node($y; $travelers):
    .seg as $segment
    | .x as $x | .w as $w
    | "<g class=\"rm-node k-\($segment.type // "attraction" | esc)\(if $segment.rain_plan then " has-rain" else "" end)\" data-seg=\"\(.id)\" tabindex=\"0\" role=\"button\" aria-pressed=\"false\" aria-label=\"\($segment | rm_aria | esc)\">"
      + "<title>\($segment | rm_aria | esc)</title>"
      + ([$segment | rm_variants[]
            | if .plan then
                "<g class=\"rplan-\(.plan)\">\(rm_node_variant($x; $y; $w; $travelers))</g>"
              else rm_node_variant($x; $y; $w; $travelers) end] | join(""))
      + "</g>";

# Same row: a straight arrow with the label above it. Next row: down from the
# previous stop, back along the row gap, down into the stop, label on the bend.
def rm_edge($from; $to; $top):
    (.transit.mode | rm_mode_class) as $mode
    | rm_edge_lines as $lines
    | ($top + rm_row_y($from.row)) as $y1
    | ($top + rm_row_y($to.row)) as $y2
    | (if $from.row == $to.row then
        ($y1 + rm_node_h / 2) as $y
        | { d: "M\($from.x + $from.w),\($y) H\($to.x - 3)",
            labels: [$lines | to_entries[]
                | { x: (($from.x + $from.w + $to.x) / 2), y: ($y - 7 - (($lines | length) - 1 - .key) * 13), text: .value }] }
       else
        ($from.x + $from.w / 2) as $fx
        | ($to.x + $to.w / 2) as $tx
        | ($y1 + rm_node_h + rm_row_gap / 2) as $mid
        | { d: "M\($fx),\($y1 + rm_node_h) V\($mid) H\($tx) V\($y2 - 3)",
            labels: (if ($lines | length) > 0 then [{ x: (($fx + $tx) / 2), y: ($mid + 4), text: ($lines | join(" · ")), halo: true }] else [] end) }
       end) as $geom
    | "<path class=\"rm-edge rm-\($mode)\" d=\"\($geom.d)\" marker-end=\"url(#rm-arrow-\($mode))\"/>"
      + "<path class=\"rm-flow rm-\($mode)\" d=\"\($geom.d)\"/>"
      + ([$geom.labels[]
            | (if .halo then
                ((.text | rm_units) * 11 + 12 | ceil) as $bw
                | "<rect class=\"rm-label-bg\" x=\"\(.x - $bw / 2)\" y=\"\(.y - 12)\" width=\"\($bw)\" height=\"16\" rx=\"8\"/>"
               else "" end)
              + "<text class=\"rm-edge-label\" x=\"\(.x)\" y=\"\(.y)\" text-anchor=\"middle\">\(.text | esc)</text>"]
         | join(""));

def rm_edges($prev; $top):
    .seg as $segment
    | . as $node
    | ($segment | rm_variants) as $variants
    | if ($variants | length) > 1 and ($segment.rain_plan.transit != null) then
        [$variants[] | "<g class=\"rplan-\(.plan)\">\(rm_edge($prev; $node; $top))</g>"] | join("")
      else $segment | rm_edge($prev; $node; $top)
      end;

def rm_marker($mode):
    "<marker id=\"rm-arrow-\($mode)\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\">"
    + "<path class=\"rm-head rm-\($mode)\" d=\"M0,0 L8,4 L0,8 z\"/></marker>";

def route_map_svg($trip):
    rm_layout($trip.constraints) as $lanes
    | rm_canvas_width($lanes) as $width
    | ((($lanes | last | select(.) | .top + .height) // rm_top) + rm_top) as $height
    | "<svg class=\"rm-svg\" viewBox=\"0 0 \($width) \($height)\" width=\"\($width)\" height=\"\($height)\" role=\"group\" aria-label=\"每日路線圖\">"
      + "<defs>\(["drive", "transit", "walk", "plain"] | map(rm_marker(.)) | join(""))</defs>"
      + ([$lanes | to_entries[]
            | .value as $lane
            | $lane.top as $top
            | "<g class=\"rm-lane\" id=\"lane-\($lane.day)\" data-day=\"\($lane.day)\">"
              + "<rect class=\"rm-lane-box\" x=\"12\" y=\"\($top)\" width=\"\($width - 24)\" height=\"\($lane.height)\" rx=\"14\"/>"
              + rm_text(rm_left; $top + 22; "rm-lane-label"; $lane.label)
              + ([range(1; $lane.segments | length) as $i | $lane.segments[$i] | rm_edges($lane.segments[$i - 1]; $top)] | join(""))
              + ([$lane.segments[] | rm_node($top + rm_row_y(.row); $trip.travelers)] | join(""))
              + "</g>"] | join("\n"))
      + "</svg>";

def rm_legend($trip):
    [$trip.itinerary[].segments[]] as $segments
    | [
        (["attraction", "meal", "break", "travel", "optional"][] as $type
            | ([$segments[] | select((.type // "attraction") == $type)] | length) as $count
            | select($count > 0)
            | "<li><span class=\"rm-swatch k-\($type)\"></span>\({ type: $type } | type_tag[0]) \($count)</li>"),
        ([$segments[] | .transit.mode, .rain_plan.transit.mode | select(.) | rm_mode_class] | unique) as $modes
        | ({ drive: "開車／叫車", transit: "大眾運輸", walk: "步行" } | to_entries[]
            | select(.key | IN($modes[]))
            | "<li><span class=\"rm-line rm-\(.key)\"></span>\(.value)</li>")
      ]
    | "<ul class=\"rm-legend\" aria-label=\"圖例\">\(join(""))</ul>";

def rm_note($trip):
    . as $day
    | [
        "<strong>Day \(.day | esc)\(if .title then " · \(.title | esc)" else "" end)</strong>",
        (.weather.summary | select(present) | "🌦️ \(esc)\(if $day.weather.rain_chance != null then " · 降雨 \($day.weather.rain_chance | esc)%" else "" end)"),
        ($trip.constraints[] | select(.day == $day.day) | "⏰ \(.time // "" | esc) \(constraint_label)\(if .description then "｜\(.description | esc)" else "" end)"),
        (.travel_notes | select(present) | "🚗 \(esc)")
      ]
    | "<p class=\"rm-note\" data-day=\"\($day.day | esc)\" hidden>\(join("<span class=\"rm-sep\"> ｜ </span>"))</p>";

# ---- vertical route (phones) ---------------------------------------------
# Same stops as the SVG, as an HTML list so names wrap instead of being clipped.

def rv_dots($travelers):
    (.highlights // {}) as $highlights
    | [$travelers[] | select($highlights[.id] != null) | "<span class=\"rv-dot member-\(.color | esc)\"></span>"]
    | if length > 0 then "<span class=\"rv-dots\" aria-hidden=\"true\">\(join(""))</span>" else "" end;

def rv_body($travelers):
    "<span class=\"rv-body\(if .plan then " rplan-\(.plan)" else "" end)\">"
    + "<span class=\"rv-top\">"
    + (if .time then "<span class=\"rv-time\">\(.time | esc)</span>" else "" end)
    + rv_dots($travelers)
    + (if .plan == "sun" then "<span class=\"rv-flag\">有雨備</span>"
       elif .plan == "rain" then "<span class=\"rv-flag rv-flag-rain\">⛈️ 雨備</span>"
       else "" end)
    + "</span>"
    + "<span class=\"rv-name\">\(.name // "" | esc)</span>"
    + (rm_sub | if present then "<span class=\"rv-sub\">\(esc)</span>" else "" end)
    + "</span>";

def rv_leg_html:
    "<div class=\"rv-leg rm-\(.transit.mode | rm_mode_class)\(if .plan then " rplan-\(.plan)" else "" end)\">"
    + (rm_edge_lines | if length > 0 then "<span>\(join(" · ") | esc)</span>" else "" end)
    + "</div>";

def rv_leg:
    rm_variants as $variants
    | if ($variants | length) > 1 and (.rain_plan.transit != null) then
        [$variants[] | rv_leg_html] | join("")
      else ({ plan: null } + .) | rv_leg_html
      end;

def rv_stop($id; $first; $travelers):
    "<li class=\"rv-stop k-\(.type // "attraction" | esc)\">"
    + (if $first then "" else rv_leg end)
    + "<button type=\"button\" class=\"rv-node\" data-seg=\"\($id)\" aria-expanded=\"false\" aria-controls=\"rv-detail-\($id)\">"
    + ([rm_variants[] | rv_body($travelers)] | join(""))
    + "</button>"
    + "<div class=\"rv-detail\" id=\"rv-detail-\($id)\" hidden></div>"
    + "</li>";

def rv_day($trip):
    . as $day
    | [
        (.date | select(present) | short_date | esc),
        (.weather.summary | select(present) | "🌦️ \(esc)\(if $day.weather.rain_chance != null then " \($day.weather.rain_chance | esc)%" else "" end)"),
        ($trip.constraints[] | select(.day == $day.day) | "⏰ \(.time // "" | esc) \(constraint_label)")
      ] as $meta
    | "<section class=\"rv-day\" data-day=\"\(.day | esc)\">"
      + "<h3 class=\"rv-head\"><span class=\"day-badge\">Day \(.day | esc)</span>\(.title // "" | esc)</h3>"
      + (if ($meta | length) > 0 then "<p class=\"rv-meta\">\($meta | join(" · "))</p>" else "" end)
      + "<ol class=\"rv-stops\">"
      + ([.segments | to_entries[] | .key as $index | .value | rv_stop("d\($day.day)-\($index + 1)"; $index == 0; $trip.travelers)] | join(""))
      + "</ol></section>";

def route_map_html($trip):
    "<section class=\"route-map\" id=\"route-map\" aria-label=\"路線圖\">\n"
    + "<p class=\"rm-hint\"><span class=\"rm-hint-wide\">點任一站看詳情</span><span class=\"rm-hint-narrow\">點任一站展開詳情</span></p>\n"
    + "<p class=\"rm-note\" data-day=\"overview\">\($trip.itinerary | length) 天行程總覽，點上方 Day 分頁聚焦單日</p>\n"
    + ([$trip.itinerary[] | rm_note($trip)] | join("\n")) + "\n"
    + "<div class=\"rm-viewport\">\n"
    + route_map_svg($trip)
    + "\n</div>\n"
    + "<div class=\"rm-vertical\">\n"
    + ([$trip.itinerary[] | rv_day($trip)] | join("\n"))
    + "\n</div>\n"
    + rm_legend($trip) + "\n"
    + "<div class=\"rm-detail\" aria-live=\"polite\"><p class=\"rm-detail-empty\">點選路線圖上的任一站，詳細內容會顯示在這裡</p></div>\n"
    + "</section>";
