#!/bin/sh
# Prints the routing rule with the planner model chosen via MODEL_PIPELINE_PLANNER (opus|fable, default opus).
planner="${MODEL_PIPELINE_PLANNER:-opus}"
case "$planner" in
  opus|fable) ;;
  *) echo "model-pipeline: MODEL_PIPELINE_PLANNER='$planner' is not opus or fable; using opus."; planner=opus ;;
esac
sed "s/{{PLANNER_MODEL}}/$planner/g" "$(dirname "$0")/routing-rule.md"
