#!/usr/bin/env bash
# PostToolUse hook: Auto-compile after Java file changes.
# Requires enable flag: .spring-grimoire/auto-compile.enabled

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
if [ ! -f "$PROJECT_DIR/.spring-grimoire/auto-compile.enabled" ]; then
  exit 0
fi

cd "$PROJECT_DIR"

# Detect build tool and compile
if [ -f "pom.xml" ]; then
  OUTPUT=$(mvn compile -q -T 1C 2>&1 | tail -30) || {
    echo "Compilation failed:" >&2
    echo "$OUTPUT" >&2
    exit 2
  }
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  GRADLE_CMD="gradle"
  if [ -f "./gradlew" ]; then
    GRADLE_CMD="./gradlew"
  fi
  OUTPUT=$($GRADLE_CMD compileJava -q 2>&1 | tail -30) || {
    echo "Compilation failed:" >&2
    echo "$OUTPUT" >&2
    exit 2
  }
else
  exit 0
fi

echo '{"systemMessage": "Compilation successful"}'
exit 0
