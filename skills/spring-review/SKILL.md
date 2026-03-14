---
name: spring-review
description: Spring Boot code review covering security vulnerabilities, performance anti-patterns, transaction mistakes, and bean lifecycle problems. Use this skill whenever the user wants to review, audit, or check Spring Boot code — even if they just say "schau dir den Code an", "check this", "is this okay?", or "review my changes". Triggers for controllers, services, repositories, configuration classes, and any Java/Kotlin Spring project.
argument-hint: "[file-or-directory]"
allowed-tools: Bash(*)
---

# Spring Boot Code Review

Perform a comprehensive code review of the Spring Boot application across four pillars: **Security**, **Performance**, **Transactions & Data Access**, and **Bean Lifecycle**. Read [spring-review-checklist.md](references/spring-review-checklist.md) for the detailed criteria on each layer (Controller, Service, Repository, Configuration, Async, Logging) before starting your review — the checklist contains important items not repeated here.

## Scope

If a specific file or directory is provided: `$ARGUMENTS`
Otherwise, review the entire project.

## Project Context

Current Spring components:
!`grep -rn "@Controller\|@RestController\|@Service\|@Repository\|@Component\|@Configuration" --include="*.java" --include="*.kt" . 2>/dev/null | head -40`

Spring Boot version:
!`grep -A1 "spring-boot-starter-parent\|spring-boot.*version" pom.xml 2>/dev/null | head -5`
!`grep "org.springframework.boot" build.gradle build.gradle.kts 2>/dev/null | head -5`

## Review Pillars

### 1. Security (review first — these can cause real damage)

1. **SQL Injection**: String concatenation in `@Query` or `EntityManager.createQuery()` — this is the most dangerous pattern, flag as CRITICAL
2. **Hardcoded Secrets**: Passwords, API keys, tokens in source code or non-profile-specific config files
3. **Input Validation**: All `@RequestBody`, `@RequestParam`, `@PathVariable` need `@Valid`/`@Validated`; DTOs need Bean Validation annotations
4. **Missing Authentication**: Endpoints without security constraints that should have them
5. **CORS**: `@CrossOrigin` or `CorsConfiguration` with `*` is almost always wrong in production
6. **Actuator Exposure**: Actuator endpoints must be secured, non-essential endpoints disabled, base path changed from default
7. **Sensitive Data Leakage**: JPA entities returned directly from controllers expose internal fields; stack traces in error responses

### 2. Performance

1. **N+1 Queries**: Collections loaded without `@EntityGraph` or `JOIN FETCH` — this is the single most common Spring performance problem. Look for `@OneToMany`/`@ManyToMany` accessed in loops
2. **Eager Fetching**: `FetchType.EAGER` on collections, especially `@OneToMany` and `@ManyToMany`
3. **Missing Pagination**: List endpoints returning unbounded collections — must use `Pageable`
4. **Missing Projections**: Read-only queries loading full entities when only a few fields are needed — use interface or class-based DTOs
5. **Missing `@Cacheable`**: Frequently called methods with expensive computations or DB queries
6. **Missing Indexes**: Repository queries on columns without `@Index` in `@Table`
7. **Connection Pool**: Datasource configuration without explicit pool sizing (HikariCP defaults may not fit)

### 3. Transactions & Data Access

Transaction mistakes are among the hardest Spring bugs to diagnose because they often only manifest under load or with specific data.

1. **Missing `@Transactional`**: Service methods that modify data without `@Transactional`
2. **`@Transactional` on private methods**: Does nothing — Spring's proxy-based AOP can't intercept private methods
3. **Missing `readOnly = true`**: Read-only service methods should use `@Transactional(readOnly = true)` for Hibernate flush-mode optimization
4. **Default rollback rules**: By default, `@Transactional` only rolls back on unchecked exceptions — use `rollbackFor = Exception.class` when checked exceptions are thrown
5. **`@Modifying` queries**: Update/delete `@Query` methods need `@Modifying(clearAutomatically = true)` to sync the persistence context
6. **Named parameters**: `@Query` should use `:name` not positional `?1` for readability and safety

### 4. Bean Lifecycle

1. **Field Injection**: `@Autowired` on fields hides dependencies and breaks testability — use constructor injection
2. **Circular Dependencies**: Constructor injection cycles; `@Lazy` is a workaround, not a fix — restructure the dependency graph
3. **Scope Mismatch**: Prototype-scoped bean injected into singleton loses its prototype behavior — use `ObjectProvider<T>`
4. **Heavy `@PostConstruct`**: I/O or long-running operations in `@PostConstruct` block application startup
5. **Missing Cleanup**: Resources opened in `@PostConstruct` without corresponding `@PreDestroy`
6. **`@Value` sprawl**: Groups of related `@Value` properties should use `@ConfigurationProperties` with `@Validated`

## Output Format

For each finding, report:

| Severity | File:Line | Issue | Recommendation |
|----------|-----------|-------|----------------|
| CRITICAL | path:line | Description | Suggested fix |
| WARNING  | path:line | Description | Suggested fix |
| INFO     | path:line | Description | Suggested fix |

**Severity guide:**
- **CRITICAL**: Security vulnerabilities, data loss risks, transaction bugs that corrupt data
- **WARNING**: Performance anti-patterns, lifecycle issues, missing best practices that will cause problems at scale
- **INFO**: Code quality improvements, convention violations, minor optimizations

Group findings by pillar. Within each pillar, list CRITICAL findings first. End with a short summary: total findings by severity and the top 3 things to fix first.
