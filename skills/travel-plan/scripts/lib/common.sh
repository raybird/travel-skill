#!/bin/bash
# Travel Plan - shared helpers for scripts/format-*.sh (sourced, not executed)

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

require_jq() {
    command -v jq &> /dev/null || die "jq is required (https://jqlang.github.io/jq/)"
}

# Print the itinerary JSON from a file or piped/redirected stdin.
# With no file and an interactive stdin, print an empty itinerary.
read_input() {
    local input_file="$1"
    local data='{}'

    if [[ "$input_file" != "/dev/stdin" ]]; then
        [[ -f "$input_file" ]] || die "input file not found: $input_file"
        data=$(cat "$input_file")
    elif [[ -p /dev/stdin || -f /dev/stdin ]]; then
        data=$(cat)
    fi

    [[ -n "${data//[[:space:]]/}" ]] || data='{}'
    printf '%s' "$data"
}

# Run a jq program with the itinerary library on the itinerary JSON
itinerary_jq() {
    jq -L "$LIB_DIR" "$@"
}
