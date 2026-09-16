#!/bin/bash
# Travel Plan Skill - Validation Script
# Validates skill structure and exercises the deterministic render pipeline end to end.

set -u

SKILL_DIR="${1:-$(dirname "$0")}"
ERRORS=0

echo "Validating Travel Plan Skill..."
echo "================================"
echo ""

fail() {
    echo "  ❌ $1"
    ((ERRORS++))
}

if [[ ! -d "$SKILL_DIR" ]]; then
    echo "❌ Error: Skill directory not found: $SKILL_DIR"
    exit 1
fi

# Check SKILL.md
echo "Checking SKILL.md..."
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
    echo "  ✅ SKILL.md exists"

    if head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---"; then
        echo "  ✅ Frontmatter start found"
    else
        fail "Missing frontmatter start"
    fi

    if grep -q "^name: travel-plan" "$SKILL_DIR/SKILL.md"; then
        echo "  ✅ name field is correct"
    else
        fail "name field missing or incorrect"
    fi

    if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
        echo "  ✅ description field exists"
    else
        fail "description field missing"
    fi
else
    fail "SKILL.md not found"
fi

echo ""

# Check scripts directory
echo "Checking scripts/..."
for script in format-markdown.sh format-json.sh format-html.sh; do
    if [[ -f "$SKILL_DIR/scripts/$script" ]]; then
        if [[ -x "$SKILL_DIR/scripts/$script" ]]; then
            echo "  ✅ $script exists and is executable"
        else
            echo "  ⚠️  $script is not executable (CI invokes it through bash-compatible checkout permissions)"
        fi
    else
        fail "$script not found"
    fi
done
for lib in common.sh itinerary.jq; do
    if [[ -f "$SKILL_DIR/scripts/lib/$lib" ]]; then
        echo "  ✅ lib/$lib exists"
    else
        fail "lib/$lib not found"
    fi
done

echo ""

# Check references and schemas
echo "Checking contract files/..."
for ref in taiwan-data-sources.md output-formats.md conversation-guide.md execution-contract.md; do
    if [[ -f "$SKILL_DIR/references/$ref" ]]; then
        echo "  ✅ references/$ref exists"
    else
        fail "references/$ref not found"
    fi
done
for schema in request.schema.json itinerary.schema.json; do
    if [[ -f "$SKILL_DIR/schemas/$schema" ]]; then
        echo "  ✅ schemas/$schema exists"
    else
        fail "schemas/$schema not found"
    fi
done

echo ""

# Check assets directory
echo "Checking assets/..."
for asset in html-template.html style.css; do
    if [[ -f "$SKILL_DIR/assets/$asset" ]]; then
        echo "  ✅ $asset exists"
    else
        fail "$asset not found"
    fi
done

echo ""

# Render examples and exercise strict/deterministic behavior.
echo "Checking examples and execution contract..."
EXAMPLE="$SKILL_DIR/examples/taipei-family-3days"
if ! command -v jq &> /dev/null; then
    echo "  ⚠️  jq not found, skipping executable checks"
elif [[ ! -f "$EXAMPLE.json" ]]; then
    fail "examples/taipei-family-3days.json not found"
else
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    for schema in "$SKILL_DIR"/schemas/*.json; do
        if jq empty "$schema" >/dev/null 2>&1; then
            echo "  ✅ $(basename "$schema") is valid JSON"
        else
            fail "$(basename "$schema") is malformed JSON"
        fi
    done

    if "$SKILL_DIR/scripts/format-json.sh" --strict "$EXAMPLE.json" "$TMP_DIR/normalized-a.json" 2> "$TMP_DIR/lint.txt"; then
        echo "  ✅ format-json.sh --strict: example passes semantic validation"
    else
        fail "format-json.sh --strict reported problems:"
        sed 's/^/      /' "$TMP_DIR/lint.txt"
    fi

    if "$SKILL_DIR/scripts/format-json.sh" --strict "$EXAMPLE.json" "$TMP_DIR/normalized-b.json" 2> "$TMP_DIR/lint-b.txt" \
        && cmp -s "$TMP_DIR/normalized-a.json" "$TMP_DIR/normalized-b.json"; then
        echo "  ✅ canonical JSON is byte-stable across repeated runs"
    else
        fail "canonical JSON is not deterministic"
    fi

    if jq -e '.meta.generated_at == null' "$TMP_DIR/normalized-a.json" >/dev/null 2>&1; then
        echo "  ✅ deterministic mode does not inject wall-clock generated_at"
    else
        fail "deterministic mode unexpectedly injected meta.generated_at"
    fi

    if "$SKILL_DIR/scripts/format-json.sh" --strict --generated-at "2026-09-16T06:30:00Z" \
        "$EXAMPLE.json" "$TMP_DIR/stamped.json" 2> "$TMP_DIR/stamped-lint.txt" \
        && jq -e '.meta.generated_at == "2026-09-16T06:30:00Z"' "$TMP_DIR/stamped.json" >/dev/null; then
        echo "  ✅ caller-controlled generated_at is reproducible"
    else
        fail "--generated-at did not preserve the caller timestamp"
    fi

    cat > "$TMP_DIR/invalid.json" <<'JSON'
{"trip":{"name":"invalid","duration_days":1},"itinerary":[{"day":1,"segments":[{"time":"25:00","type":"attraction","name":""}]}]}
JSON
    echo "sentinel" > "$TMP_DIR/blocked.json"
    if "$SKILL_DIR/scripts/format-json.sh" --strict "$TMP_DIR/invalid.json" "$TMP_DIR/blocked.json" >/dev/null 2> "$TMP_DIR/invalid-lint.txt"; then
        fail "strict mode accepted an invalid itinerary"
    elif [[ "$(cat "$TMP_DIR/blocked.json")" == "sentinel" ]]; then
        echo "  ✅ strict mode rejects invalid input before touching publishable output"
    else
        fail "strict mode modified output even though validation failed"
    fi

    if "$SKILL_DIR/scripts/format-html.sh" "$EXAMPLE.json" "$TMP_DIR/example.html"; then
        if grep -q "{{[A-Z_]*}}" "$TMP_DIR/example.html"; then
            fail "format-html.sh left unfilled placeholders"
        else
            echo "  ✅ format-html.sh: all placeholders filled"
        fi
    else
        fail "format-html.sh failed"
    fi

    if "$SKILL_DIR/scripts/format-markdown.sh" "$EXAMPLE.json" "$TMP_DIR/example.md"; then
        echo "  ✅ format-markdown.sh renders the example"
    else
        fail "format-markdown.sh failed"
    fi

    for ext in html md; do
        if cmp -s "$TMP_DIR/example.$ext" "$EXAMPLE.$ext"; then
            echo "  ✅ examples/taipei-family-3days.$ext matches script output"
        else
            fail "examples/taipei-family-3days.$ext is out of date; regenerate it with the scripts"
        fi
    done

    # Values must stay escaped: no raw markup or closing script tag from trip data.
    echo '{"trip":{"name":"</script><b>x</b>{{DATE_JSON}}"},"itinerary":[{"segments":[{"time":"09:00","type":"attraction","name":"<img src=x>","map_url":"javascript:alert(1)"}]}]}' \
        | "$SKILL_DIR/scripts/format-html.sh" > "$TMP_DIR/escape.html"
    if grep -q -e "<b>x</b>" -e "<img src=x>" -e "javascript:alert" -e '</script><b>' "$TMP_DIR/escape.html"; then
        fail "format-html.sh did not escape hostile values"
    else
        echo "  ✅ format-html.sh escapes values and drops unsafe URLs"
    fi
fi

echo ""
echo "================================"

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ Validation passed! Skill contract, deterministic pipeline, and examples are valid."
    exit 0
else
    echo "❌ Validation completed with $ERRORS error(s)"
    exit 1
fi
