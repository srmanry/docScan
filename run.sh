#!/bin/bash
# Loads local secrets from .env.local (gitignored) and runs the app.
# Usage: ./run.sh
set -e

if [ ! -f .env.local ]; then
  echo "Missing .env.local — copy your API keys there first (see README)."
  exit 1
fi

export $(grep -v '^#' .env.local | xargs)

flutter run --dart-define=CLOUD_VISION_API_KEY="$CLOUD_VISION_API_KEY" --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
