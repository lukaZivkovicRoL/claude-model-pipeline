---
name: pipeline
description: Run a coding task through the model pipeline — haiku-griller (Haiku) grills the user on requirements, repo-reader (Haiku) gathers context, optionally designer (planner model) draws the design on a doop.design canvas for the user to approve, planner (Opus, Sonnet or Fable) writes the plan, the user approves it, then haiku-coder (Haiku) implements it. Use when the user invokes /pipeline, or for any non-trivial code change.
argument-hint: <task description>
---

# Model pipeline: grill (Haiku) → read (Haiku) → design (opt-in, planner model) → plan (Opus, Sonnet or Fable) → approve → code (Haiku)

You are the orchestrator. Do not interview the user on your own, read the codebase deeply, draw the design, write the plan, or write code yourself. Delegate those to the workers. Your job is to route context between them, talk to the user, and check the result.

Workers do not see this conversation. Every worker prompt must be self-contained: the task, the relevant user requirements, the project rules (from CLAUDE.md / AGENTS.md and anything else in your context), and the previous stage's output, copied in full.

Task: $ARGUMENTS (if empty, use the user's latest request).

## 1. Grill: `haiku-griller`
- Skip this stage if the user asked to skip grilling up front.
- Spawn one `haiku-griller` with the task, the project rules, and any constraints the user has already stated.
- Loop: when it returns **Question**, ask exactly that question with AskUserQuestion, using its header and options as given. Then SendMessage the answer to the same agent. Pass free-text "Other" answers through verbatim.
- If the user says "skip grilling", "enough", or similar, tell the griller to finish now and return its brief.
- When it returns **Done**, keep the Requirements brief for the next stages.

## 2. Read: `repo-reader`
- Split the task into independent areas (for example, UI, data layer, backend) and spawn one `repo-reader` per area, at most 3, in a single message so they run in parallel. Use one reader when the scope is narrow.
- Tell each reader what to look for and why, and include the Requirements brief so it focuses on what was decided.
- When the design step will run (see stage 3), also ask the reader covering the UI to report the existing styles, design tokens, components and layout patterns that a new screen should match, with file paths.

## 3. Design: `designer` (opt-in)
- **When to run.** The design step is on or off for the session. If `/model-pipeline:designer` was run in this conversation, use the state it last reported. Otherwise use the routing rule's line "Design step for this session". If neither is in your context, run `f="$HOME/.claude/model-pipeline/designer"; [ -f "$f" ] && tr -d ' \t\r\n' < "$f"` with Bash: `on` means on, anything else means off. A per-task request wins over the session state: if the user asked to skip design for this task, treat it as off; if the user asked for a design for this task (for example "with design"), treat it as on. When it is off, skip this stage silently and go to stage 4.
- If neither the Requirements brief nor the reader briefs involve any user-facing screen (for example, a pure backend, CLI or config change), output `Design step skipped: this task has no UI to draw.` and go to stage 4.
- **Check that doop is available.** Check whether any tool whose name starts with `mcp__doop__` is available to you. If your tools are deferred, search for `doop` with ToolSearch. If none is found, run `claude mcp list 2>/dev/null | grep -i doop` with Bash. doop is available only if a doop tool was found or that line contains `Connected`. Otherwise output one line and go to stage 4:
  - if the line contains `Needs authentication`: `Design step skipped: doop needs sign-in. Run /mcp, pick doop and approve it in the browser.`
  - otherwise: `Design step skipped: doop MCP is not connected. Add it with \`claude mcp add --transport http doop https://doop.design/mcp\`, then run /mcp and approve doop in the browser.`
- **Spawn.** Spawn one `designer` with the task, the Requirements brief and all reader briefs verbatim, the project rules, and any user constraints. Tell it that the brief's Decisions made are settled and must not be asked again. Pass the Agent tool's `model` set to the same model you use for `planner` in stage 4.
- If the designer returns **Blocked**, output `Design step skipped: <its reason in one line>.` and go to stage 4.
- **Open questions.** If the Design brief's Open questions include a big decision, ask it as described in "Unanticipated decisions" below, before the review. If an answer changes the design, SendMessage the answers to the same `designer` and wait for its updated Design brief. This does not count as a revision round.
- **Review.** Show the user the canvas URL, the Frames list (name and what each shows), and the Design decisions. Do not show the Frame HTML. Then call AskUserQuestion:
  - header: `Design`
  - question: `Review the design at <canvas URL>. You can also leave comments on the canvas. Use this design?`
  - options: `Approve` (description `Use this design for the plan.`) and `Request changes` (description `Describe the changes here, or leave comments on the canvas and say so.`)
- **Request changes.** SendMessage to the same `designer`: the user's feedback verbatim, plus `Also call get_feedback on canvas <canvas ID> and apply the canvas comments. Return an updated Design brief.` If that agent can't be reached, spawn a new `designer` with all the inputs above plus the canvas ID and the feedback. Then review again. This is one revision round.
- **Round limit.** At most 2 revision rounds. After the second revised Design brief, show it as in Review, then call AskUserQuestion instead of the Review question:
  - header: `Design`
  - question: `Two revision rounds are done. Review <canvas URL>. How should the pipeline continue?`
  - options: `Approve as-is` (description `Use the current design for the plan.`), `Continue without design` (description `Plan without a design. The canvas stays on doop.design.`), `Stop` (description `Stop the pipeline here.`)
  - If the user answers with free text, ask the same question again.
- **Result.** On `Approve` or `Approve as-is`, keep the latest Design brief verbatim, including Frame HTML, as the approved Design brief for stages 4 and 6. On `Continue without design`, go to stage 4 without a Design brief. On `Stop`, stop the pipeline and tell the user the canvas URL.

## 4. Plan: `planner`
- Spawn one `planner` with the task, the Requirements brief and all reader briefs verbatim, the project rules, and any user constraints. Tell it that the brief's Decisions made are settled and must not be asked again.
- If there is an approved Design brief, include it verbatim, including Frame HTML. Tell the planner that the user approved this design and the plan must follow it. Each step that builds a screen must name the frame ID it follows, and the plan must include the canvas URL. If the design conflicts with the codebase or the Requirements brief, the planner lists it under Decisions needed instead of changing the design.
- Pass the Agent tool's `model` set to the session's planner model from the routing rule (default `opus`), or to the model the user asked for on this task (`opus`, `sonnet` or `fable`). If `/model-pipeline:planner` was run in this conversation, the model it reported takes precedence over the routing rule. Follow-ups go to the same agent via SendMessage, so they keep that model.
- If the planner lists **Decisions needed**, handle them as described in "Unanticipated decisions" below, then send the answers back to `planner` (SendMessage to the same agent) for a final plan.

## 5. Checkpoint: user approves the plan
- **In plan mode:** write the plan to the plan file and call ExitPlanMode.
- **Otherwise:** show the plan (summary + steps, concise) and ask with AskUserQuestion: Approve / Request changes.
- Send requested changes back to `planner`. Never start coding without approval.

## 6. Code: `haiku-coder`
- Spawn `haiku-coder` with the full approved plan, project rules, and the "Do not touch" list.
- If there is an approved Design brief, include it verbatim, including Frame HTML. Tell the coder it may re-check frames with its read-only doop tools (`get_canvas`, `get_frame`, `get_frame_screenshot`, `export_frame`) and must never create or edit frames.
- Only when steps touch disjoint files and don't depend on each other, you may split them across parallel coders (max 3, single message). Otherwise use one coder.

## 7. Check and report
- Read `git diff` and compare it to the plan. Flag anything outside the plan.
- If the coder reported a blocker or a failing verification, send the issue back to `haiku-coder` once with the error and the relevant plan step. If it still fails, stop and ask the user, or send the problem back to `planner` for a revised step.
- Report to the user: what changed (files), verification results as observed, and anything skipped. Don't commit unless the user asks.

## Unanticipated decisions: ask, don't guess
This applies to every stage after the grill. A big decision is one that the Requirements brief doesn't cover and that changes behaviour, UX, the data model, a public API, user-visible naming, dependencies, or the scope, or one that is expensive to reverse. Never pick one on the user's behalf.
- **Read:** if a reader's Open questions include a big decision, ask the user before planning.
- **Design:** if the designer's Open questions include a big decision, ask the user one at a time with AskUserQuestion, recommendation first, before the design review and before planning. Add the answers to the Requirements brief under Decisions made.
- **Plan:** ask about each of the planner's Decisions needed one at a time with AskUserQuestion, recommendation first. Add the answers to the Requirements brief under Decisions made.
- **Code:** if `haiku-coder` reports **Decision needed**, ask the user, send the answer to `planner` for a revised step, and give the coder that step. Neither you nor the coder improvises the choice.
- Small, reversible details that follow existing conventions are not escalated. Workers follow the conventions.

## When to skip the pipeline
Pure questions, and trivial edits such as a typo, a one-line change, or a single known spot: handle them directly and say that you did.
