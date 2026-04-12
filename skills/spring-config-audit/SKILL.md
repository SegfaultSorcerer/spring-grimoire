---
name: spring-config-audit
description: Audit Spring Boot configuration files (application.yml, application.properties, profile variants) for dangerous defaults, production hardening gaps, profile conflicts, deprecated properties, timeout/pool inconsistencies, and hardcoded secrets. Use this skill whenever the user wants to check their config, review application.yml, audit properties, or asks "passt meine Config?", "sind die Properties okay?", "check mal die application.yml", "is my config production ready?", or "review my properties".
argument-hint: "[profile-or-config-file]"
allowed-tools: Bash(*)
---

# Spring Config Audit

Audit Spring Boot configuration files for misconfigurations, dangerous defaults, and production hardening gaps. Read [spring-config-properties.md](references/spring-config-properties.md) for detailed property lists, BAD/GOOD comparisons, and timeout alignment examples before starting your audit — the reference contains fix patterns you should recommend.

## Scope

If a specific file or profile is provided: `$ARGUMENTS`
Otherwise, audit all configuration files in the project.

## Project Context

Configuration files:
!`find src/main/resources -maxdepth 1 -name "application*.yml" -o -name "application*.properties" 2>/dev/null`

Profile variants:
!`ls src/main/resources/application-*.yml src/main/resources/application-*.properties 2>/dev/null`

Dependencies (starters present):
!`grep -E "spring-boot-starter-|spring-cloud-|resilience4j|openfeign" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -20`

Profile includes and config imports:
!`grep -rE "spring.config.import|spring.profiles.include|spring.profiles.active|spring.profiles.group" src/main/resources/application*.yml src/main/resources/application*.properties 2>/dev/null`

Configuration content:
!`cat src/main/resources/application*.yml src/main/resources/application*.properties 2>/dev/null | head -150`

@ConfigurationProperties classes:
!`grep -rln "@ConfigurationProperties" --include="*.java" --include="*.kt" . 2>/dev/null | head -10`

## Audit Checklist

### 1. Dangerous Defaults (audit first — these silently degrade production)

1. **`spring.jpa.open-in-view` defaults to `true`**: Keeps the Hibernate session open through the entire HTTP request including view rendering. This hides lazy loading bugs and holds database connections far longer than necessary — a silent performance killer under load
2. **`spring.jpa.hibernate.ddl-auto` set to `update` or `create`**: Allows Hibernate to modify the production database schema automatically. Use `validate` in production and manage schema changes with Flyway or Liquibase
3. **HikariCP `maximumPoolSize` at default (10)**: Often too small for production workloads. `minimumIdle` defaults to the same value as `maximumPoolSize`, preventing pool shrinkage during low-traffic periods
4. **`server.shutdown` not set to `graceful`**: Without graceful shutdown, in-flight requests are abruptly terminated during deployment — causes 5xx errors for active users
5. **`spring.lifecycle.timeout-per-shutdown-phase` left at default (30s)**: May be too short for long-running requests or batch jobs. Set explicitly based on your longest expected request
6. **`spring.jackson.serialization.FAIL_ON_EMPTY_BEANS` not configured**: Empty beans silently serialize as `{}` — can mask bugs in DTO mapping

### 2. Production Hardening (only flag if the relevant starter is present)

1. **Actuator `management.endpoints.web.exposure.include: "*"`**: Exposes `/actuator/env` (leaks secrets), `/actuator/heapdump` (leaks memory contents), `/actuator/shutdown` (DoS vector). Only expose `health` and `info` in production
2. **No `management.server.port` separation**: Actuator endpoints run on the same port as public traffic — internal endpoints are reachable from the internet
3. **Missing `server.tomcat.max-threads` / `server.tomcat.accept-count` tuning**: Tomcat defaults may not match production load. `max-threads` defaults to 200, `accept-count` defaults to 100
4. **`server.error.whitelabel.enabled` not set to `false`**: Exposes framework name and potentially stack traces to end users
5. **Missing `server.tomcat.connection-timeout`**: Defaults to 20s which may be too generous — slow clients hold threads longer than necessary
6. **`spring.main.banner-mode` not set to `off` in production**: Minor, but leaks Spring Boot version information in logs

### 3. Profile and Property Conflicts — Cross-File Analysis

This is the most subtle category and where manual review usually fails. Don't just list individual findings — trace the effective value of critical properties across the profile chain and flag when a profile override doesn't actually take effect.

1. **Same property in base and profile config with conflicting intent**: Properties defined in `application.yml` that are overridden in `application-{profile}.yml` with potentially dangerous values — not all overrides are intentional
2. **Override that silently fails due to key mismatch**: A profile file may intend to override a base property but use a different key format (e.g., `ddl_auto` vs `ddl-auto`). Trace the effective value: if the override uses a different key variant, the base value may still win in production. This is the most dangerous cross-file issue because it looks correct at a glance
3. **Profile files that are never activated**: Profile-specific files (e.g., `application-staging.yml`) that exist but are never referenced by `spring.profiles.active`, `spring.profiles.include`, or `spring.profiles.group` — dead configuration
4. **`spring.config.import` ordering issues**: Later imports override earlier ones — verify the order matches intent
5. **`spring.profiles.include` chains**: Circular or redundant profile loading via include chains can cause unexpected property precedence
6. **Environment-specific values in base `application.yml`**: Database URLs, external service endpoints, and credentials should be in profile-specific files, not the base config
7. **Safety-critical property missing from production profile**: If `server.shutdown: graceful` or `spring.jpa.open-in-view: false` is set in dev but missing from prod, production is less safe than development — flag this inversion explicitly

### 4. Orphaned and Deprecated Properties

1. **Misspelled property keys**: Common typos like `spring.datasource.hikari.maxLiftime` (missing 'e'), `spring.jpa.hibernate.ddl_auto` (underscore instead of hyphen). Relaxed binding accepts some variants but creates inconsistency
2. **Deprecated Spring Boot 2.x properties**: `spring.redis.*` should be `spring.data.redis.*` (since Boot 3.0), `spring.flyway.*` namespace changes, `management.metrics.*` restructuring. Deprecated keys are silently ignored
3. **Custom properties without binding**: Properties like `app.feature.x` without a corresponding `@ConfigurationProperties` or `@Value` binding suggest dead configuration
4. **Properties for absent starters**: Configuration for starters not in the dependency list (e.g., `spring.flyway.enabled` without Flyway dependency) — silently ignored, clutters config

### 5. Timeout and Pool Size Consistency

1. **HikariCP `connectionTimeout` vs Tomcat `connection-timeout`**: If HikariCP waits longer for a connection than Tomcat waits for a request, requests fail with confusing timeout errors
2. **Feign/RestTemplate timeout vs circuit breaker timeout**: `connectTimeout` + `readTimeout` must be less than Resilience4j `timeoutDuration` — otherwise the circuit breaker never trips and provides no protection
3. **HikariCP `maxLifetime` vs database `wait_timeout`**: `maxLifetime` must be less than the database server's connection timeout — otherwise the pool serves connections that the database has already closed
4. **Tomcat `max-threads` vs HikariCP `maximumPoolSize`**: If Tomcat threads significantly exceed pool size, threads block waiting for connections under load. Ratio should be reasonable (e.g., 200 threads with at least 20-50 connections)
5. **`spring.task.execution.pool.max-size` vs HikariCP pool**: Async tasks can exhaust the connection pool if the thread pool is much larger than the connection pool

### 6. Security in Properties (complement to /spring-security-check — property-level concerns only)

1. **Hardcoded credentials**: `spring.datasource.password`, `spring.mail.password`, API keys in plain text instead of `${ENV_VAR}` or vault references — check all profiles, including dev (credentials in dev config often leak to production)
2. **`logging.level.org.springframework.security=DEBUG` in non-dev profiles**: Logs full security filter chain details including authentication tokens and request headers
3. **`spring.h2.console.enabled=true` outside of dev/test profiles**: H2 console provides unauthenticated database access — must be restricted to development profiles only
4. **`management.endpoint.env.show-values` not set to `NEVER` in production**: Exposes environment variable values including secrets via `/actuator/env`
5. **`spring.devtools.*` properties in production profile**: DevTools enables automatic restarts, remote debugging, and relaxed security — never appropriate in production

## Output Format

### 1. Production Readiness Verdict

Start with a clear overall rating — this is the first thing the reader should see:
- **RED**: Critical issues found — hardcoded secrets, unsecured actuator, `ddl-auto: update/create` reaching production, H2 console in prod. The application must not be deployed.
- **YELLOW**: No critical issues, but warnings that degrade reliability or performance under load. Safe to deploy with caution, but fix before scaling.
- **GREEN**: No critical or warning issues. Configuration follows production best practices.

### 2. Findings Table

Use exactly these three severity levels — not HIGH/MEDIUM/LOW, not numbered severity:

| Severity | Category | File:Line | Property | Issue | Fix |
|----------|----------|-----------|----------|-------|-----|
| CRITICAL | Category | path:line | property.key | Description | Recommended fix |
| WARNING | Category | path:line | property.key | Description | Recommended fix |
| INFO | Category | path:line | property.key | Description | Recommended fix |

**Severity guide:**
- **CRITICAL**: Hardcoded secrets, `ddl-auto: create/update` in prod, unsecured actuator with `include: "*"`, H2 console enabled in prod, hardcoded credentials — these cause data breaches or production incidents
- **WARNING**: `open-in-view=true`, missing graceful shutdown, timeout misalignment, HikariCP defaults, deprecated properties — these degrade performance or cause failures at scale
- **INFO**: Missing banner suppression, unused profile files, missing explicit pool sizes, inconsistent property style — improvements for operational maturity

For cross-file issues, explain the chain: "Property X in base config is `update`. The prod override uses `ddl_auto` (underscore) which may not take effect → effective value in production is `update`."

### 3. Timeout Alignment Summary

After the findings table, if any timeout or pool sizing issues were found, include a brief alignment diagram showing the current (broken) chain and the recommended chain:

```
Current:  Feign (40s) > Resilience4j (5s) > HikariCP (60s) > Tomcat (10s)  ← BROKEN
Fixed:    Feign (8s)  < Resilience4j (10s) < HikariCP (5s)  < Tomcat (10s) ← CORRECT
```

This makes timeout misalignment immediately visible at a glance rather than requiring the reader to piece together individual findings.

### 4. Summary

End with:
- Total findings by severity (CRITICAL/WARNING/INFO counts)
- **Starter-conditional analysis**: Which findings depend on detected starters (e.g., "Actuator findings apply because `spring-boot-starter-actuator` is a dependency"). This prevents false positives when the skill is used on projects with different dependency sets
- **Top 3 things to fix first**, prioritized by production impact

For detailed property lists and examples, see [spring-config-properties.md](references/spring-config-properties.md).
