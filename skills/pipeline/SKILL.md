---
name: pipeline
description: Run a coding task through the model pipeline — repo-reader (Haiku) gathers context, fable-planner (Fable) writes the plan, the user approves it, then haiku-coder (Haiku) implements it. Use when the user invokes /pipeline, or for any non-trivial code change.
argument-hint: <task description>
---

# Model pipeline: read (Haiku) → plan (Fable) → approve → code (Haiku)

You are the orchestrator. Do not read the codebase deeply, write the plan, or write code yourself. Delegate those to the workers. Your job is to route context between them, talk to the user, and check the result.

Workers do not see this conversation. Every worker prompt must be self-contained: the task, the relevant user requirements, the project rules (from CLAUDE.md / AGENTS.md and anything else in your context), and the previous stage's output, copied in full.

Task: $ARGUMENTS (if empty, use the user's latest request).

## 1. Read: `repo-reader`
- Split the task into independent areas (for example, UI, data layer, backend) and spawn one `repo-reader` per area, at most 3, in a single message so they run in parallel. Use one reader when the scope is narrow.
- Tell each reader what to look for and why.

## 2. Plan: `fable-planner`
- Spawn one `fable-planner` with the task, all reader briefs verbatim, the project rules, and any user constraints.
- If the planner lists **Decisions needed**, ask the user with AskUserQuestion (multiple choice, recommendation first). Then send the answers back to `fable-planner` (SendMessage to the same agent) for a final plan.

## 3. Checkpoint: user approves the plan
- **In plan mode:** write the plan to the plan file and call ExitPlanMode.
- **Otherwise:** show the plan (summary + steps, concise) and ask with AskUserQuestion: Approve / Request changes.
- Send requested changes back to `fable-planner`. Never start coding without approval.

## 4. Code: `haiku-coder`
- Spawn `haiku-coder` with the full approved plan, project rules, and the "Do not touch" list.
- Only when steps touch disjoint files and don't depend on each other, you may split them across parallel coders (max 3, single message). Otherwise use one coder.

## 5. Check and report
- Read `git diff` and compare it to the plan. Flag anything outside the plan.
- If the coder reported a blocker or a failing verification, send the issue back to `haiku-coder` once with the error and the relevant plan step. If it still fails, stop and ask the user, or send the problem back to `fable-planner` for a revised step.
- Report to the user: what changed (files), verification results as observed, and anything skipped. Don't commit unless the user asks.

## When to skip the pipeline
Pure questions, and trivial edits such as a typo, a one-line change, or a single known spot: handle them directly and say that you did.
