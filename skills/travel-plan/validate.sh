#!/bin/bash
# Travel Plan Skill - Validation Script
# Validates skill structure, then renders the examples to check the scripts end to end

SKILL_DIR="${1:-$(dirname "$0")}"
ERRORS=0

echo "Validating Travel Plan Skill..."
echo "================================"
echo ""

fail() {
    echo "  ❌ $1"
    ((ERRORS++))
}

# Check if skill directory exists
if [[ ! -d "$SKILL_DIR" ]]; then
    echo "❌ Error: Skill directory not found: $SKILL_DIR"
    exit 1
fi

# Check for SKILL.md
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
            echo "  ⚠️  $script is not executable"
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

# Check references directory
echo "Checking references/..."
for ref in taiwan-data-sources.md output-formats.md conversation-guide.md; do
    if [[ -f "$SKILL_DIR/references/$ref" ]]; then
        echo "  ✅ $ref exists"
    else
        echo "  ⚠️  $ref not found"
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

# Render examples
echo "Checking examples/..."
EXAMPLE="$SKILL_DIR/examples/taipei-family-3days"
if ! command -v jq &> /dev/null; then
    echo "  ⚠️  jq not found, skipping render checks"
elif [[ ! -f "$EXAMPLE.json" ]]; then
    fail "examples/taipei-family-3days.json not found"
else
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    if "$SKILL_DIR/scripts/format-json.sh" "$EXAMPLE.json" "$TMP_DIR/normalized.json" 2> "$TMP_DIR/lint.txt" \
        && ! grep -q "Warning" "$TMP_DIR/lint.txt"; then
        echo "  ✅ format-json.sh: example has no warnings"
    else
        fail "format-json.sh reported problems:"
        sed 's/^/      /' "$TMP_DIR/lint.txt"
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

    # Values must stay escaped: no raw markup or closing script tag from trip data
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

# Summary
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ Validation passed! Skill structure and examples are valid."
    exit 0
else
    echo "❌ Validation completed with $ERRORS error(s)"
    exit 1
fi
