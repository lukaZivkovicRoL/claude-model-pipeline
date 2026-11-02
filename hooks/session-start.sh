#!/bin/sh
# Prints the routing rule with the planner model (opus|sonnet|fable) and the design step (on|off) filled in.
# Planner precedence: saved choice in $HOME/.claude/model-pipeline/planner (set by /model-pipeline:planner)
# > MODEL_PIPELINE_PLANNER env var > opus.
# Design step: on only if $HOME/.claude/model-pipeline/designer (set by /model-pipeline:designer) contains "on".
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
designer=off
designer_file="$HOME/.claude/model-pipeline/designer"
if [ -f "$designer_file" ]; then
  designer_saved=$(tr -d ' \t\r\n' < "$designer_file")
  case "$designer_saved" in
    on) designer=on ;;
    off|"") ;;
    *) echo "model-pipeline: saved designer setting '$designer_saved' in $designer_file is not on or off; treating it as off." ;;
  esac
fi
sed -e "s/{{PLANNER_MODEL}}/$planner/g" -e "s/{{DESIGNER}}/$designer/g" "$(dirname "$0")/routing-rule.md"
