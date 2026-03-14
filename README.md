<div align="center">

# spring-grimoire

**A spellbook of [Claude Code](https://claude.ai/code) skills and hooks for Java/Spring Boot development.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-17%2B-ED8B00?logo=openjdk&logoColor=white)](https://openjdk.org)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-cc785c?logo=anthropic&logoColor=white)](https://claude.ai/code)

7 slash commands. 4 automation hooks. Zero config to get started.

[Installation](#installation) · [Skills](#skills) · [Hooks](#hooks) · [Configuration](#configuration)

</div>

---

## Why?

Claude Code is powerful out of the box — but it doesn't know the Spring ecosystem's pitfalls. This plugin adds that knowledge: N+1 query detection, Spring Security misconfigurations, javax→jakarta migration paths, and more — all as slash commands you can invoke on any Spring project.

## Skills

> Slash commands that analyze your code and generate artifacts.

| Skill | What it does |
|:------|:-------------|
| `/spring-review` | Three-pillar code review: **Security**, **Performance**, **Bean Lifecycle** |
| `/spring-migration` | Spring Boot 2→3 migration analysis with javax→jakarta mappings |
| `/api-design` | REST API review: naming, HTTP verbs, status codes, RFC 7807 errors |
| `/jpa-audit` | Entity audit for N+1 queries, missing indexes, lazy loading traps |
| `/security-check` | Spring Security config review — filter chains, CORS, CSRF, JWT |
| `/test-gen [file]` | Generate JUnit 5 tests — detects Controller/Service/Repository patterns |
| `/dockerfile` | Multi-stage Dockerfile with layer caching, JVM flags, non-root user |

<details>
<summary><b>Skill details</b></summary>

### `/spring-review`

Performs a structured code review across three pillars:
- **Security** — input validation, SQL injection, hardcoded secrets, actuator exposure
- **Performance** — missing `@Cacheable`, unbounded queries, eager fetching
- **Bean Lifecycle** — circular dependencies, scope mismatches, field injection

Outputs a findings table with severity levels (`CRITICAL` / `WARNING` / `INFO`).

### `/test-gen [file]`

Pass a file path and it generates tests matching the class type:

| Class Type | Test Strategy |
|:-----------|:-------------|
| `@RestController` | `@WebMvcTest` + `MockMvc` |
| `@Service` | `@ExtendWith(MockitoExtension.class)` + `@Mock` / `@InjectMocks` |
| `@Repository` | `@DataJpaTest` + Testcontainers |

Uses AssertJ, `@Nested` grouping, and `methodName_state_expected` naming.

### `/jpa-audit`

Scans entities and repositories for:
- N+1 query patterns → recommends `@EntityGraph`, `JOIN FETCH`, `@BatchSize`
- Missing indexes on filtered/sorted columns
- Lazy loading outside transactions (entities as API responses)
- Relationship anti-patterns (`CascadeType.ALL` on `@ManyToOne`, missing `mappedBy`)

### `/spring-migration`

Generates a migration report covering:
- `javax.*` → `jakarta.*` namespace changes (full mapping table)
- Spring Security 6 API changes (`authorizeRequests` → `authorizeHttpRequests`)
- Configuration property renames (`spring.redis.*` → `spring.data.redis.*`)
- Behavior changes (trailing slash, `PathPatternParser`)
- Effort estimate per category

### `/security-check`

Reviews security posture and rates it `RED` / `YELLOW` / `GREEN`:
- Filter chain ordering and default-deny rules
- CORS policy (wildcard origins, credentials)
- CSRF protection (disabled without justification)
- Password encoding, session management
- JWT validation (algorithm, expiry, audience)
- Security headers (CSP, HSTS, X-Frame-Options)

### `/api-design`

Builds an endpoint inventory and checks:
- URL naming (nouns, plural, lowercase-hyphenated)
- HTTP verb correctness and idempotency
- Response status codes (no "200 for everything")
- Error format (RFC 7807 Problem Details)
- Pagination on collection endpoints

### `/dockerfile`

Generates production-ready container artifacts:
- Multi-stage build with dependency layer caching
- JVM container flags (`-XX:MaxRAMPercentage=75.0`)
- Non-root user, `.dockerignore`
- Health check via Actuator (if present)
- `docker-compose.yml` snippet for local dev

</details>

## Hooks

> Automation that runs before or after Claude Code tool calls.

| Hook | Event | What it does | Opt-in |
|:-----|:------|:-------------|:-------|
| **Prod config guard** | `PreToolUse` | Blocks writes to `application-prod.*` files | Always on |
| **Auto-format** | `PostToolUse` | Formats `.java` files with google-java-format | Flag file |
| **Auto-compile** | `PostToolUse` | Runs `mvn compile` / `gradle compileJava` | Flag file |
| **Checkstyle** | `PostToolUse` | Runs Checkstyle (+ optional SpotBugs) | Flag file |

## Installation

### Plugin (recommended)

From within Claude Code:

```
/plugin marketplace add https://github.com/SegfaultSorcerer/spring-grimoire.git
```

Then install via the `/plugin` menu under **Discover**.

Or from a local clone:

```
/plugin marketplace add ./spring-grimoire
```

### Manual

```bash
git clone https://github.com/SegfaultSorcerer/spring-grimoire.git
cp -r spring-grimoire/skills/ your-project/.claude/skills/
cp -r spring-grimoire/hooks/ your-project/.claude/
```

### Prerequisites

```bash
bash scripts/check-prerequisites.sh
```

| Required | Optional |
|:---------|:---------|
| Java 17+ | `google-java-format` |
| Maven or Gradle | Docker |
| `jq` (macOS/Linux only) | |

### Windows

The default `hooks.json` uses Bash scripts. If you have Git for Windows installed (which includes Git Bash), hooks work out of the box — no changes needed.

Without Git Bash, use the PowerShell variants instead:

```powershell
Copy-Item hooks\hooks.windows.json -Destination hooks\hooks.json -Force
```

## Configuration

### Enabling opt-in hooks

Create flag files in your project root to activate hooks:

```bash
mkdir -p .spring-grimoire
touch .spring-grimoire/auto-format.enabled    # google-java-format after edits
touch .spring-grimoire/auto-compile.enabled   # compile after edits
touch .spring-grimoire/checkstyle.enabled     # checkstyle after edits
touch .spring-grimoire/spotbugs.enabled       # spotbugs (requires checkstyle)
```

> Add `.spring-grimoire/` to your `.gitignore` — these are local developer preferences.

### Disabling the prod config guard

The `block-prod-config` hook is always active by design. To disable it, remove the entry from `hooks/hooks.json`.

## Contributing

Contributions welcome! Open an issue or submit a PR.

To add a new skill:

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter
2. Add reference material in `skills/<skill-name>/references/`
3. Update this README

## License

[MIT](LICENSE)
