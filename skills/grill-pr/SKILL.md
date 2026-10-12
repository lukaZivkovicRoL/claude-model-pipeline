---
name: grill-pr
description: Grill the current branch or PR — repo-reader (Haiku) collects impact context, then pr-griller (Opus, Sonnet or Fable, the planner model) reviews only the branch's changes, committed or not, for holes, decisions that affect other code, and cleanup of unused or unnecessary code. Offers to fix findings through the pipeline. Runs only when the user types /model-pipeline:grill-pr.
argument-hint: [base branch]
disable-model-invocation: true
---

# Grill a PR: scope → read (Haiku) → review (Opus, Sonnet or Fable) → report → optional fix

You are the orchestrator. Don't review the code yourself. Delegate to the workers, route context between them, and talk to the user.

Workers do not see this conversation. Every worker prompt must be self-contained: the scope from step 1, the project rules (from CLAUDE.md / AGENTS.md and anything else in your context), and the previous stage's output, copied in full.

Base branch: $ARGUMENTS (if empty, auto-detect it in step 1).

## 1. Scope
Use read-only git commands only.
- **Base**: the first of these that exists. Check each with `git rev-parse --verify --quiet`, trying `origin/<name>` first, then the local `<name>`.
  1. The argument, if given.
  2. A development branch, where PRs usually merge before production: `develop`, then `development`, then `dev`.
  3. Origin's default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix stripped.
  4. `main`, then `master`.

  If none exists, ask the user for one. Tell the user which base you picked and why, in one line (for example, `Base: develop (development branch)`).
- **Merge-base**: `git merge-base origin/<base> HEAD` if `origin/<base>` exists, otherwise `git merge-base <base> HEAD`.
- If the current branch is the base branch, use `HEAD` as the merge-base, so only uncommitted work is reviewed, and tell the user so.
- Collect:
  - commits: `git log --oneline <merge-base>..HEAD`
  - tracked changes: `git diff <merge-base> --stat` (commits + staged + unstaged)
  - untracked files: the `??` lines of `git status --porcelain`
- If there are no commits, no tracked changes and no untracked files, tell the user there is nothing to review and stop.

## 2. Read: `repo-reader`
- Spawn one `repo-reader` for a small diff. For a larger one, split the changed files by area and spawn up to 3 in a single message so they run in parallel.
- Give each reader the base, the merge-base SHA and its changed files. Ask it for:
  - callers and usages, outside the diff, of symbols the diff adds, changes, or removes
  - config, docs, manifests, and tests tied to the changed files
  - existing helpers the diff duplicates
  - code that the diff leaves unused
- Don't skip this stage.

## 3. Review: `pr-griller`
- Spawn one `pr-griller` with the base, merge-base SHA, commit list, diff stat, untracked files, all reader briefs verbatim, and the project rules.
- Pass the Agent tool's `model` set to the session's planner model from the routing rule (default `opus`), or to the model the user asked for on this task (`opus`, `sonnet` or `fable`). If `/model-pipeline:planner` was run in this conversation, the model it reported takes precedence over the routing rule.

## 4. Report
- Show the user the griller's report: summary, findings in severity order with `path:line` refs, decisions with wider impact, cleanup, questions, verdict. Keep it concise, but don't drop findings.
- Don't edit anything in this stage.

## 5. Offer fixes
If there are no findings and no cleanup items, stop after the report. Otherwise ask with AskUserQuestion:
- header: `Fix`
- question: `Which findings should go into the pipeline to be fixed?`
- options, in this order:
  1. `Blockers and majors (Recommended)`: fix every Blocker and Major finding.
  2. `Everything`: fix all findings and cleanup items.
  3. `Pick findings`: the user types the finding numbers under Other.
  4. `Report only`: change nothing.

On a fix choice:
- First ask the user about every selected item that depends on an unconfirmed **Decision with wider impact** or a **Question for the author**, one at a time with AskUserQuestion, recommendation first. Never assume the answer.
- Then run the `pipeline` skill flow from stage 2 (Read) or stage 3 (Plan) when the reader briefs above already cover the files. Skip the grill stage: the selected findings and the answers are the Requirements brief, with the answers under Decisions made. The planner's Decisions needed, the approval checkpoint, and the check-and-report stage still apply.
