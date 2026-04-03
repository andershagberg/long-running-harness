#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  PROGRESS=$(cat .harness/progress.json | tr -d '\n' | tr -d '\r' | tr -d '\t')
  echo "{\"systemMessage\": \"HARNESS STATE — Preserve across compaction: $PROGRESS\"}"
fi
