#!/bin/bash
# Travel Plan - JSON Output Formatter
# Normalizes itinerary JSON to the schema in references/output-formats.md,
# fills meta and summary, and reports problems (bad times, unknown travelers, missed deadlines) on stderr.

set -euo pipefail

INPUT_FILE="${1:-/dev/stdin}"
OUTPUT_FILE="${2:-/dev/stdout}"

source "$(dirname "$0")/lib/common.sh"

usage() {
    echo "Usage: $0 [input.json] [output.json]"
    echo ""
    echo "Arguments:"
    echo "  input.json   Itinerary JSON file (default: stdin)"
    echo "  output.json  Normalized JSON file (default: stdout)"
    echo ""
    echo "What it does:"
    echo "  - Fills meta (generated_at, generator, version), day numbers, traveler colors"
    echo "  - Computes summary counts unless provided"
    echo "  - Prints warnings to stderr; exit code stays 0 so drafts can still be rendered"
    echo ""
    echo "Examples:"
    echo "  $0 draft.json itinerary.json"
    echo "  cat draft.json | $0 > itinerary.json"
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    require_jq

    local input_data
    input_data=$(read_input "$INPUT_FILE")

    local warnings
    warnings=$(printf '%s' "$input_data" | itinerary_jq -r 'include "itinerary"; lint[]')
    if [[ -n "$warnings" ]]; then
        while IFS= read -r line; do
            warn "$line"
        done <<< "$warnings"
    fi

    local pending
    pending=$(printf '%s' "$input_data" | itinerary_jq 'include "itinerary"; to_verify_count')
    if [[ "$pending" -gt 0 ]]; then
        echo "Note: $pending item(s) marked to_verify" >&2
    fi

    printf '%s' "$input_data" \
        | itinerary_jq 'include "itinerary"; normalize | .meta.generated_at = (now | todate) | .summary = summarize' \
        > "$OUTPUT_FILE"
}

main "$@"
