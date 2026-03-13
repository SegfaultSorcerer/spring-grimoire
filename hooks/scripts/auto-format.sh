#!/usr/bin/env bash
# PostToolUse hook: Auto-format Java files with google-java-format.
# Requires enable flag: .spring-grimoire/auto-format.enabled

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only process Java files
if [[ "$FILE_PATH" != *.java ]]; then
  exit 0
fi

# Check enable flag
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
if [ ! -f "$PROJECT_DIR/.spring-grimoire/auto-format.enabled" ]; then
  exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Find google-java-format
GJF=""
if command -v google-java-format &>/dev/null; then
  GJF="google-java-format"
elif [ -f "$HOME/.local/share/google-java-format/google-java-format.jar" ]; then
  GJF="java -jar $HOME/.local/share/google-java-format/google-java-format.jar"
fi

if [ -z "$GJF" ]; then
  exit 0
fi

# Format the file
if $GJF --replace "$FILE_PATH" 2>/dev/null; then
  echo "{\"systemMessage\": \"Auto-formatted $(basename "$FILE_PATH") with google-java-format\"}"
fi

exit 0
