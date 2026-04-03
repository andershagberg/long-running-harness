# Long-Running AI Agent Harness

A reusable harness for long-running AI agent tasks, built entirely with Claude Code native features. Based on:
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Building Long-Running AI Agent Harnesses](https://atalupadhyay.wordpress.com/2026/03/26/building-long-running-ai-agent-harnesses/)

## Quick Start

| Skill | Duration | Use When |
|---|---|---|
| `/sprint <task>` | < 30 min | Tests/linters are the quality gate |
| `/iterate <task>` | 1-4 hours | Needs quality judgment beyond "tests pass" |
| `/orchestrate <goal>` | Multi-hour | Complex enough to need decomposition into sub-tasks |

## Architecture

```
Planner (Opus) ──► plan.json + features.json + rubric.json + init.sh
                         │
           ┌─────────────┼─────────────┐
           ▼             ▼             ▼
       Task 1        Task 2        Task 3
     ┌────────┐    ┌────────┐    ┌────────┐
     │Generate │    │Generate │    │Generate │
     │(Sonnet) │    │(Sonnet) │    │(Sonnet) │
     └───┬────┘    └───┬────┘    └───┬────┘
         │ commit      │ commit      │ commit
         ▼             ▼             ▼
     ┌────────┐    ┌────────┐    ┌────────┐
     │Evaluate│    │Evaluate│    │Evaluate│
     │ (Opus) │    │ (Opus) │    │ (Opus) │
     └───┬────┘    └───┬────┘    └───┬────┘
         │             │             │
    score < 8?    score < 8?    score < 8?
    ◄────┘ loop   ◄────┘ loop   ◄────┘ loop
```

## Key Design Principles

1. **Subagent isolation = free context resets.** Each generator/evaluator gets a fresh context window. No manual reset needed.
2. **Immutable feature list.** `.harness/features.json` catalogs every behavior with verification steps. Generators cannot modify it. JSON format chosen because models are less likely to edit JSON than Markdown.
3. **Skeptical evaluation.** The evaluator assumes the generator's self-assessment is optimistic. A score of 7/10 means "significant issues remain."
4. **Git integration.** Generators commit after each task. Code is always in a merge-ready state.
5. **Init script.** `.harness/init.sh` eliminates environment setup overhead per agent session.
6. **Progress files survive everything.** Context compaction, session restarts, subagent boundaries.

## Agents

- `planner` (Opus, blue) — Decomposes goals into tasks, features, rubrics, and init scripts
- `generator` (Sonnet, green) — Executes single tasks with structured onboarding sequence, commits work
- `evaluator` (Opus, red) — Skeptical critic, 1-10 rubric scoring, feature verification, read-only

## Hooks

- **PreCompact** — Injects progress state into compaction context
- **SessionStart** — Detects resumable harness sessions
- **SubagentStop (generator)** — Blocks if progress.json not updated
- **SubagentStop (evaluator)** — Blocks if feedback file not written
- **Stop** — Warns about incomplete harness tasks

## Runtime State

All in `.harness/` (gitignored):
- `progress.json` — Task tracking, the single source of truth
- `features.json` — Immutable verification spec with step-by-step checks
- `plan.json` — Planner output (orchestrate only)
- `rubric.json` — Evaluation criteria, 1-10 scale
- `init.sh` — Environment setup script
- `feedback/iteration-NNN.json` — Evaluator feedback per cycle

## Scoring

Uses 1-10 scale. Pass threshold: 8.
- **9-10**: Production-ready
- **7-8**: Minor issues, small fixes needed
- **5-6**: Moderate issues, another iteration needed
- **3-4**: Major rework required
- **1-2**: Non-functional

## Harness Maintenance

Every component encodes an assumption about what the model cannot do on its own. As models improve, harnesses should simplify. Audit your harness when a major new model is released — remove components that address outdated limitations.
