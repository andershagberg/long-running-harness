---
name: sprint
description: "Quick single-agent task with automated validation. For focused tasks under 30 minutes where tests and linters are the quality gate. No evaluator needed — hard validation is the check."
user-invocable: true
---

# Sprint: Single Agent + Hard Validation

Fast, focused implementation with automated test/lint validation as the quality gate.

## Task
$ARGUMENTS

## Process

### 1. Initialize harness state
Create `.harness/progress.json`:
```json
{
  "pattern": "sprint",
  "goal": "$ARGUMENTS",
  "started_at": "<current ISO timestamp>",
  "status": "in_progress",
  "tasks": [
    {
      "task_id": "task-1",
      "description": "$ARGUMENTS",
      "status": "in_progress",
      "iteration": 0,
      "max_iterations": 5
    }
  ]
}
```

### 2. Set up environment
- If `.harness/init.sh` exists, run `bash .harness/init.sh`
- Run `git log --oneline -10` to understand recent state
- Run the test suite once to establish a baseline (know what's already broken vs. what you break)

### 3. Implement
- Read relevant existing code to understand patterns and conventions
- Implement the task following existing project patterns
- Keep changes minimal and focused

### 4. Validate and fix loop (max 5 iterations)
Run validation in this order:
1. **Type checker** (if configured): `npx tsc --noEmit`, `mypy`, `go vet`, etc.
2. **Linter** (if configured): `npm run lint`, `ruff check`, `golangci-lint run`, etc.
3. **Tests**: `npm test`, `pytest`, `go test ./...`, etc.

If any validation fails:
- Read the error output carefully
- Fix the specific issue
- Re-run validation
- Increment the iteration counter in progress.json
- Repeat until all pass or 5 iterations exhausted

### 5. Commit
```bash
git add <specific files modified>
git commit -m "harness(sprint): <concise description of what was done>"
```

### 6. Finalize
Update `.harness/progress.json` with final status:
```json
{
  "status": "completed" or "failed",
  "completed_at": "<current ISO timestamp>",
  "iterations_used": N,
  "commit_sha": "<sha>",
  "tasks": [{ "status": "completed", "files_modified": [...], "test_results": "...", "notes": "..." }]
}
```

### 7. Report
Summarize: what was done, files changed, iterations needed, final test status.

## When to use
- Bug fixes with existing test coverage
- Small features with clear acceptance tests
- Refactors where tests verify correctness
- Any task where "tests pass + lint clean" = done
