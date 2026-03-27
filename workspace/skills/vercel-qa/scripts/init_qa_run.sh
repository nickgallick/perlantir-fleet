#!/usr/bin/env bash
set -euo pipefail

RUN_NAME="${1:-manual}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ROOT="/tmp/qa-runs/${RUN_NAME}-${STAMP}"
SHOT_DIR="$ROOT/screenshots"
ARTIFACT_DIR="$ROOT/artifacts"
REPORT_MD="$ROOT/uat-report.md"
REPORT_JSON="$ROOT/uat-report.json"

mkdir -p "$SHOT_DIR" "$ARTIFACT_DIR"

cat > "$REPORT_JSON" <<JSON
{
  "runName": "${RUN_NAME}",
  "root": "$ROOT",
  "screenshotsDir": "$SHOT_DIR",
  "artifactsDir": "$ARTIFACT_DIR",
  "reportMarkdown": "$REPORT_MD",
  "reportJson": "$REPORT_JSON",
  "productMap": {},
  "productGaps": [],
  "bugs": [],
  "uxIssues": [],
  "passed": [],
  "summary": {}
}
JSON

cat > "$REPORT_MD" <<MD
## 🧪 UAT REPORT: [App Name] — [URL]

## 📋 PRODUCT MAP
- Purpose:
- Users:
- Roles:
- Core flows:
- Main entities:
- Expected vs actual:

## 🚨 PRODUCT GAPS
- None yet

## ❌ BUGS
- None yet

## ⚠️ UX ISSUES
- None yet

## ✅ PASSED
- None yet

## 📊 SUMMARY
- Total tests:
- Passed:
- Failed:
- Product gaps:
- UX issues:

## 🏁 VERDICT
- NEEDS WORK

## 📎 SCREENSHOTS
- Add screenshot paths and descriptions here
MD

echo "$ROOT"
