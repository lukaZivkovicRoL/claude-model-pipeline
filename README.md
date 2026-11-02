# model-pipeline

Claude Code plugin that splits coding work across models:

| Stage | Agent | Model |
|---|---|---|
| Grill the user on requirements | `haiku-griller` | Haiku |
| Read the repo | `repo-reader` | Haiku |
| Draw the design (opt-in) | `designer` | planner model |
| Write the plan | `planner` | Opus (default), Sonnet or Fable |
| User approves | (main session) | — |
| Write the code | `haiku-coder` | Haiku |
| Review a PR (`grill-pr`) | `repo-reader` → `pr-griller` | Haiku → planner model |

- `/pipeline <task>` runs the flow explicitly.
- `/model-pipeline:planner` switches the planner model (Opus, Sonnet or Fable).
- `/model-pipeline:designer` turns the opt-in design step on or off. See [Design step](#design-step).
- `/model-pipeline:grill-pr [base]` reviews the current branch's changes. It runs only from this command, never automatically. See [Grill a PR](#grill-a-pr).
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

## Design step

Off by default. To turn it on or off, run:

```
/model-pipeline:designer
```

The choice is saved per user in `~/.claude/model-pipeline/designer` and applies from the next task, in this session and future ones. **Off** deletes that file. For a single task you can also say "skip design" (when it is on) or "with design" (when it is off).

The design step uses the [doop](https://doop.design) MCP server. Add it once, then sign in:

```
claude mcp add --transport http doop https://doop.design/mcp
```

Then run `/mcp`, pick **doop** and approve it in the browser. No API key is needed.

When it is on, after the repo is read, `designer` (running on the planner model) draws the proposed UI on a doop canvas. It draws one frame per screen or state, desktop by default and mobile only when the requirements mention it, and it matches the styles and components the readers found. You get the canvas URL and can **Approve** or **Request changes**, in chat or as comments on the canvas. After two revision rounds you choose to approve as-is, continue without the design, or stop. Tasks with no user-facing screen skip the step with a one-line note.

The approved design (canvas URL, frame IDs, a spec per frame, and each frame's HTML) goes to the planner, and the plan references the frames. `haiku-coder` can re-fetch frames and screenshots with read-only doop tools, but never edits them. Fixes started from `grill-pr` never run the design step.

If the design step is on but doop isn't connected, the step is skipped with the setup command above and the pipeline continues to planning.

Frames are stored on doop.design. The designer is told never to put secrets, email addresses, real user data or private source code into them, and to use fake sample data instead. It never uses doop's `generate_image`.

## Grill a PR

```
/model-pipeline:grill-pr [base]
```

Reviews only what the current branch changed against its merge-base with the base branch: commits, staged and unstaged changes, and untracked files. Unless you pass a base, it uses a development branch if one exists (`develop`, `development` or `dev`, where PRs usually merge before production), then origin's default branch, then `main`, then `master`. On the base branch itself, only uncommitted work is reviewed.

`repo-reader` (Haiku) collects the impact context: callers of changed symbols, related config, docs and tests, duplicated helpers, and code the change leaves unused. `pr-griller` then reviews on the planner model and reports:

- **Findings** ranked Blocker / Major / Minor / Nit: holes, broken callers, missing tests or docs
- **Decisions with wider impact** that other code relies on
- **Cleanup**: unused or unnecessary code, with evidence that it's safe to remove
- a one-line **Verdict**

Afterwards it offers to fix the selected findings through the normal pipeline (plan → approve → code). Open decisions are asked first, never assumed.

## Install

**(GitHub marketplace):**
```
/plugin marketplace add lukaZivkovicRoL/claude-model-pipeline
/plugin install model-pipeline@model-pipeline
```
