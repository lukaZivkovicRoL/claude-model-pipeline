# model-pipeline

Claude Code plugin that splits coding work across models:

| Stage | Agent | Model |
|---|---|---|
| Grill the user on requirements | `haiku-griller` | Haiku |
| Read the repo | `repo-reader` | Haiku |
| Write the plan | `fable-planner` | Fable |
| User approves | (main session) | — |
| Write the code | `haiku-coder` | Haiku |

- `/pipeline <task>` runs the flow explicitly.
- The grill stage asks one question at a time; say "skip grilling" to skip it. Big decisions that come up later get asked too, never guessed.
- A SessionStart hook adds a routing rule, so non-trivial coding tasks go through the flow by default.

## Install

**(GitHub marketplace):**
```
/plugin marketplace add lukaZivkovicRoL/claude-model-pipeline
/plugin install model-pipeline@model-pipeline
```
