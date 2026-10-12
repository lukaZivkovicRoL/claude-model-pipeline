---
name: planner
description: Switch the model-pipeline planner model (opus, sonnet or fable) with an interactive picker, or reset it to the default. The choice is saved per user and applies immediately and in future sessions. Use when the user invokes /model-pipeline:planner or asks to change the default planner model.
---

# Switch the planner model

Ignore any arguments. Always show the picker.

## 1. Read the current setting

Run this exact command with the Bash tool:

```sh
f="$HOME/.claude/model-pipeline/planner"; if [ -f "$f" ]; then echo "saved=$(tr -d ' \t\r\n' < "$f")"; else echo "saved="; fi; echo "env=${MODEL_PIPELINE_PLANNER:-}"
```

Work out the currently active model:
- If `saved` is `opus`, `sonnet` or `fable`, the active model is that value (source: saved choice).
- Otherwise, if `saved` is not empty, the saved file is invalid. Tell the user in one line that the saved value is not opus, sonnet or fable and is ignored, then continue with the next rule.
- Otherwise, if `env` is `opus`, `sonnet` or `fable`, the active model is that value (source: MODEL_PIPELINE_PLANNER).
- Otherwise the active model is `opus` (source: default). If `env` was not empty, tell the user in one line that MODEL_PIPELINE_PLANNER='<env>' is not opus, sonnet or fable and is ignored.

Also work out the **default model**, which is the model that applies when nothing is saved. That is `env` if it is `opus`, `sonnet` or `fable`, otherwise `opus`.

If `/model-pipeline:planner` was already run earlier in this conversation, the active model is the one it last reported.

## 2. Ask

Call AskUserQuestion with one question:
- header: `Planner`
- question: `Planner model is currently <active model> (<source>). Which planner model should model-pipeline use?`
- multiSelect: false
- options, in this order:
  1. label `Opus`, description `Use Opus for the planner in this and future sessions.`
  2. label `Sonnet`, description `Use Sonnet for the planner in this and future sessions.`
  3. label `Fable`, description `Use Fable for the planner in this and future sessions.`
  4. label `Reset to default`, description `Delete the saved choice. Falls back to MODEL_PIPELINE_PLANNER, then opus (currently <default model>).`

If the user answers with free text, treat `opus`, `sonnet` or `fable` (any case) as that option and `reset` or `default` as Reset. For anything else, say nothing was changed and stop.

## 3. Save

- **Opus**: run `mkdir -p "$HOME/.claude/model-pipeline" && printf '%s\n' opus > "$HOME/.claude/model-pipeline/planner"`. The new model is `opus`.
- **Sonnet**: run `mkdir -p "$HOME/.claude/model-pipeline" && printf '%s\n' sonnet > "$HOME/.claude/model-pipeline/planner"`. The new model is `sonnet`.
- **Fable**: run `mkdir -p "$HOME/.claude/model-pipeline" && printf '%s\n' fable > "$HOME/.claude/model-pipeline/planner"`. The new model is `fable`.
- **Reset to default**: run `rm -f "$HOME/.claude/model-pipeline/planner"`. The new model is the default model from step 1.

If the command fails, report the error and stop. Do not claim the model changed.

## 4. Confirm

Output exactly one line:
- For Opus, Sonnet or Fable: `Planner model is now **<model>** for this session and future sessions.`
- For reset: `Planner choice reset. Planner model is now **<model>** (from <MODEL_PIPELINE_PLANNER or default>) for this session and future sessions.`

From now on in this conversation, spawn `planner` with the Agent tool's `model` set to this model. This overrides the routing rule's planner line. A per-task request from the user for another model still wins for that task.
