# spring-java-commands

A curated collection of [Claude Code](https://claude.ai/code) skills (slash commands) and hooks for Java/Spring Boot development.

> **First-of-its-kind**: Purpose-built Claude Code automation for the Java/Spring ecosystem.

## What's Included

### Skills (Slash Commands)

| Skill | Description |
|-------|-------------|
| `/spring-review` | Spring Boot code review — security, performance, bean lifecycle |
| `/spring-migration` | Spring Boot 2→3 / javax→jakarta migration analysis |
| `/api-design` | REST API design review against best practices |
| `/jpa-audit` | JPA entity audit — N+1 queries, missing indexes, lazy loading |
| `/security-check` | Spring Security configuration review |
| `/test-gen [file]` | Generate JUnit 5 tests with Mockito/Testcontainers |
| `/dockerfile` | Generate optimized multi-stage Dockerfiles |

### Hooks (Automatic)

| Hook | Trigger | Description | Opt-in |
|------|---------|-------------|--------|
| Block prod config | Before file write | Prevents AI edits to `application-prod.*` files | Always on |
| Auto-format | After file edit | Formats Java files with google-java-format | Yes |
| Auto-compile | After file edit | Runs `mvn compile` / `gradle compileJava` | Yes |
| Checkstyle | After file edit | Runs Checkstyle (and optionally SpotBugs) | Yes |

## Installation

### As Claude Code Plugin

```bash
claude plugin add SegfaultSorcerer/spring-java-commands
```

### Manual (Copy into your project)

```bash
git clone https://github.com/SegfaultSorcerer/spring-java-commands.git
cp -r spring-java-commands/skills/ your-project/.claude/skills/
cp -r spring-java-commands/hooks/ your-project/.claude/
```

## Configuration

### Enabling Optional Hooks

Opt-in hooks are activated by creating flag files in your project root:

```bash
# Enable auto-formatting
mkdir -p .spring-java-commands
touch .spring-java-commands/auto-format.enabled

# Enable auto-compilation
touch .spring-java-commands/auto-compile.enabled

# Enable Checkstyle
touch .spring-java-commands/checkstyle.enabled

# Enable SpotBugs (requires Checkstyle to be enabled)
touch .spring-java-commands/spotbugs.enabled
```

Add `.spring-java-commands/` to your `.gitignore` — these are local developer preferences.

### Disabling the Prod Config Guard

The `block-prod-config` hook is always active by design. To disable it, remove the corresponding entry from `hooks/hooks.json`.

## Prerequisites

Run the included check script to verify your environment:

```bash
bash scripts/check-prerequisites.sh
```

**Required:**
- Java 17+
- Maven or Gradle
- `jq` (used by hook scripts)

**Optional:**
- `google-java-format` (for auto-format hook)
- Docker (for `/dockerfile` skill)

## Skills in Detail

### `/spring-review`

Performs a three-pillar code review:
- **Security**: input validation, SQL injection, hardcoded secrets, actuator exposure
- **Performance**: missing caching, unbounded queries, eager fetching
- **Bean Lifecycle**: circular dependencies, scope mismatches, field injection

Outputs a findings table with severity levels (CRITICAL / WARNING / INFO).

### `/test-gen [file]`

Generates tests based on the class type:
- `@RestController` → `@WebMvcTest` with `MockMvc`
- `@Service` → `@ExtendWith(MockitoExtension.class)` with `@Mock`/`@InjectMocks`
- `@Repository` → `@DataJpaTest` with Testcontainers

Uses AssertJ assertions and follows `methodName_stateUnderTest_expectedBehavior` naming.

### `/jpa-audit`

Scans entities and repositories for:
- N+1 query patterns (with solutions: `@EntityGraph`, `JOIN FETCH`, `@BatchSize`)
- Missing database indexes on filtered/sorted columns
- Lazy loading issues (entities returned directly from controllers)
- Relationship anti-patterns (missing `mappedBy`, wrong cascade types)

### `/spring-migration`

Generates a complete migration report:
- javax→jakarta namespace changes (with file list)
- Spring Security 6 API changes
- Configuration property renames
- Behavior changes (trailing slash, PathPatternParser)
- Effort estimate

### `/security-check`

Reviews security posture across:
- Filter chain configuration and matcher ordering
- CORS/CSRF settings
- Authentication and password encoding
- JWT/OAuth2 validation
- Security headers (CSP, HSTS, X-Frame-Options)

Rates overall posture as RED / YELLOW / GREEN.

### `/api-design`

Reviews REST API design:
- URL naming conventions (nouns, plural, lowercase-hyphenated)
- HTTP verb correctness and idempotency
- Response status codes and error format (RFC 7807)
- Pagination and content negotiation

### `/dockerfile`

Generates a production-ready Dockerfile with:
- Multi-stage build (dependency caching)
- JVM container flags (`-XX:MaxRAMPercentage`)
- Non-root user
- Health check (if Actuator is present)
- Matching `.dockerignore`

## Contributing

Contributions welcome! Please open an issue or PR.

When adding a new skill:
1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter
2. Add detailed reference material in `skills/<skill-name>/references/`
3. Update this README

## License

[MIT](LICENSE)
