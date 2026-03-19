#!/bin/bash
# ─────────────────────────────────────────────────────────
# publish.sh — Add a synthetic test report to the repo
#
# Usage:
#   ./publish.sh <path-to-report.html> \
#     --site "Simployer.com" \
#     --date "2026-03-17" \
#     --personas "Olivia (HR Admin)" \
#     --task "HRIS AI Evaluation" \
#     --verdict "Conditional" \
#     --verdict-type "mixed"
#
# verdict-type: good | mixed | bad
#
# What it does:
#   1. Copies the HTML report into /reports
#   2. Adds a metadata entry to index.html
#   3. Commits and pushes (triggers Vercel deploy)
# ─────────────────────────────────────────────────────────

set -e

# ── Parse arguments ──
REPORT_FILE=""
SITE=""
DATE=""
PERSONAS=""
TASK=""
VERDICT=""
VERDICT_TYPE="mixed"

while [[ $# -gt 0 ]]; do
  case $1 in
    --site) SITE="$2"; shift 2 ;;
    --date) DATE="$2"; shift 2 ;;
    --personas) PERSONAS="$2"; shift 2 ;;
    --task) TASK="$2"; shift 2 ;;
    --verdict) VERDICT="$2"; shift 2 ;;
    --verdict-type) VERDICT_TYPE="$2"; shift 2 ;;
    -*) echo "Unknown option: $1"; exit 1 ;;
    *) REPORT_FILE="$1"; shift ;;
  esac
done

# ── Validate ──
if [ -z "$REPORT_FILE" ]; then
  echo "❌ Error: No report file specified."
  echo ""
  echo "Usage: ./publish.sh <report.html> --site \"Name\" --date \"YYYY-MM-DD\" \\"
  echo "       --personas \"Persona Name\" --task \"Task desc\" \\"
  echo "       --verdict \"Verdict\" --verdict-type good|mixed|bad"
  exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
  echo "❌ Error: File not found: $REPORT_FILE"
  exit 1
fi

# ── Determine repo root (where this script lives) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
INDEX_FILE="$SCRIPT_DIR/index.html"

mkdir -p "$REPORTS_DIR"

# ── Copy report ──
FILENAME=$(basename "$REPORT_FILE")
cp "$REPORT_FILE" "$REPORTS_DIR/$FILENAME"
echo "✅ Copied report to reports/$FILENAME"

# ── Build the metadata entry ──
# Convert comma-separated personas to JSON array
IFS=',' read -ra PERSONA_ARR <<< "$PERSONAS"
PERSONA_JSON=""
for p in "${PERSONA_ARR[@]}"; do
  p=$(echo "$p" | xargs)  # trim whitespace
  if [ -n "$PERSONA_JSON" ]; then
    PERSONA_JSON="$PERSONA_JSON, "
  fi
  PERSONA_JSON="$PERSONA_JSON\"$p\""
done

ENTRY="    { file: \"$FILENAME\", site: \"$SITE\", date: \"$DATE\", personas: [$PERSONA_JSON], task: \"$TASK\", verdict: \"$VERDICT\", verdictType: \"$VERDICT_TYPE\" },"

# ── Insert entry into index.html (before REPORT_ENTRIES_END marker) ──
# Use a temp file for portability
MARKER="// ── REPORT_ENTRIES_END ──"
TEMP_FILE=$(mktemp)

awk -v entry="$ENTRY" -v marker="$MARKER" '
  $0 ~ marker { print entry }
  { print }
' "$INDEX_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$INDEX_FILE"
echo "✅ Added entry to index.html"

# ── Git commit and push ──
cd "$SCRIPT_DIR"

if git rev-parse --git-dir > /dev/null 2>&1; then
  git add "reports/$FILENAME" index.html
  git commit -m "Add test report: $SITE ($DATE)

Persona: $PERSONAS
Task: $TASK
Verdict: $VERDICT"

  echo ""
  read -p "Push to remote? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
    echo "✅ Pushed to remote — Vercel will auto-deploy"
  else
    echo "ℹ️  Committed locally. Run 'git push' when ready."
  fi
else
  echo ""
  echo "ℹ️  Not a git repo yet. Run these commands first:"
  echo "  git init"
  echo "  git remote add origin <your-repo-url>"
  echo "  git add -A && git commit -m 'Initial commit'"
  echo "  git push -u origin main"
fi

echo ""
echo "🎉 Done! Report will be available at:"
echo "   <your-vercel-url>/reports/$FILENAME"
