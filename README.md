# Long-Running Harness

A Claude Code plugin that provides structured harnesses for long-running AI agent tasks. Based on [Anthropic's effective harness patterns](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and [Building Long-Running AI Agent Harnesses](https://atalupadhyay.wordpress.com/2026/03/26/building-long-running-ai-agent-harnesses/).

## What It Does

Prevents the three root causes of agent failure in long-running tasks:

1. **Context window exhaustion** — Each agent gets a fresh context window; progress persists in files, not memory
2. **Self-approval bias** — A separate skeptical evaluator scores work against rubrics; the generator never judges its own output
3. **Task underscoping** — A planner agent decomposes vague goals into specific tasks with definitions of done

## Install

### As a Claude Code Plugin (recommended)

```bash
# Add this repo as a marketplace
/plugin marketplace add andershagberg/long-running-harness

# Install the plugin
/plugin install long-running-harness
```

After installing, skills are available as `/long-running-harness:sprint`, `/long-running-harness:iterate`, `/long-running-harness:orchestrate`.

### Direct Project Use

Copy the plugin files into your project:

```bash
# Copy agents, skills, hooks, scripts, and CLAUDE.md into your project
cp -r agents/ skills/ hooks/ scripts/ CLAUDE.md /path/to/your-project/
```

Skills are then available as `/sprint`, `/iterate`, `/orchestrate`.

## Three Skills

| Skill | Duration | What It Does |
|---|---|---|
| `/sprint <task>` | < 30 min | Single agent + automated validation (tests/linters). No evaluator. |
| `/iterate <task>` | 1-4 hours | Generator-Evaluator feedback loop. Iterates until rubric score >= 8/10. |
| `/orchestrate <goal>` | Multi-hour | Planner decomposes goal, then runs `/iterate` per sub-task. Session resumable. |

## Architecture

```
                    /orchestrate
                         |
                    +---------+
                    | Planner |  (Opus)
                    +---------+
                         |
              plan.json + features.json + rubric.json + init.sh
                         |
           +-------------+-------------+
           |             |             |
       Task 1        Task 2        Task 3
           |             |             |
     +===========+ +===========+ +===========+
     | Generator | | Generator | | Generator |  (Sonnet)
     |  commit   | |  commit   | |  commit   |
     +-----------+ +-----------+ +-----------+
     | Evaluator | | Evaluator | | Evaluator |  (Opus)
     |  score    | |  score    | |  score    |
     +===========+ +===========+ +===========+
     score < 8?    score < 8?    score < 8?
       loop          loop          loop
```

## Key Artifacts

All runtime state lives in `.harness/` (gitignored):

| File | Purpose | Who Creates | Who Reads | Mutable? |
|---|---|---|---|---|
| `plan.json` | Sequenced tasks with definitions of done | Planner | Generator, Evaluator | No |
| `features.json` | Comprehensive feature list with verification steps | Planner | Evaluator | **Never** |
| `rubric.json` | Weighted evaluation criteria (1-10 scale) | Planner | Evaluator | No |
| `init.sh` | Environment setup script | Planner | Generator | Generator can extend |
| `progress.json` | Task completion tracking — single source of truth | Skills | All agents | Yes |
| `feedback/iteration-NNN.json` | Evaluator feedback per cycle | Evaluator | Generator (next cycle) | No |

## Agents

| Agent | Model | Role | Tools |
|---|---|---|---|
| `planner` | Opus | Decomposes goals, creates feature lists and rubrics | Read, Grep, Glob, Write, Bash |
| `generator` | Sonnet | Implements tasks, commits code, updates progress | Read, Write, Edit, Grep, Glob, Bash |
| `evaluator` | Opus | Skeptical critic, rubric scoring, feature verification | Read, Grep, Glob, Bash (read-only) |

## Hooks

| Hook | Purpose |
|---|---|
| **PreCompact** | Injects progress.json into compaction context — state survives context resets |
| **SessionStart** | Detects resumable harness sessions |
| **SubagentStop (generator)** | Blocks if progress.json not updated |
| **SubagentStop (evaluator)** | Blocks if feedback file not written |
| **Stop** | Warns about incomplete harness tasks |

## Scoring

Uses 1-10 scale. Pass threshold: 8.

| Score | Meaning |
|---|---|
| 9-10 | Production-ready |
| 7-8 | Minor issues, small fixes needed |
| 5-6 | Moderate issues, another iteration |
| 3-4 | Major rework required |
| 1-2 | Non-functional |

## Customization

### Custom Rubrics

Provide a `.harness/rubric.json` before running — the planner will use it instead of generating one. Weight criteria for your domain:

- **Code**: Correctness 35%, Edge Cases 25%, Quality 20%, Tests 20%
- **Compliance audit**: Regulatory Coverage 40%, Evidence Quality 30%, Actionability 20%, Completeness 10%
- **Data pipeline**: Correctness 50%, Performance 20%, Error Handling 20%, Documentation 10%

### Browser Automation

For UI tasks, configure a browser automation MCP server (e.g., Puppeteer) so the evaluator can test features as a user would. Without this, UI features are only verified by code reading.

## Harness Maintenance

> "Every component of your harness encodes an assumption about what the model cannot do on its own."

As models improve, harnesses should simplify. Audit your harness when a major model is released — remove components that address outdated limitations.

## License

MIT
