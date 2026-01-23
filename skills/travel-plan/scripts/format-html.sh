#!/bin/bash
# Travel Plan - HTML Output Formatter
# Generates mobile-friendly HTML itinerary

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"
TEMPLATE_DIR="${3:-$(dirname "$0")/../assets}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    cat << 'EOF'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TRIP_NAME}}</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header class="trip-header">
        <div class="header-content">
            <h1>{{TRIP_NAME}}</h1>
            <p class="trip-meta">{{DURATION}} · {{DATE}}</p>
        </div>
    </header>
    
    <main class="container">
EOF
}

print_day_section() {
    local day_num="$1"
    local day_title="$2"
    
    cat << EOF
        <section class="day-section">
            <div class="day-header">
                <span class="day-badge">Day $day_num</span>
                <span class="day-title">$day_title</span>
            </div>
            
            <div class="time-card morning">
                <span class="time-label">09:00</span>
                <div class="spot-info">
                    <h3>景點名稱</h3>
                    <p>參觀說明...</p>
                </div>
            </div>
            
            <div class="time-card break">
                <span class="time-label">12:00</span>
                <div class="spot-info">
                    <h3>午餐推薦</h3>
                    <p>餐廳或休息站建議</p>
                </div>
            </div>
            
            <div class="time-card afternoon">
                <span class="time-label">14:00</span>
                <div class="spot-info">
                    <h3>景點名稱</h3>
                    <p>參觀說明...</p>
                </div>
            </div>
        </section>
EOF
}

print_tips_section() {
    cat << 'EOF'
        <section class="tips-section">
            <h2>旅遊注意事項</h2>
            <ul class="tips-list">
                <li>出發前請再次確認景點開放時間</li>
                <li>建議攜帶防曬用品及雨具</li>
                <li>交通資訊僅供參考，實際路況可能不同</li>
            </ul>
        </section>
EOF
}

print_actions_section() {
    cat << 'EOF'
        <section class="actions-section">
            <button class="btn btn-primary" onclick="copyAll()">複製全部行程</button>
            <button class="btn btn-secondary" onclick="shareViaLINE()">分享到 LINE</button>
        </section>
EOF
}

print_footer() {
    cat << 'EOF'
    </main>
    
    <footer class="footer">
        <p>此行程由 Travel Plan Agent 產生</p>
    </footer>
    
    <script>
        function copyAll() {
            const content = document.querySelector('main').innerText;
            navigator.clipboard.writeText(content).then(() => {
                alert('已複製到剪貼簿！');
            }).catch(() => {
                alert('複製失敗，請手動複製');
            });
        }
        
        function shareViaLINE() {
            const url = encodeURIComponent(window.location.href);
            const text = encodeURIComponent('{{TRIP_NAME}}\n{{DATE}}\n查看完整行程：');
            window.open('https://line.me/R/msg/text/?' + text + '%20' + url, '_blank');
        }
    </script>
</body>
</html>
EOF
}

# Generate HTML from input data
generate_html() {
    local input_data="$1"
    
    # Extract trip info if JSON input provided
    local trip_name="旅遊行程"
    local days=1
    local date=""
    
    if command -v jq &> /dev/null && [[ "$input_data" != "{}" ]]; then
        trip_name=$(echo "$input_data" | jq -r '.trip.name // "旅遊行程"')
        days=$(echo "$input_data" | jq -r '.trip.duration_days // 1')
        date=$(echo "$input_data" | jq -r '.trip.date // ""')
    fi
    
    print_header | sed "s/{{TRIP_NAME}}/$trip_name/g" | sed "s/{{DURATION}}/${days}天/g" | sed "s/{{DATE}}/$date/g"
    
    # Generate day sections
    for i in $(seq 1 "$days"); do
        print_day_section "$i" "Day $i"
    done
    
    print_tips_section
    print_actions_section
    print_footer
}

# Usage information
usage() {
    echo "Usage: $0 [input.json] [output.html] [template_dir]"
    echo ""
    echo "Arguments:"
    echo "  input.json    Input JSON file (default: stdin)"
    echo "  output.html   Output HTML file (default: stdout)"
    echo "  template_dir  Directory containing templates (default: assets/)"
    echo ""
    echo "Input JSON format:"
    echo '  {'
    echo '    "trip": {'
    echo '      "name": "行程名稱",'
    echo '      "duration_days": 3,'
    echo '      "date": "2026-01-25"'
    echo '    }'
    echo '  }'
    echo ""
    echo "Examples:"
    echo "  $0 itinerary.json plan.html"
    echo "  $0 itinerary.json plan.html ./assets"
    echo "  cat itinerary.json | $0 > plan.html"
}

# Main execution
main() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq not found, using default values${NC}" >&2
    fi
    
    # Read input
    local input_data
    if [[ -p "/dev/stdin" ]] || [[ "$INPUT_FILE" != "/dev/stdin" && -f "$INPUT_FILE" ]]; then
        input_data=$(cat "$INPUT_FILE")
    else
        input_data='{}'
    fi
    
    generate_html "$input_data"
}

main "$@"
