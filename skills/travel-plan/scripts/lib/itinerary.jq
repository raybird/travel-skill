# Travel Plan - shared jq helpers for the itinerary JSON schema
# (references/output-formats.md). Loaded with: jq -L scripts/lib 'include "itinerary"; ...'

def schema_version: "1.2.0";
def segment_types: ["attraction", "break", "meal", "travel", "optional"];
def constraint_types: ["depart_after", "arrive_by", "other"];
def traveler_colors: ["rose", "blue", "cyan", "violet", "amber", "green", "orange", "slate"];

# ---- encoding -------------------------------------------------------------

def esc: tostring | @html;

# JSON string literal that is safe inside <script>
def js: tojson | gsub("<"; "\\u003c");

def present: . != null and . != "" and . != [] and . != {};

def is_safe_url: type == "string" and test("^https?://");

def safe_url: select(is_safe_url);

def is_date: type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$");

# ---- time -----------------------------------------------------------------

def is_hhmm: type == "string" and test("^([01][0-9]|2[0-3]):[0-5][0-9]$");

def minutes_of_day: if is_hhmm then (split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) else null end;

def duration_text:
    if type != "number" then null
    elif . >= 60 then "\(. / 60 | floor) 小時" + (if . % 60 > 0 then " \(. % 60) 分" else "" end)
    else "\(.) 分鐘"
    end;

def period:
    ((.time | minutes_of_day) // 0) as $m
    | if $m >= 17 * 60 then "evening" elif $m >= 12 * 60 then "afternoon" else "morning" end;

# "2026-10-14" -> "10/14（三）"; unparseable dates are returned unchanged
def short_date:
    . as $date
    | try (
        strptime("%Y-%m-%d") | mktime | gmtime | strftime("%w") | tonumber
        | ["日", "一", "二", "三", "四", "五", "六"][.]
        | "\($date[5:7] | ltrimstr("0"))/\($date[8:10] | ltrimstr("0"))（\(.)）"
      ) catch $date;

# "2026-10-14" -> "10/14 三", compact enough for tabs
def tab_date: short_date | sub("（(?<day>.)）$"; " \(.day)");

# ---- labels ---------------------------------------------------------------

# [label, css class]
def type_tag:
    {
        attraction: ["景點", "tag-attraction"],
        meal: ["用餐", "tag-meal"],
        break: ["休息", "tag-break"],
        travel: ["交通", "tag-travel"],
        optional: ["選配", "tag-optional"]
    }[.type // ""];

def mode_label:
    {
        drive: "🚗 自駕",
        mrt: "🚇 捷運",
        bus: "🚌 公車",
        train: "🚆 台鐵",
        hsr: "🚄 高鐵",
        taxi: "🚕 計程車",
        rideshare: "🚕 叫車",
        walk: "🚶 步行"
    }[. // ""] // .;

def travel_mode:
    if IN("mrt", "bus", "train", "hsr") then "transit"
    elif . == "walk" then "walking"
    else "driving"
    end;

# A line is "BL" or {"code": "R", "name": "紅線"}; default names follow Taipei Metro
def line_code: (if type == "object" then .code else . end) // "" | tostring | ascii_upcase | gsub("[^A-Z0-9]"; "");

def line_name:
    if type == "object" and .name then .name
    else
        line_code as $code
        | {
            BL: "板南線", R: "淡水信義線", G: "松山新店線", O: "中和新蘆線",
            BR: "文湖線", Y: "環狀線", A: "機場捷運", V: "淡海輕軌", K: "安坑輕軌"
          }[$code] // $code
    end;

def constraint_label:
    { depart_after: "後出發", arrive_by: "前抵達" }[.kind // ""] // "";

def member_label: [.emoji, .label] | map(select(present)) | join(" ");

# ---- maps -----------------------------------------------------------------

def place_query:
    if (.coordinates.lat | type) == "number" and (.coordinates.lng | type) == "number" then
        "\(.coordinates.lat),\(.coordinates.lng)"
    else
        .address // .name
    end;

def map_url_for:
    (.map_url | safe_url)
    // (place_query | select(present) | "https://www.google.com/maps/search/?api=1&query=\(@uri)");

# Directions to this segment; origin/waypoints pin the route (e.g. a service area on the chosen freeway)
def directions_url_for:
    . as $segment
    | (.transit // {}) as $transit
    | ($transit.waypoints // []) as $waypoints
    | if ($transit.map_url | is_safe_url) then $transit.map_url
      elif $transit.origin or ($waypoints | length) > 0 then
          "https://www.google.com/maps/dir/?api=1"
          + (if $transit.origin then "&origin=\($transit.origin | @uri)" else "" end)
          + "&destination=\($segment | place_query | @uri)"
          + (if ($waypoints | length) > 0 then "&waypoints=\($waypoints | join("|") | @uri)" else "" end)
          + "&travelmode=\($transit.mode | travel_mode)"
      else empty
      end;

# ---- normalize & lint -----------------------------------------------------

def normalize:
    .meta = ((.meta // {}) + { generator: "travel-plan-agent", version: schema_version })
    | .trip = ({ name: "旅遊行程" } + (.trip // {}))
    | .itinerary = [
        (.itinerary // []) | to_entries[]
        | .value + { day: (.value.day // (.key + 1)), segments: (.value.segments // []) }
      ]
    | .trip.duration_days = (.trip.duration_days // ([.itinerary[]] | length | select(. > 0)) // 1)
    | .travelers = [
        (.travelers // []) | to_entries[]
        | .value + { color: (.value.color // traveler_colors[.key % (traveler_colors | length)]) }
      ]
    | .lodging = (.lodging // [])
    | .constraints = (.constraints // [])
    | .changes = (.changes // [])
    | .assumptions = (.assumptions // [])
    | .decisions = (.decisions // []);

def has_rain_plans: [.itinerary[]?.segments[]? | select(.rain_plan)] | length > 0;

def summarize:
    [.itinerary[].segments[]] as $segments
    | {
        total_attractions: ([$segments[] | select(.type == "attraction")] | length),
        total_estimated_hours: (([$segments[] | .duration_minutes // 0] | add // 0) / 6 | round / 10),
        rest_stops_recommended: ([$segments[] | select(.type == "break" or .type == "meal")] | length)
      } + (.summary // {});

# Human-readable semantic problems for an itinerary; an empty array means clean.
# Draft mode prints these as warnings; strict mode treats them as blocking errors.
def lint:
    . as $raw
    | normalize
    | [.travelers[].id | select(present)] as $ids
    | (.itinerary | map({ key: (.day | tostring), value: .segments }) | from_entries) as $days
    | def source_checks($where):
        ((.sources // [])[]
          | (if (.url | is_safe_url | not) then "\($where): sources 需要 http(s) 網址" else empty end),
            (if .checked_at != null and (.checked_at | is_date | not) then "\($where): sources.checked_at 必須是 YYYY-MM-DD" else empty end));
    | def check_segment($where):
        (if (.time | is_hhmm | not) then "\($where): time 必須是 HH:MM" else empty end),
        (if (.type | IN(segment_types[]) | not) then "\($where): type 必須是 \(segment_types | join(" / "))" else empty end),
        (if (.name | present | not) then "\($where): name 不可空白" else empty end),
        (if .duration_minutes != null and ((.duration_minutes | type) != "number" or .duration_minutes < 0) then "\($where): duration_minutes 必須是非負數" else empty end),
        (if .buffer_minutes != null and ((.buffer_minutes | type) != "number" or .buffer_minutes < 0) then "\($where): buffer_minutes 必須是非負數" else empty end),
        (if .transit.duration_minutes != null and ((.transit.duration_minutes | type) != "number" or .transit.duration_minutes < 0) then "\($where): transit.duration_minutes 必須是非負數" else empty end),
        ((.highlights // {}) | keys[] | select(IN($ids[]) | not) | "\($where): highlights 的「\(.)」不在 travelers 裡"),
        source_checks($where),
        (if (.transit.call_at != null) and (.transit.call_at | is_hhmm | not) then "\($where): transit.call_at 必須是 HH:MM" else empty end);
    [
      (if (($raw.trip.name // "") | present | not) then "trip.name 不可空白" else empty end),
      (if (.itinerary | length) == 0 then "itinerary 至少需要一天" else empty end),
      (if .trip.duration_days != (.itinerary | length) then "trip.duration_days 與 itinerary 天數不一致" else empty end),
      ([.travelers[].id | select(present)] | group_by(.)[] | select(length > 1) | "travelers.id 重複：「\(.[0])」"),
      ([.itinerary[].day] | group_by(.)[] | select(length > 1) | "itinerary.day 重複：Day \(.[0])"),
      (
        .itinerary[] | .day as $day
        | .segments | to_entries[]
        | "Day \($day) 第 \(.key + 1) 項「\(.value.name // "")」" as $where
        | .value as $segment
        | $segment | check_segment($where),
          (select(.rain_plan)
            | ({ time: $segment.time, type: $segment.type } + .rain_plan)
            | check_segment("\($where) 的雨備"),
              (if (.reason | present | not) then "\($where) 的 rain_plan.reason 不可空白" else empty end))
      ),
      (
        .itinerary[] | .day as $day
        | [.segments[] | .time | minutes_of_day] as $times
        | range(1; $times | length)
        | select($times[.] != null and $times[. - 1] != null and $times[.] < $times[. - 1])
        | "Day \($day) 第 \(. + 1) 項的時間早於前一項"
      ),
      (
        .constraints[]
        | . as $constraint
        | ($days[.day | tostring] // null) as $segments
        | if $segments == null then "constraints: Day \(.day) 不在 itinerary 裡"
          elif (.time | is_hhmm | not) then "constraints: Day \(.day) 的 time 必須是 HH:MM"
          elif (.kind | IN(constraint_types[]) | not) then "constraints: kind 必須是 \(constraint_types | join(" / "))"
          elif .kind == "arrive_by" and ($segments | length) > 0
               and (($segments | last | .time | minutes_of_day) // 0) > (.time | minutes_of_day) then
              "Day \(.day) 最後一項 \($segments | last | .time) 晚於截止時間 \(.time)（\(.description // "arrive_by")）"
          elif .kind == "depart_after" and ($segments | length) > 0
               and (($segments | first | .time | minutes_of_day) // 1440) < (.time | minutes_of_day) then
              "Day \(.day) 第一項 \($segments | first | .time) 早於可出發時間 \(.time)（\(.description // "depart_after")）"
          else empty
          end
      ),
      (
        .itinerary[] | select(.weather)
        | if .weather.source == null or .weather.checked_at == null then
            "Day \(.day) 的 weather 需要 source 與 checked_at"
          elif (.weather.checked_at | is_date | not) then
            "Day \(.day) 的 weather.checked_at 必須是 YYYY-MM-DD"
          else empty end
      )
    ];

def to_verify_count: [.. | objects | select(has("to_verify")) | .to_verify | select(present)] | length;
