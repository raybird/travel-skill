#!/bin/bash
# Travel Plan - JSON Output Formatter
# Generates structured JSON itinerary from input data

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_json_header() {
    cat << 'EOF'
{
  "meta": {
    "generated_at": "EOF
}

print_json_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

print_json_rest() {
    cat << 'EOF'
",
    "generator": "travel-plan-agent",
    "version": "1.0.0"
  },
  "trip": {
    "name": "",
    "duration_days": 0,
    "date": "",
    "starting_point": "",
    "transportation": ""
  },
  "itinerary": [],
  "summary": {
    "total_attractions": 0,
    "total_estimated_hours": 0,
    "rest_stops_recommended": 0
  }
}
EOF
}

# Generate JSON structure
generate_json() {
    local input_data="$1"
    
    # Get timestamp
    local timestamp
    timestamp=$(print_json_timestamp)
    
    # Extract trip info if JSON input provided
    local trip_name="旅遊行程"
    local days=1
    local date=""
    
    if command -v jq &> /dev/null && [[ "$input_data" != "{}" ]]; then
        trip_name=$(echo "$input_data" | jq -r '.trip.name // "旅遊行程"')
        days=$(echo "$input_data" | jq -r '.trip.days // 1')
        date=$(echo "$input_data" | jq -r '.trip.date // ""')
    fi
    
    # Build the JSON structure
    cat << EOF
{
  "meta": {
    "generated_at": "$timestamp",
    "generator": "travel-plan-agent",
    "version": "1.0.0"
  },
  "trip": {
    "name": "$trip_name",
    "duration_days": $days,
    "date": "$date",
    "starting_point": "",
    "transportation": ""
  },
  "itinerary": [
    {
      "day": 1,
      "date": "",
      "segments": [
        {
          "time": "09:00",
          "type": "attraction",
          "name": "景點名稱",
          "address": "地址",
          "duration_minutes": 120,
          "notes": "參觀說明"
        },
        {
          "time": "12:00",
          "type": "break",
          "name": "休息站/餐廳",
          "address": "",
          "duration_minutes": 60,
          "notes": "午餐建議"
        },
        {
          "time": "14:00",
          "type": "attraction",
          "name": "景點名稱",
          "address": "地址",
          "duration_minutes": 120,
          "notes": "參觀說明"
        }
      ],
      "travel_notes": "交通說明"
    }
  ],
  "summary": {
    "total_attractions": 2,
    "total_estimated_hours": 6,
    "rest_stops_recommended": 1,
    "notes": [
      "出發前請確認景點開放時間",
      "建議提早出發以避開人潮"
    ]
  }
}
EOF
}

# Usage information
usage() {
    echo "Usage: $0 [input.json] [output.json]"
    echo ""
    echo "Arguments:"
    echo "  input.json   Input JSON file (default: stdin)"
    echo "  output.json  Output JSON file (default: stdout)"
    echo ""
    echo "Input JSON format:"
    echo '  {'
    echo '    "trip": {'
    echo '      "name": "行程名稱",'
    echo '      "days": 3,'
    echo '      "date": "2026-01-25"'
    echo '    }'
    echo '  }'
    echo ""
    echo "Output JSON Schema:"
    echo "  - meta: Generation metadata"
    echo "  - trip: Basic trip information"
    echo "  - itinerary: Array of daily itineraries"
    echo "  - summary: Trip summary statistics"
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.json"
    echo "  cat itinerary.json | $0 > plan.json"
}

# Main execution
main() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Read input
    local input_data
    if [[ -p "/dev/stdin" ]] || [[ "$INPUT_FILE" != "/dev/stdin" && -f "$INPUT_FILE" ]]; then
        input_data=$(cat "$INPUT_FILE")
    else
        input_data='{}'
    fi
    
    generate_json "$input_data"
}

main "$@"
