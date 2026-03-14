<div align="center">

<img src="spring-grimoire.png" alt="Spring Grimoire" width="100%">

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
| `/spring-review` | Four-pillar code review: **Security**, **Performance**, **Transactions**, **Bean Lifecycle** |
| `/spring-migration` | Spring Boot 2→3 migration analysis with javax→jakarta mappings |
| `/api-design` | REST API review: naming, HTTP verbs, status codes, pagination, versioning, idempotency |
| `/jpa-audit` | Entity audit for N+1 queries, missing indexes, lazy loading traps |
| `/security-check` | Spring Security config review — filter chains, CORS, CSRF, JWT |
| `/test-gen [file]` | Generate JUnit 5 tests — detects Controller/Service/Repository patterns |
| `/dockerfile` | Multi-stage Dockerfile with layer caching, JVM flags, non-root user |

<details>
<summary><b>Skill details</b></summary>

### `/spring-review`

Performs a structured code review across four pillars:
- **Security** — SQL injection, hardcoded secrets, CORS, actuator exposure, input validation
- **Performance** — N+1 queries, eager fetching, missing pagination, missing indexes
- **Transactions & Data Access** — missing `@Transactional`, private method traps, `@Modifying` misuse
- **Bean Lifecycle** — circular dependencies, field injection, scope mismatches, heavy `@PostConstruct`

Outputs a findings table with severity levels (`CRITICAL` / `WARNING` / `INFO`) and a prioritized Top 3 action list.

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 fixture project with ~30 intentional bugs across all four pillars.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 95.2% | 81.0% | **+14.2%** |
| Avg. Time | 103.7s | 98.5s | +5.2s |
| Avg. Tokens | 22,106 | 18,067 | +4,039 |

Key advantages with the skill:
- **Consistent output format** — structured table in 3/3 runs (vs. 0/3 without)
- **Transactions pillar** — dedicated coverage of `@Transactional` misuse that baseline reviews fold into general findings
- **Prioritized summary** — always ends with severity counts and Top 3 fixes

</details>

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
- URL naming (nouns, plural, lowercase-hyphenated, no trailing slashes, no file extensions)
- HTTP verb correctness and idempotency (GET must not mutate, DELETE must be idempotent)
- Response status codes (201 for creation, 204 for deletion, 404 for missing resources)
- Error format (RFC 7807 Problem Details via `@RestControllerAdvice`)
- Pagination on collection endpoints (with default/max page size)
- Versioning consistency across controllers
- Request/Response DTO separation (no JPA entity exposure)

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 fixture project with ~25 intentional API design violations across 3 controllers.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 97.8% | 77.8% | **+20.0%** |
| Avg. Time | 92.5s | 80.1s | +12.4s |
| Avg. Tokens | 22,012 | 16,751 | +5,261 |

Key advantages with the skill:
- **Per-controller endpoint inventory table** in 3/3 runs (vs. 0/3 without)
- **Top 3 prioritized action list** in 3/3 runs (vs. 0/3 without)
- **RFC 7807 ProblemDetail** code examples in recommendations

</details>

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
/plugin marketplace add SegfaultSorcerer/spring-grimoire
/plugin install spring-grimoire@spring-grimoire
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
