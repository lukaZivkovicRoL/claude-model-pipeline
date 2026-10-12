# model-pipeline

Claude Code plugin that splits coding work across models:

| Stage | Agent | Model |
|---|---|---|
| Read the repo | `repo-reader` | Haiku |
| Write the plan | `fable-planner` | Fable |
| User approves | (main session) | — |
| Write the code | `haiku-coder` | Haiku |

- `/pipeline <task>` runs the flow explicitly.
- A SessionStart hook adds a routing rule, so non-trivial coding tasks go through the flow by default.

## Install

**(GitHub marketplace):**
```
/plugin marketplace add <github-user>/claude-model-pipeline
/plugin install model-pipeline@model-pipeline
```
