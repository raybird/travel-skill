#!/bin/bash
# Travel Plan Skill - Validation Script
# Validates skill structure and format

SKILL_DIR="${1:-./skills/travel-plan}"
ERRORS=0

echo "Validating Travel Plan Skill..."
echo "================================"
echo ""

# Check if skill directory exists
if [[ ! -d "$SKILL_DIR" ]]; then
    echo "❌ Error: Skill directory not found: $SKILL_DIR"
    exit 1
fi

# Check for SKILL.md
echo "Checking SKILL.md..."
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
    echo "  ✅ SKILL.md exists"
    
    # Check frontmatter
    if head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---"; then
        echo "  ✅ Frontmatter start found"
    else
        echo "  ❌ Missing frontmatter start"
        ((ERRORS++))
    fi
    
    # Check name field
    if grep -q "^name: travel-plan" "$SKILL_DIR/SKILL.md"; then
        echo "  ✅ name field is correct"
    else
        echo "  ❌ name field missing or incorrect"
        ((ERRORS++))
    fi
    
    # Check description field
    if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
        echo "  ✅ description field exists"
    else
        echo "  ❌ description field missing"
        ((ERRORS++))
    fi
else
    echo "  ❌ SKILL.md not found"
    ((ERRORS++))
fi

echo ""

# Check scripts directory
echo "Checking scripts/..."
if [[ -d "$SKILL_DIR/scripts" ]]; then
    echo "  ✅ scripts/ directory exists"
    
    for script in format-markdown.sh format-json.sh format-html.sh; do
        if [[ -f "$SKILL_DIR/scripts/$script" ]]; then
            echo "    ✅ $script exists"
            if [[ -x "$SKILL_DIR/scripts/$script" ]]; then
                echo "    ✅ $script is executable"
            else
                echo "    ⚠️  $script is not executable"
            fi
        else
            echo "    ❌ $script not found"
            ((ERRORS++))
        fi
    done
else
    echo "  ❌ scripts/ directory not found"
    ((ERRORS++))
fi

echo ""

# Check references directory
echo "Checking references/..."
if [[ -d "$SKILL_DIR/references" ]]; then
    echo "  ✅ references/ directory exists"
    
    for ref in taiwan-data-sources.md output-formats.md conversation-guide.md; do
        if [[ -f "$SKILL_DIR/references/$ref" ]]; then
            echo "    ✅ $ref exists"
        else
            echo "    ⚠️  $ref not found"
        fi
    done
else
    echo "  ❌ references/ directory not found"
    ((ERRORS++))
fi

echo ""

# Check assets directory
echo "Checking assets/..."
if [[ -d "$SKILL_DIR/assets" ]]; then
    echo "  ✅ assets/ directory exists"
    
    for asset in html-template.html style.css; do
        if [[ -f "$SKILL_DIR/assets/$asset" ]]; then
            echo "    ✅ $asset exists"
        else
            echo "    ⚠️  $asset not found"
        fi
    done
else
    echo "  ❌ assets/ directory not found"
    ((ERRORS++))
fi

echo ""
echo "================================"

# Summary
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ Validation passed! Skill structure is valid."
    echo ""
    echo "Skill structure:"
    echo "  skills/travel-plan/"
    echo "  ├── SKILL.md"
    echo "  ├── scripts/"
    echo "  │   ├── format-markdown.sh"
    echo "  │   ├── format-json.sh"
    echo "  │   └── format-html.sh"
    echo "  ├── references/"
    echo "  │   ├── taiwan-data-sources.md"
    echo "  │   ├── output-formats.md"
    echo "  │   └── conversation-guide.md"
    echo "  └── assets/"
    echo "      ├── html-template.html"
    echo "      └── style.css"
    exit 0
else
    echo "❌ Validation completed with $ERRORS error(s)"
    exit 1
fi
