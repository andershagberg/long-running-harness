#!/usr/bin/env bash
if [ -f .harness/progress.json ]; then
  STATUS=$(python3 -c "import json; d=json.load(open('.harness/progress.json')); print(d.get('status',''))")
  if [ "$STATUS" = "in_progress" ]; then
    echo "WARNING: Harness has in-progress tasks. Progress is saved in .harness/progress.json and can be resumed next session."
  fi
fi
