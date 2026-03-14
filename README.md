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
| `/spring-migration` | Spring Boot 2→3 migration analysis with effort estimate and OpenRewrite |
| `/api-design` | REST API review: naming, HTTP verbs, status codes, pagination, versioning, idempotency |
| `/jpa-audit` | Entity audit for N+1 queries, EAGER defaults, missing indexes, relationship anti-patterns |
| `/security-check` | Spring Security audit — filter chains, CORS, CSRF, JWT, IDOR, dev/debug traps |
| `/test-gen [file]` | Generate JUnit 5 tests — detects Controller/Service/Repository, security tests |
| `/dockerfile` | Multi-stage Dockerfile with layered JAR, JVM flags, non-root user, signal handling |

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
| `@RestController` | `@WebMvcTest` + `MockMvc` + `@WithMockUser` for secured endpoints |
| `@Service` | `@ExtendWith(MockitoExtension.class)` + `@Mock` / `@InjectMocks` |
| `@Repository` | `@DataJpaTest` + Testcontainers (custom queries only, not inherited CRUD) |

Uses AssertJ, `@Nested` grouping, `methodName_state_expected` naming, and `given/when/then` structure.

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 project with a Controller (6 endpoints, `@PreAuthorize`), a Service (7 methods), and a Repository (5 custom queries).

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 100.0% | 78.6% | **+21.4%** |
| Avg. Time | 58.0s | 56.2s | +1.8s |
| Avg. Tokens | 19,113 | 15,172 | +3,941 |

Key advantages with the skill:
- **`methodName_state_expected` naming** in 3/3 runs (vs. 0/3 without — baseline uses `shouldVerb` style)
- **`given/when/then` comments** in 3/3 runs (vs. 0/3 without)
- **Repository: tests only custom queries** in 3/3 runs (vs. 0/3 — baseline wastes tests on inherited CRUD)
- **`@ParameterizedTest`** for similar inputs in 3/3 runs (vs. 0/3 without)

</details>

### `/jpa-audit`

Scans entities and repositories for:
- N+1 query patterns → recommends `@EntityGraph`, `JOIN FETCH`, `@BatchSize`, DTO projections
- `@ManyToOne` EAGER default trap — the most common JPA surprise
- Missing indexes on filtered/sorted/joined columns
- Lazy loading outside transactions (entities as API responses, `open-in-view`)
- Relationship anti-patterns (`CascadeType.ALL` on `@ManyToOne`, missing `mappedBy`, `List` vs `Set`)
- ID generation & batching (`GenerationType.IDENTITY` blocking batch inserts)
- Bulk update anti-patterns (load-modify-save vs `@Modifying @Query`)

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 fixture project with ~30 intentional JPA issues across 6 entities, 3 repositories, and 1 service.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 97.9% | 81.3% | **+16.6%** |
| Avg. Time | 101.4s | 82.5s | +18.9s |
| Avg. Tokens | 23,505 | 17,711 | +5,794 |

Key advantages with the skill:
- **Consistent `Severity|Entity|Issue|Impact|Fix` table** in 3/3 runs (vs. 0/3 without)
- **Quantified impact** — "6001 queries", "500ms+ per query" consistently included
- **`@ManyToOne` EAGER default** flagged on all instances (vs. some without)

</details>

### `/spring-migration`

Generates a migration report covering:
- `javax.*` → `jakarta.*` namespace changes (with JDK package warnings)
- Spring Security 6 API changes (`authorizeRequests` → `authorizeHttpRequests`)
- Configuration property renames (`spring.redis.*` → `spring.data.redis.*`)
- Spring Cloud compatibility matrix
- Behavior changes (trailing slash, `PathPatternParser`)
- Effort estimate (LOW/MEDIUM/HIGH) with Top 3 priority actions
- OpenRewrite automation recommendation

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 2.7 project with Java 11, Spring Security, JPA, Spring Cloud, Flyway, and ~20 intentional migration issues.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 100.0% | 77.3% | **+22.7%** |
| Avg. Time | 100.0s | 71.4s | +28.6s |
| Avg. Tokens | 23,801 | 17,090 | +6,711 |

Key advantages with the skill:
- **Effort estimate** (LOW/MEDIUM/HIGH) in 3/3 runs (vs. 0/3 without)
- **Top 3 Migration Steps** summary in 3/3 runs (vs. 0/3 without)
- **OpenRewrite recommendation** with specific recipes in 3/3 runs (vs. 0/3 without)
- **JDK javax package warning** (`javax.sql.*` does NOT change) in 3/3 runs (vs. 0/3 without)
- **Trailing slash detection** in 3/3 runs (vs. 1/3 without)

</details>

### `/security-check`

Reviews security posture and rates it `RED` / `YELLOW` / `GREEN`:
- Filter chain ordering, default-deny rules, matcher precedence
- CORS policy (wildcard origins, credentials)
- CSRF protection (disabled without justification)
- Password encoding (`NoOpPasswordEncoder` detection), session management
- Authorization gaps (IDOR, mass assignment, `@Secured` prefix trap)
- JWT validation (algorithm, expiry, audience, secret strength)
- Security headers (CSP, HSTS, X-Frame-Options)
- Dangerous dev/debug settings (H2 console, `security.debug`, actuator exposure)

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 fixture project with ~30 intentional security vulnerabilities across config, controllers, and JWT handling.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 100.0% | 77.8% | **+22.2%** |
| Avg. Time | 105.5s | 85.6s | +19.9s |
| Avg. Tokens | 24,045 | 17,395 | +6,650 |

Key advantages with the skill:
- **Perfect 100% pass rate** across all 3 test cases — best result of any skill
- **RED/YELLOW/GREEN rating** and **OWASP references** in 3/3 runs (vs. 0/3 without)
- **Catches subtle issues** baseline misses: `@Secured` wrong prefix, `@EnableMethodSecurity`, `security.debug`

</details>

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
- Spring Boot layered JAR extraction for optimal Docker caching
- JVM container flags (`-XX:MaxRAMPercentage=75.0`)
- Non-root user, exec-form ENTRYPOINT (PID 1 signal handling), `.dockerignore`
- Health check via Actuator (if present)
- `docker-compose.yml` snippet for local dev (modern Compose v3+ syntax)
- Analyzes existing Dockerfiles before generating replacements

<details>
<summary><b>Benchmark results</b></summary>

Tested against a Spring Boot 3.2 project with Java 21, Actuator, and an intentionally bad existing Dockerfile.

| Metric | With Skill | Without Skill | Delta |
|:-------|:-----------|:--------------|:------|
| Pass Rate | 100.0% | 81.0% | **+19.0%** |
| Avg. Time | 67.8s | 41.7s | +26.1s |
| Avg. Tokens | 16,215 | 12,108 | +4,107 |

Key advantages with the skill:
- **Spring Boot layered JAR extraction** in 3/3 runs (vs. 0/3 without)
- **Exec-form ENTRYPOINT with JarLauncher** for proper PID 1 signal handling (vs. shell wrappers or plain `-jar`)
- **Modern Compose syntax** (`deploy.resources.limits.memory`) in 3/3 runs (vs. deprecated `mem_limit` / missing)
- **No redundant `-XX:+UseContainerSupport`** (default since JDK 10) — baseline includes it 2/3 times

</details>

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
