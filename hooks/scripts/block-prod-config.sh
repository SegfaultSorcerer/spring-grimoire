#!/usr/bin/env bash
# PreToolUse hook: Block writes to production configuration files.
# Always active — no enable flag required. This is a safety measure.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

if [[ "$BASENAME" =~ ^application-prod\..+ ]] || \
   [[ "$BASENAME" =~ ^application-production\..+ ]] || \
   [[ "$BASENAME" =~ ^bootstrap-prod\..+ ]]; then
  echo "Blocked: Production configuration file '$BASENAME' must not be modified by AI. Edit this file manually." >&2
  exit 2
fi

exit 0
