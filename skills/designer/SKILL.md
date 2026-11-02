---
name: designer
description: Turn the model-pipeline design step on or off with an interactive picker. When it is on, the pipeline's designer agent draws the proposed design on a doop.design canvas between Read and Plan, and you approve it before planning. The choice is saved per user and applies immediately and in future sessions. Use when the user invokes /model-pipeline:designer or asks to turn the design step on or off.
---

# Turn the design step on or off

Ignore any arguments. Always show the picker.

## 1. Read the current setting

Run this exact command with the Bash tool:

```sh
f="$HOME/.claude/model-pipeline/designer"; if [ -f "$f" ]; then echo "saved=$(tr -d ' \t\r\n' < "$f")"; else echo "saved="; fi
```

Work out the current state:
- If `saved` is `on`, the design step is On (source: saved choice).
- If `saved` is `off`, the design step is Off (source: saved choice).
- If `saved` is empty, the design step is Off (source: default).
- Otherwise, tell the user in one line that the saved value '<saved>' is not on or off and is ignored. The design step is Off (source: default).

If `/model-pipeline:designer` was already run earlier in this conversation, the current state is the one it last reported.

## 2. Ask

Call AskUserQuestion with one question:
- header: `Designer`
- question: `Design step is currently <On or Off> (<source>). Should model-pipeline draw the design on a doop.design canvas before planning?`
- multiSelect: false
- options, in this order:
  1. label `On`, description `Run the design step in this and future sessions. Needs the doop MCP server.`
  2. label `Off`, description `Skip the design step. Deletes the saved choice (off is the default).`

If the user answers with free text, treat `on`, `yes` or `enable` (any case) as On and `off`, `no`, `disable` or `reset` as Off. For anything else, say nothing was changed and stop.

## 3. Save

- **On**: run `mkdir -p "$HOME/.claude/model-pipeline" && printf '%s\n' on > "$HOME/.claude/model-pipeline/designer"`.
- **Off**: run `rm -f "$HOME/.claude/model-pipeline/designer"`.

If the command fails, report the error and stop. Do not claim the setting changed.

## 4. Check doop (On only)

Skip this step for Off.

Check whether any tool whose name starts with `mcp__doop__` is available to you. If your tools are deferred, search for `doop` with ToolSearch. If none is found, run `claude mcp list 2>/dev/null | grep -i doop` with the Bash tool.
- A doop tool was found, or the line contains `Connected`: doop is ready. Add nothing.
- The line contains `Needs authentication`: remember the line `doop needs sign-in: run /mcp, pick doop and approve it in the browser. Until then the design step is skipped.`
- No doop line, or any other status: remember the line `doop MCP is not connected yet. Add it with \`claude mcp add --transport http doop https://doop.design/mcp\`, then run /mcp, pick doop and approve it in the browser. Until then the design step is skipped.`

## 5. Confirm

Output exactly one line:
- For On: `Design step is now **on** for this session and future sessions.`
- For Off: `Design step is now **off** for this session and future sessions.`

If step 4 produced a line, output it on the next line.

From now on in this conversation, run the pipeline's Design stage when this reported on, and skip it when this reported off. This overrides the routing rule's design step line. A per-task request from the user ("skip design" or "with design") still wins for that task.
