---
name: spring-review
description: Spring Boot code review focusing on security vulnerabilities, performance issues, and bean lifecycle problems. Use when reviewing Spring Boot controllers, services, repositories, or configuration classes.
argument-hint: "[file-or-directory]"
allowed-tools: Bash(*)
---

# Spring Boot Code Review

Perform a comprehensive code review of the Spring Boot application, focusing on three pillars: **Security**, **Performance**, and **Bean Lifecycle**.

## Scope

If a specific file or directory is provided: `$ARGUMENTS`
Otherwise, review the entire project.

## Project Context

Current Spring components:
!`grep -rn "@Controller\|@RestController\|@Service\|@Repository\|@Component\|@Configuration" --include="*.java" . 2>/dev/null | head -40`

Spring Boot version:
!`grep -A1 "spring-boot-starter-parent\|spring-boot.*version" pom.xml 2>/dev/null | head -5`
!`grep "org.springframework.boot" build.gradle 2>/dev/null | head -3`

## Review Checklist

### Security

1. **Input Validation**: Check all `@RequestBody`, `@RequestParam`, `@PathVariable` for `@Valid`/`@Validated`
2. **SQL Injection**: Look for string concatenation in `@Query` annotations or `EntityManager.createQuery()`
3. **Hardcoded Secrets**: Scan for passwords, API keys, tokens in source code or non-profile-specific config
4. **Actuator Exposure**: Check if actuator endpoints are properly secured
5. **CORS**: Verify `@CrossOrigin` or `CorsConfiguration` is not overly permissive (`*`)
6. **Missing Authentication**: Endpoints without security constraints that should have them

### Performance

1. **Missing `@Cacheable`**: Identify frequently called methods with expensive computations or DB queries that lack caching
2. **Synchronous Blocking**: Operations that should use `@Async` or reactive patterns
3. **Missing Pagination**: List endpoints returning unbounded collections — must use `Pageable`
4. **Eager Fetching**: `FetchType.EAGER` on collections, especially `@OneToMany` and `@ManyToMany`
5. **Missing Indexes**: Repository method queries on columns without `@Index` in `@Table`
6. **Connection Pool**: Check datasource configuration for appropriate pool sizing

### Bean Lifecycle

1. **Circular Dependencies**: Detect constructor injection cycles (avoid `@Lazy` workarounds)
2. **Scope Mismatch**: Prototype-scoped bean injected into singleton (use `ObjectProvider<T>` instead)
3. **Heavy `@PostConstruct`**: I/O or long-running operations in `@PostConstruct` block startup
4. **Missing Cleanup**: Resources opened in `@PostConstruct` without corresponding `@PreDestroy`
5. **Field Injection**: Prefer constructor injection over `@Autowired` on fields
6. **`@Value` vs `@ConfigurationProperties`**: Groups of related properties should use `@ConfigurationProperties`

## Output Format

For each finding, report:

| Severity | File:Line | Issue | Recommendation |
|----------|-----------|-------|----------------|
| CRITICAL / WARNING / INFO | path:line | Description | Suggested fix |

Group findings by pillar (Security, Performance, Bean Lifecycle). Start with CRITICAL findings.

For detailed review criteria, see [spring-review-checklist.md](references/spring-review-checklist.md).
