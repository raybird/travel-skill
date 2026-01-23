#!/bin/bash
# Travel Plan - Markdown Output Formatter
# Generates formatted Markdown itinerary from input data

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    cat << 'EOF'
# TRAVEL ITINERARY

---

EOF
}

print_day_section() {
    local day_num="$1"
    local day_title="$2"
    cat << EOF
## Day $day_num: $day_title

### 上午 (Morning)
| 時間 | 項目 | 說明 |
|------|------|------|

### 中途 (Midday)
| 時間 | 項目 | 說明 |
|------|------|------|

### 下午 (Afternoon)
| 時間 | 項目 | 說明 |
|------|------|------|

EOF
}

print_footer() {
    cat << 'EOF'
---

## 旅遊注意事項 (Travel Tips)

- 出發前請再次確認景點開放時間
- 建議攜帶防曬用品及雨具
- 交通資訊僅供參考，實際路況可能不同
- 餐廳建議可事先訂位以確保有位

---

*此行程由 Travel Plan Agent 產生*
EOF
}

# Main formatter function
format_markdown() {
    local input_data="$1"
    
    # Parse input and generate formatted markdown
    # Expected input format: JSON with itinerary data
    
    print_header
    
    # Check if jq is available for JSON parsing
    if command -v jq &> /dev/null; then
        # Process JSON input
        local trip_name
        trip_name=$(echo "$input_data" | jq -r '.trip.name // "旅遊行程"')
        local days
        days=$(echo "$input_data" | jq -r '.trip.days // 1')
        
        echo "# $trip_name"
        echo ""
        echo "---"
        echo ""
        
        # Generate day sections
        for i in $(seq 1 "$days"); do
            print_day_section "$i" "Day $i"
        done
    else
        # Fallback to basic template
        print_day_section 1 "行程規劃"
    fi
    
    print_footer
}

# Usage information
usage() {
    echo "Usage: $0 [input.json] [output.md]"
    echo ""
    echo "Arguments:"
    echo "  input.json   Input JSON file (default: stdin)"
    echo "  output.md    Output Markdown file (default: stdout)"
    echo ""
    echo "Input JSON format:"
    echo '  {'
    echo '    "trip": {'
    echo '      "name": "行程名稱",'
    echo '      "days": 3'
    echo '    }'
    echo '  }'
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.md"
    echo "  cat itinerary.json | $0 > plan.md"
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
        # No input provided, generate template
        input_data='{}'
    fi
    
    format_markdown "$input_data" "$OUTPUT_FILE"
}

main "$@"
