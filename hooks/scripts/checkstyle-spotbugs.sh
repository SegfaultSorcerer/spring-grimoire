#!/usr/bin/env bash
# PostToolUse hook: Run Checkstyle after Java file edits.
# Requires enable flag: .spring-java-commands/checkstyle.enabled

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
if [ ! -f "$PROJECT_DIR/.spring-java-commands/checkstyle.enabled" ]; then
  exit 0
fi

cd "$PROJECT_DIR"

# Detect build tool and run checkstyle
if [ -f "pom.xml" ]; then
  OUTPUT=$(mvn checkstyle:check -q 2>&1 | tail -30) || {
    echo "Checkstyle violations found:" >&2
    echo "$OUTPUT" >&2
    exit 2
  }
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  GRADLE_CMD="gradle"
  if [ -f "./gradlew" ]; then
    GRADLE_CMD="./gradlew"
  fi
  OUTPUT=$($GRADLE_CMD checkstyleMain -q 2>&1 | tail -30) || {
    echo "Checkstyle violations found:" >&2
    echo "$OUTPUT" >&2
    exit 2
  }
else
  exit 0
fi

# Optional: SpotBugs (separate flag since it's slower)
if [ -f "$PROJECT_DIR/.spring-java-commands/spotbugs.enabled" ]; then
  if [ -f "pom.xml" ]; then
    OUTPUT=$(mvn spotbugs:check -q 2>&1 | tail -30) || {
      echo "SpotBugs issues found:" >&2
      echo "$OUTPUT" >&2
      exit 2
    }
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    OUTPUT=$($GRADLE_CMD spotbugsMain -q 2>&1 | tail -30) || {
      echo "SpotBugs issues found:" >&2
      echo "$OUTPUT" >&2
      exit 2
    }
  fi
fi

exit 0
