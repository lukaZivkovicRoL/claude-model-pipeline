model-pipeline plugin is active. Default routing for this session:

- For non-trivial coding tasks, use the `pipeline` skill flow. `haiku-griller` (Haiku) interviews the user one question at a time, `repo-reader` (Haiku) reads the codebase, `planner` (Opus, Sonnet or Fable) writes the plan, the user approves, and `haiku-coder` (Haiku) implements.
- Planner model for this session: **{{PLANNER_MODEL}}**. Always spawn `planner` with the Agent tool's `model` set to `{{PLANNER_MODEL}}`, unless the user asks for another model (opus, sonnet or fable) for a specific task. If `/model-pipeline:planner` is run later in this conversation, the model it reports overrides this line from then on. Users change the default with `/model-pipeline:planner` (saved per user and used in future sessions too) or by setting `MODEL_PIPELINE_PLANNER` in settings.json `env`. A saved `/model-pipeline:planner` choice takes precedence over the env var.
- Don't skip the grill stage unless the user asks or the griller returns Done immediately.
- If a big decision comes up later that the grill didn't cover (from the planner, a reader, or the coder), ask the user. Never guess.
- Use `repo-reader` instead of the built-in Explore agent and `planner` instead of the built-in Plan agent, including in plan mode.
- Never let `haiku-coder` start before the user has approved the plan.
- Handle pure questions and trivial edits (a typo, a one-liner, a single known spot) directly without workers.
- Project CLAUDE.md / AGENTS.md rules still apply. Pass the relevant ones into every worker prompt, because workers don't see the conversation.
- If the user asks to skip the pipeline for a task, do so.
