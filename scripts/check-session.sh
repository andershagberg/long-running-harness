#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' .harness/progress.json | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  PATTERN=$(grep -o '"pattern"[[:space:]]*:[[:space:]]*"[^"]*"' .harness/progress.json | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  if [ "$STATUS" = "in_progress" ]; then
    echo "RESUMABLE HARNESS SESSION DETECTED (pattern: $PATTERN). Use /orchestrate, /iterate, or /sprint to resume."
  fi
fi
