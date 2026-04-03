#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  STATUS=$(python3 -c "import json; d=json.load(open('.harness/progress.json')); print(d.get('status',''))")
  PATTERN=$(python3 -c "import json; d=json.load(open('.harness/progress.json')); print(d.get('pattern',''))")
  if [ "$STATUS" = "in_progress" ]; then
    echo "RESUMABLE HARNESS SESSION DETECTED (pattern: $PATTERN). Use /orchestrate, /iterate, or /sprint to resume."
  fi
fi
