#!/bin/bash
# Verify that every internal preset reference resolves to a file that exists.
#
# Preconditions:
#   - Run from the repository root.
# Postconditions:
#   - Exit 0 when every `github>vspo-lab/config/renovate:<name>` reference has a
#     matching `renovate/<name>.json`. Exit 1 listing the dangling references
#     otherwise. Never modifies the working tree.
# Idempotency:
#   - Pure inspection: the same tree always produces the same result.
#
# Why this exists: `default.json` once extended `:groupLinters` and
# `:vulnerabilityAlerts` with no corresponding file, at both main and v1.0.0.
# renovate-config-validator does not resolve remote presets, so nothing caught it.

set -euo pipefail

MISSING=0

# Collect every internal reference of the form
#   github>vspo-lab/config/renovate:<name>
REFS=$(grep -rhoE 'github>vspo-lab/config/renovate:[A-Za-z0-9_-]+' renovate.json renovate/ \
  | sed 's/.*://' | sort -u)

if [ -z "$REFS" ]; then
  echo "No internal preset references found."
  exit 0
fi

for name in $REFS; do
  if [ -f "renovate/${name}.json" ]; then
    echo "ok       ${name} -> renovate/${name}.json"
  else
    echo "MISSING  ${name} -> renovate/${name}.json does not exist"
    MISSING=1
  fi
done

if [ "$MISSING" -ne 0 ]; then
  echo ""
  echo "One or more presets are referenced but do not exist."
  echo "Add the file, or remove the reference from the extends list."
  exit 1
fi

echo ""
echo "All internal preset references resolve."
