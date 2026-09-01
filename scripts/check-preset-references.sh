#!/bin/bash
# Verify that every internal preset reference is written in a form Renovate can
# resolve, and points at a file that exists.
#
# Preconditions:
#   - Run from the repository root.
# Postconditions:
#   - Exit 0 when every `github>vspo-lab/config//renovate/<name>` reference has a
#     matching `renovate/<name>.json`, and no reference uses the legacy
#     single-slash colon form. Exit 1 listing the offenders otherwise. Never
#     modifies the working tree.
# Idempotency:
#   - Pure inspection: the same tree always produces the same result.
#
# Why this exists: `default.json` once extended `:groupLinters` and
# `:vulnerabilityAlerts` with no corresponding file, at both main and v1.0.0.
# renovate-config-validator does not resolve remote presets, so nothing caught it.
#
# It now also rejects the legacy `github>vspo-lab/config/renovate:<name>` form.
# That spelling parses, but not the way it reads: Renovate's `parsePreset` splits
# on the first colon, so the repository becomes `vspo-lab/config/renovate` --
# which does not exist -- and the whole preset chain silently fails to load. The
# subdirectory separator has to be a double slash, and a subdirectory preset
# names its file with a slash rather than a colon (`//renovate/minimumReleaseAge`);
# combining `//` with `:` is rejected outright as a prohibited sub-preset.

set -euo pipefail

FAILED=0

# The legacy form resolves to a repository that does not exist. Catch it first,
# since every such reference is silently dead rather than merely dangling.
LEGACY=$(grep -rnoE 'github>vspo-lab/config/renovate:[A-Za-z0-9_-]+' renovate.json renovate/ || true)

if [ -n "$LEGACY" ]; then
  echo "LEGACY FORM  these references resolve to the repository 'vspo-lab/config/renovate', which does not exist:"
  printf '%s\n' "$LEGACY" | sed 's/^/  /'
  echo ""
  echo "  Rewrite as: github>vspo-lab/config//renovate/<name>"
  echo ""
  FAILED=1
fi

# Collect every internal reference of the form
#   github>vspo-lab/config//renovate/<name>
REFS=$(grep -rhoE 'github>vspo-lab/config//renovate/[A-Za-z0-9_-]+' renovate.json renovate/ \
  | sed 's|.*/||' | sort -u)

if [ -z "$REFS" ] && [ "$FAILED" -eq 0 ]; then
  echo "No internal preset references found."
  exit 0
fi

for name in $REFS; do
  if [ -f "renovate/${name}.json" ]; then
    echo "ok       ${name} -> renovate/${name}.json"
  else
    echo "MISSING  ${name} -> renovate/${name}.json does not exist"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "One or more preset references are dead."
  echo "Add the missing file, fix the reference form, or drop it from the extends list."
  exit 1
fi

echo ""
echo "All internal preset references resolve."
