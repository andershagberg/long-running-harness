---
name: iterate
description: "Generator-Evaluator feedback loop for tasks requiring quality judgment beyond automated tests. Launches separate generator and evaluator agents in alternating cycles until the evaluator's rubric-based score meets the pass threshold. For 1-4 hour tasks."
user-invocable: true
---

# Iterate: Generator-Evaluator Feedback Loop

Iterative refinement through alternating generation and critical evaluation cycles.

## Task
$ARGUMENTS

## Process

### 1. Initialize harness state

Create `.harness/progress.json`:
```json
{
  "pattern": "iterate",
  "goal": "$ARGUMENTS",
  "started_at": "<current ISO timestamp>",
  "status": "in_progress",
  "current_iteration": 0,
  "max_iterations": 10,
  "pass_threshold": 8,
  "score_progression": [],
  "tasks": [
    {
      "task_id": "task-1",
      "description": "$ARGUMENTS",
      "status": "in_progress"
    }
  ]
}
```

Create `.harness/rubric.json` with evaluation criteria tailored to the task, using a **1-10 scoring scale** (9-10 production-ready, 7-8 minor issues, 5-6 moderate, 3-4 major, 1-2 non-functional). Weight criteria based on what matters most:
- **Correctness** (typically 30-40%): Does it work as specified?
- **Completeness** (typically 20-30%): Are all requirements addressed?
- **Edge Cases** (typically 15-25%): Does it handle boundary conditions?
- **Code Quality** (typically 10-20%): Does it follow project patterns?
- **Test Coverage** (typically 10-20%): Are the important paths tested?

Adjust weights based on the task domain. A data pipeline should weight correctness higher. A UI component should include usability criteria.

Create `.harness/features.json` with a feature list cataloging every user-facing behavior this task should produce, each with step-by-step verification procedures. This file is **immutable** — neither the generator nor evaluator may modify it.

### 2. Feedback loop (max 10 iterations)

For each iteration:

**A. Generator phase**
Launch the `generator` subagent with this context:
- The task description
- Current contents of `.harness/progress.json`
- If iteration > 1: the contents of the latest `.harness/feedback/iteration-NNN.json` — this is the evaluator's specific feedback from the previous cycle

The generator implements (or fixes) the work and updates `.harness/progress.json`.

**B. Evaluator phase**
Launch the `evaluator` subagent with this context:
- The task description
- Contents of `.harness/rubric.json`
- Contents of `.harness/progress.json`
- The iteration number (so it writes to the correct feedback file)

The evaluator independently verifies the work, scores it against the rubric, and writes feedback to `.harness/feedback/iteration-NNN.json`.

**C. Decision**
Read the evaluator's feedback file:
- If `overall_pass == true` AND `score >= 8`: **Stop — task complete**
- If iteration == max_iterations: **Stop — max iterations reached**
- Otherwise: **Continue** to next iteration, carrying forward the feedback

Update `.harness/progress.json` with the current iteration number, latest score, and append to `score_progression`.

### 3. Finalize
Update `.harness/progress.json`:
```json
{
  "status": "completed" or "max_iterations_reached",
  "completed_at": "<current ISO timestamp>",
  "iterations_used": N,
  "final_score": 8.5,
  "score_progression": [4.5, 6.2, 7.8, 8.5]
}
```

### 4. Report
Summarize:
- Iterations used and score progression
- What the generator built
- What the evaluator found (and what was fixed)
- Final score and pass/fail status
- Any remaining issues if max iterations were reached

## When to use
- Features that need quality judgment beyond "tests pass"
- Tasks where edge cases, error handling, and code quality matter
- Work that benefits from an independent critical review
- Anything you'd normally want a code review for before merging
