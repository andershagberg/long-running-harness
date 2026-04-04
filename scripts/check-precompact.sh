#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  PROGRESS=$(cat .harness/progress.json | tr -d '\n' | tr -d '\r' | tr -d '\t')
  # Use printf with %s to avoid shell expansion of special characters in JSON
  printf '{"systemMessage": "HARNESS STATE — Preserve across compaction: %s"}\n' "$PROGRESS"
fi
