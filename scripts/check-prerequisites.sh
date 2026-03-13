#!/usr/bin/env bash
# Check prerequisites for spring-grimoire plugin

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok() { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[OPTIONAL]${NC} $1"; }
fail() { echo -e "  ${RED}[MISSING]${NC} $1"; ERRORS=$((ERRORS + 1)); }

ERRORS=0

echo "Checking prerequisites for spring-grimoire..."
echo ""

# Required
echo "Required:"

if command -v java &>/dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -1 | sed 's/.*"\([0-9]*\).*/\1/')
  if [ "$JAVA_VERSION" -ge 17 ] 2>/dev/null; then
    ok "Java $JAVA_VERSION"
  else
    fail "Java 17+ required (found $JAVA_VERSION)"
  fi
else
  fail "Java not found"
fi

if command -v jq &>/dev/null; then
  ok "jq ($(jq --version 2>&1))"
else
  fail "jq not found — required by hook scripts (brew install jq)"
fi

if command -v mvn &>/dev/null || [ -f "./gradlew" ] || command -v gradle &>/dev/null; then
  if command -v mvn &>/dev/null; then ok "Maven"; fi
  if command -v gradle &>/dev/null || [ -f "./gradlew" ]; then ok "Gradle"; fi
else
  fail "Neither Maven nor Gradle found"
fi

echo ""
echo "Optional:"

if command -v google-java-format &>/dev/null || [ -f "$HOME/.local/share/google-java-format/google-java-format.jar" ]; then
  ok "google-java-format (for auto-format hook)"
else
  warn "google-java-format not found — auto-format hook will be skipped"
fi

if command -v docker &>/dev/null; then
  ok "Docker (for /dockerfile skill)"
else
  warn "Docker not found — /dockerfile skill works without it but cannot verify builds"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}$ERRORS required tool(s) missing.${NC}"
  exit 1
else
  echo -e "${GREEN}All required tools found.${NC}"
  exit 0
fi
