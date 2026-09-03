#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "       SonarQube Issue Export Tool"
echo "=============================================="
echo

# --------------------------------------------------
# SonarQube URL
# --------------------------------------------------
read -rp "SonarQube URL: " SONAR_URL

SONAR_URL="${SONAR_URL%/}"

if [[ -z "$SONAR_URL" ]]; then
    echo "ERROR: SonarQube URL cannot be empty."
    exit 1
fi

# --------------------------------------------------
# Token
# --------------------------------------------------
read -rsp "SonarQube Token: " SONAR_TOKEN
echo

if [[ -z "$SONAR_TOKEN" ]]; then
    echo "ERROR: SonarQube token cannot be empty."
    exit 1
fi

# --------------------------------------------------
# Component Key
# --------------------------------------------------
read -rp "Component Key: " COMPONENT_KEY

if [[ -z "$COMPONENT_KEY" ]]; then
    echo "ERROR: Component Key cannot be empty."
    exit 1
fi

# --------------------------------------------------
# Severity
# --------------------------------------------------
echo
echo "Severity options:"
echo "  1) BLOCKER"
echo "  2) CRITICAL"
echo "  3) MAJOR"
echo "  4) MINOR"
echo "  5) INFO"
echo "  6) ALL"

read -rp "Severity [CRITICAL]: " SEVERITY
SEVERITY="${SEVERITY:-CRITICAL}"

case "$SEVERITY" in
    1|[bB][lL][oO][cC][kK][eE][rR])
        SEVERITY="BLOCKER"
        ;;
    2|[cC][rR][iI][tT][iI][cC][aA][lL])
        SEVERITY="CRITICAL"
        ;;
    3|[mM][aA][jJ][oO][rR])
        SEVERITY="MAJOR"
        ;;
    4|[mM][iI][nN][oO][rR])
        SEVERITY="MINOR"
        ;;
    5|[iI][nN][fF][oO])
        SEVERITY="INFO"
        ;;
    6|[aA][lL][lL])
        SEVERITY=""
        ;;
    *)
        echo "ERROR: Invalid severity: $SEVERITY"
        exit 1
        ;;
esac

# --------------------------------------------------
# Status
# --------------------------------------------------
echo
echo "Status options:"
echo "  1) OPEN"
echo "  2) CONFIRMED"
echo "  3) REOPENED"
echo "  4) RESOLVED"
echo "  5) CLOSED"
echo "  6) ALL"

read -rp "Status [OPEN]: " STATUS
STATUS="${STATUS:-OPEN}"

case "$STATUS" in
    1|[oO][pP][eE][nN])
        STATUS="OPEN"
        ;;
    2|[cC][oO][nN][fF][iI][rR][mM][eE][dD])
        STATUS="CONFIRMED"
        ;;
    3|[rR][eE][oO][pP][eE][nN][eE][dD])
        STATUS="REOPENED"
        ;;
    4|[rR][eE][sS][oO][lL][vV][eE][dD])
        STATUS="RESOLVED"
        ;;
    5|[cC][lL][oO][sS][eE][dD])
        STATUS="CLOSED"
        ;;
    6|[aA][lL][lL])
        STATUS=""
        ;;
    *)
        echo "ERROR: Invalid status: $STATUS"
        exit 1
        ;;
esac

# --------------------------------------------------
# Output directory & files
# --------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="${SCRIPT_DIR}/sonarqube-issue"

mkdir -p "$OUTPUT_DIR"

# Ensure .gitignore exists in the output directory
GITIGNORE_FILE="${OUTPUT_DIR}/.gitignore"

if [[ ! -f "$GITIGNORE_FILE" ]]; then
    cat << 'EOF' > "$GITIGNORE_FILE"
*
!.gitignore
EOF
fi

JSON_FILE="${OUTPUT_DIR}/sonar-issues-${TIMESTAMP}.json"
CSV_FILE="${OUTPUT_DIR}/sonar-issues-${TIMESTAMP}.csv"

echo
echo "=============================================="
echo "Export Configuration"
echo "=============================================="
echo "SonarQube URL : $SONAR_URL"
echo "Component Key : $COMPONENT_KEY"
echo "Severity      : ${SEVERITY:-ALL}"
echo "Status        : ${STATUS:-ALL}"
echo "Output Dir    : $OUTPUT_DIR"
echo "JSON File     : $(basename "$JSON_FILE")"
echo "CSV File      : $(basename "$CSV_FILE")"
echo "=============================================="
echo

# --------------------------------------------------
# Check dependencies
# --------------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required."
    echo
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install curl"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required."
    echo
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

# --------------------------------------------------
# Check SonarQube connection
# --------------------------------------------------
echo "Checking SonarQube connection..."

if ! curl -fsS \
    -u "$SONAR_TOKEN:" \
    "$SONAR_URL/api/system/status" \
    >/dev/null; then

    echo
    echo "ERROR: Unable to connect to SonarQube."
    echo
    echo "Please verify:"
    echo "  - SonarQube URL"
    echo "  - SonarQube token"
    echo "  - Component/project key"
    echo "  - Network connectivity"
    echo "  - Firewall/proxy settings"
    exit 1
fi

echo "SonarQube connection successful."
echo

# --------------------------------------------------
# Cleanup handler
# --------------------------------------------------
TEMP_FILES=()

cleanup() {
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        rm -f "${TEMP_FILES[@]}"
    fi
}

trap cleanup EXIT

# --------------------------------------------------
# Build API URL
# --------------------------------------------------
BASE_URL="$SONAR_URL/api/issues/search"

PAGE=1
PAGE_SIZE=500

echo "Fetching issues..."

while true; do

    QUERY="componentKeys=${COMPONENT_KEY}&ps=${PAGE_SIZE}&p=${PAGE}"

    if [[ -n "$SEVERITY" ]]; then
        QUERY="${QUERY}&severities=${SEVERITY}"
    fi

    if [[ -n "$STATUS" ]]; then
        QUERY="${QUERY}&statuses=${STATUS}"
    fi

    TEMP_FILE=$(mktemp)
    TEMP_FILES+=("$TEMP_FILE")

    HTTP_CODE=$(curl -sS \
        -u "$SONAR_TOKEN:" \
        -o "$TEMP_FILE" \
        -w "%{http_code}" \
        "$BASE_URL?$QUERY")

    if [[ "$HTTP_CODE" != "200" ]]; then
        echo
        echo "ERROR: SonarQube API returned HTTP $HTTP_CODE"
        echo
        cat "$TEMP_FILE"
        exit 1
    fi

    PAGE_ISSUES=$(jq '.issues | length' "$TEMP_FILE")
    TOTAL=$(jq '.total' "$TEMP_FILE")

    echo "  Page $PAGE: $PAGE_ISSUES issues (Total: $TOTAL)"

    if [[ "$PAGE_ISSUES" -eq 0 ]]; then
        break
    fi

    PAGE=$((PAGE + 1))

    if [[ "$PAGE_ISSUES" -lt "$PAGE_SIZE" ]]; then
        break
    fi

done

# --------------------------------------------------
# Merge all pages
# --------------------------------------------------
echo
echo "Creating JSON export..."

jq -s '
    {
        total: (.[0].total // (map(.issues | length) | add)),
        issues: [.[].issues[]?]
    }
' "${TEMP_FILES[@]}" > "$JSON_FILE"

# --------------------------------------------------
# Create CSV
# --------------------------------------------------
echo "Creating CSV export..."

jq -r '
    [
        "Issue Key",
        "Component",
        "File",
        "Line",
        "Rule",
        "Severity",
        "Type",
        "Status",
        "Message",
        "Effort",
        "Tags"
    ],
    (
        .issues[]? |
        [
            .key,
            .component,
            (.component | sub("^[^:]+:"; "")),
            (.line // ""),
            .rule,
            .severity,
            .type,
            .status,
            .message,
            (.effort // ""),
            ((.tags // []) | join(","))
        ]
    ) |
    @csv
' "$JSON_FILE" > "$CSV_FILE"

# --------------------------------------------------
# Summary
# --------------------------------------------------
TOTAL_ISSUES=$(jq '.issues | length' "$JSON_FILE")

echo
echo "=============================================="
echo "             Export Completed"
echo "=============================================="
echo
echo "Issues exported : $TOTAL_ISSUES"
echo
echo "Directory:"
echo "  $OUTPUT_DIR"
echo
echo "JSON:"
echo "  $JSON_FILE"
echo
echo "CSV:"
echo "  $CSV_FILE"
echo
echo "=============================================="