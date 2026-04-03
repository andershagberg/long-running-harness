---
name: orchestrate
description: "Full planned pipeline for multi-hour tasks. Decomposes the goal via a planner agent, then runs generator-evaluator feedback loops for each sub-task in dependency order, tracking progress across the entire pipeline. Supports session resumption."
user-invocable: true
---

# Orchestrate: Full Planned Multi-Task Pipeline

Complete harness: planning, decomposition, iterative execution, evaluation, and progress tracking across multiple sub-tasks.

## Goal
$ARGUMENTS

## Process

### 0. Check for resumable session
Read `.harness/progress.json`. If it exists and has `"pattern": "orchestrate"` with incomplete tasks:
- Show the user what was completed and what remains
- Ask: "Resume from where we left off, or start fresh?"
- If resuming: skip to Step 3, continuing from the first incomplete task
- If starting fresh: delete `.harness/` contents and proceed to Step 1

### 1. Planning phase
Launch the `planner` subagent with:
> Decompose this goal into implementable tasks: $ARGUMENTS
>
> Read the codebase first to understand existing patterns, then write:
> - `.harness/plan.json` with sequenced tasks, dependencies, and definition of done
> - `.harness/features.json` with comprehensive feature list and verification steps (IMMUTABLE)
> - `.harness/rubric.json` with weighted evaluation criteria per task (1-10 scale, threshold 8)
> - `.harness/init.sh` with environment setup commands
> - Create a Claude Code Task for each planned task

### 2. Initialize execution state
Read `.harness/plan.json`. Create `.harness/progress.json`:
```json
{
  "pattern": "orchestrate",
  "goal": "$ARGUMENTS",
  "started_at": "<current ISO timestamp>",
  "status": "in_progress",
  "total_tasks": N,
  "completed_tasks": 0,
  "failed_tasks": 0,
  "tasks": [
    {
      "task_id": "task-1",
      "description": "from plan",
      "dependencies": [],
      "status": "pending",
      "iterations_used": 0,
      "final_score": null
    }
  ]
}
```

### 3. Execute tasks in dependency order

For each task where all dependencies are satisfied (status == "completed"):

**A. Mark task in-progress**
Update the task's status to `"in_progress"` in `.harness/progress.json`.

**B. Run the iterate loop for this task**
Run the same generator-evaluator feedback loop as the `/iterate` skill:
- Max 10 iterations per task
- Pass threshold: 8 (on 1-10 scale)
- Generator gets: task description + progress + feedback + features.json awareness
- Evaluator gets: task rubric + progress + code state + features.json for verification
- Loop until pass or max iterations

**C. Record result**
Update `.harness/progress.json`:
- Set task status to `"completed"` or `"failed"`
- Record `iterations_used` and `final_score`
- Increment `completed_tasks` or `failed_tasks`

**D. Handle failure**
If a task fails after max iterations:
- Record the failure with the evaluator's latest feedback
- Check if any downstream tasks depend on this one
- If downstream tasks are blocked: note them as `"blocked"` in progress
- Continue to the next unblocked task — do not stop the entire pipeline

### 4. Final evaluation
After all tasks are attempted, launch the `evaluator` subagent with:
> Evaluate the entire project against these global completion criteria:
> [from `.harness/plan.json` global_completion_criteria]
>
> Check that all the pieces integrate correctly as a whole, not just individually.
> Write your evaluation to `.harness/feedback/final-evaluation.json`

### 5. Finalize
Update `.harness/progress.json`:
```json
{
  "status": "completed" or "partially_completed",
  "completed_at": "<current ISO timestamp>",
  "total_tasks": N,
  "completed_tasks": X,
  "failed_tasks": Y,
  "blocked_tasks": Z,
  "final_evaluation_score": 8.5,
  "features_passing": "12/15"
}
```

### 6. Report
Summarize the full pipeline:
- Tasks planned vs completed vs failed vs blocked
- Iterations and scores per task
- Total time elapsed
- Final evaluation result
- Any remaining gaps or follow-up work needed

## When to use
- Large features spanning multiple files or modules
- Greenfield components requiring design decomposition
- Major refactors that must be done in stages
- Any task complex enough to need a plan before starting
