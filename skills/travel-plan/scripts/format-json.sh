#!/bin/bash
# Travel Plan - JSON Output Formatter
# Normalizes itinerary JSON to the schema in references/output-formats.md.
# Default mode is deterministic: it never inserts the current wall-clock time.

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

STRICT=0
STAMP_NOW=0
GENERATED_AT=""
POSITIONAL=()

usage() {
    cat <<'EOF'
Usage: format-json.sh [options] [input.json] [output.json]

Options:
  --strict                 Treat semantic lint messages as blocking errors (exit 2)
  --generated-at ISO8601   Set meta.generated_at to a caller-controlled value
  --stamp-now              Set meta.generated_at to the current UTC time (non-replayable)
  -h, --help               Show this help

Arguments:
  input.json               Itinerary JSON file (default: stdin)
  output.json              Normalized JSON file (default: stdout)

Behavior:
  - Fills canonical meta.generator/meta.version, day numbers, traveler colors
  - Computes summary counts unless provided
  - Preserves caller data and does not add generated_at unless explicitly requested
  - Draft mode prints lint warnings and still renders
  - Strict mode exits 2 before writing output when lint messages exist

Examples:
  format-json.sh draft.json normalized.json
  format-json.sh --strict itinerary.json normalized.json
  format-json.sh --strict --generated-at 2026-09-16T06:30:00Z itinerary.json normalized.json
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT=1
            shift
            ;;
        --generated-at)
            if [[ $# -lt 2 ]]; then
                echo "Error: --generated-at requires an ISO8601 value" >&2
                exit 64
            fi
            GENERATED_AT="$2"
            shift 2
            ;;
        --stamp-now)
            STAMP_NOW=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            echo "Error: unknown option: $1" >&2
            usage >&2
            exit 64
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -gt 2 ]]; then
    echo "Error: too many positional arguments" >&2
    usage >&2
    exit 64
fi

if [[ $STAMP_NOW -eq 1 && -n "$GENERATED_AT" ]]; then
    echo "Error: use either --stamp-now or --generated-at, not both" >&2
    exit 64
fi

INPUT_FILE="${POSITIONAL[0]:-/dev/stdin}"
OUTPUT_FILE="${POSITIONAL[1]:-/dev/stdout}"

main() {
    require_jq

    local input_data
    input_data=$(read_input "$INPUT_FILE")

    # Parse once up front so malformed JSON fails before any output file is touched.
    if ! printf '%s' "$input_data" | jq -e . >/dev/null 2>&1; then
        echo "Error: input is not valid JSON" >&2
        exit 65
    fi

    local warnings
    warnings=$(printf '%s' "$input_data" | itinerary_jq -r 'include "itinerary"; lint[]')
    if [[ -n "$warnings" ]]; then
        while IFS= read -r line; do
            warn "$line"
        done <<< "$warnings"
        if [[ $STRICT -eq 1 ]]; then
            echo "Error: strict validation failed" >&2
            exit 2
        fi
    fi

    local pending
    pending=$(printf '%s' "$input_data" | itinerary_jq 'include "itinerary"; to_verify_count')
    if [[ "$pending" -gt 0 ]]; then
        echo "Note: $pending item(s) marked to_verify" >&2
    fi

    local generated_at="$GENERATED_AT"
    if [[ $STAMP_NOW -eq 1 ]]; then
        generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    fi

    local output_data
    if [[ -n "$generated_at" ]]; then
        output_data=$(printf '%s' "$input_data" \
            | itinerary_jq --arg generated_at "$generated_at" \
              'include "itinerary"; normalize | .meta.generated_at = $generated_at | .summary = summarize')
    else
        output_data=$(printf '%s' "$input_data" \
            | itinerary_jq 'include "itinerary"; normalize | .summary = summarize')
    fi

    printf '%s\n' "$output_data" > "$OUTPUT_FILE"
}

main
