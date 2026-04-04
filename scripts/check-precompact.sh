#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  # Read progress, collapse whitespace, escape inner quotes for valid JSON embedding
  PROGRESS=$(cat .harness/progress.json | tr -d '\n' | tr -d '\r' | tr -d '\t' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
  printf '{"systemMessage": "HARNESS STATE — Preserve across compaction: %s"}\n' "$PROGRESS"
fi
