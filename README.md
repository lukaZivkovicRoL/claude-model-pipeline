# model-pipeline

Claude Code plugin that splits coding work across models:

| Stage | Agent | Model |
|---|---|---|
| Grill the user on requirements | `haiku-griller` | Haiku |
| Read the repo | `repo-reader` | Haiku |
| Write the plan | `planner` | Opus (default), Sonnet or Fable |
| User approves | (main session) | — |
| Write the code | `haiku-coder` | Haiku |

- `/pipeline <task>` runs the flow explicitly.
- `/model-pipeline:planner` switches the planner model (Opus, Sonnet or Fable).
- The grill stage asks one question at a time; say "skip grilling" to skip it. Big decisions that come up later get asked too, never guessed.
- A SessionStart hook adds a routing rule, so non-trivial coding tasks go through the flow by default.

## Planner model

The planner runs on Opus by default. To switch, run:

```
/model-pipeline:planner
```

It opens a picker showing the current model, with **Opus**, **Sonnet**, **Fable** and **Reset to default**. The choice applies from the next task in the current session and is saved per user in `~/.claude/model-pipeline/planner`, so future sessions use it too. **Reset to default** deletes that file.

You can also set the default with an env var in your settings and restart Claude Code:

```json
// ~/.claude/settings.json
{ "env": { "MODEL_PIPELINE_PLANNER": "fable" } }
```

Accepted values are `opus`, `sonnet` and `fable`. Precedence: the saved `/model-pipeline:planner` choice, then `MODEL_PIPELINE_PLANNER`, then `opus`. Invalid values are ignored with a warning. For a single task, just ask (for example, "use the sonnet planner for this").

## Install

**(GitHub marketplace):**
```
/plugin marketplace add lukaZivkovicRoL/claude-model-pipeline
/plugin install model-pipeline@model-pipeline
```
