#!/bin/sh
# Prints the routing rule with the planner model filled in (opus|sonnet|fable).
# Precedence: saved choice in $HOME/.claude/model-pipeline/planner (set by /model-pipeline:planner)
# > MODEL_PIPELINE_PLANNER env var > opus.
planner=""
saved_file="$HOME/.claude/model-pipeline/planner"
if [ -f "$saved_file" ]; then
  saved=$(tr -d ' \t\r\n' < "$saved_file")
  case "$saved" in
    opus|sonnet|fable) planner="$saved" ;;
    *) echo "model-pipeline: saved planner choice '$saved' in $saved_file is not opus, sonnet or fable; ignoring it." ;;
  esac
fi
if [ -z "$planner" ]; then
  planner="${MODEL_PIPELINE_PLANNER:-opus}"
  case "$planner" in
    opus|sonnet|fable) ;;
    *) echo "model-pipeline: MODEL_PIPELINE_PLANNER='$planner' is not opus, sonnet or fable; using opus."; planner=opus ;;
  esac
fi
sed "s/{{PLANNER_MODEL}}/$planner/g" "$(dirname "$0")/routing-rule.md"
