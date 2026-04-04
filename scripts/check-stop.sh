#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' .harness/progress.json | head -1 | grep -o '"[^"]*"$' | tr -d '"')
  if [ "$STATUS" = "in_progress" ]; then
    echo "WARNING: Harness has in-progress tasks. Progress is saved in .harness/progress.json and can be resumed next session."
  fi
fi
