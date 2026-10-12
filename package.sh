#!/bin/sh
# Builds dist/model-pipeline.zip for upload to claude.ai (My Uploads).
set -e
cd "$(dirname "$0")"
mkdir -p dist
rm -f dist/model-pipeline.zip
zip -rq dist/model-pipeline.zip .claude-plugin agents skills hooks README.md
echo "dist/model-pipeline.zip"
