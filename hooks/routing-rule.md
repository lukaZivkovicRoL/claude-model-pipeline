model-pipeline plugin is active. Default routing for this session:

- For non-trivial coding tasks, use the `pipeline` skill flow. `repo-reader` (Haiku) reads the codebase, `fable-planner` (Fable) writes the plan, the user approves, and `haiku-coder` (Haiku) implements.
- Use `repo-reader` instead of the built-in Explore agent and `fable-planner` instead of the built-in Plan agent, including in plan mode.
- Never let `haiku-coder` start before the user has approved the plan.
- Handle pure questions and trivial edits (a typo, a one-liner, a single known spot) directly without workers.
- Project CLAUDE.md / AGENTS.md rules still apply. Pass the relevant ones into every worker prompt, because workers don't see the conversation.
- If the user asks to skip the pipeline for a task, do so.
