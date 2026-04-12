# Spring Config Properties Reference

## Dangerous Defaults

Properties that silently degrade production performance or safety when left at their default values.

| Property | Default | Recommended (prod) | Why |
|----------|---------|---------------------|-----|
| `spring.jpa.open-in-view` | `true` | `false` | Holds DB connections through view rendering |
| `spring.jpa.hibernate.ddl-auto` | `none` (no starter) / `create-drop` (embedded DB) | `validate` | Prevents uncontrolled schema changes |
| `spring.datasource.hikari.maximum-pool-size` | `10` | Tuned per workload | Default often too small for production |
| `spring.datasource.hikari.minimum-idle` | same as max | Lower than max | Allow pool to shrink during low traffic |
| `server.shutdown` | `immediate` | `graceful` | Prevents dropped in-flight requests |
| `spring.lifecycle.timeout-per-shutdown-phase` | `30s` | Based on longest request | Default may be too short |
| `server.tomcat.max-threads` | `200` | Tuned per workload | May need adjustment for high/low traffic |
| `server.tomcat.accept-count` | `100` | Tuned per workload | Backlog queue for incoming connections |
| `server.tomcat.connection-timeout` | `20s` | `10s` or less | Slow clients hold threads too long |

### BAD — Dangerous defaults left unconfigured

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: update  # Hibernate modifies production schema
    # open-in-view not set — defaults to true
  datasource:
    url: jdbc:postgresql://prod-db:5432/app
    username: app
    password: s3cret  # Hardcoded credential
    # No HikariCP tuning — defaults to pool size 10
# No server.shutdown — defaults to immediate
```

### GOOD — Explicitly configured for production

```yaml
spring:
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
  datasource:
    url: jdbc:postgresql://prod-db:5432/app
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 30
      minimum-idle: 10
      max-lifetime: 1740000        # 29 min (< DB wait_timeout)
      connection-timeout: 5000     # 5s — fail fast
      leak-detection-threshold: 30000
  lifecycle:
    timeout-per-shutdown-phase: 60s

server:
  shutdown: graceful
  tomcat:
    max-threads: 200
    accept-count: 100
    connection-timeout: 10s
  error:
    whitelabel:
      enabled: false
```

---

## Deprecated Property Mapping (Boot 2.x to 3.x)

Properties that were renamed or restructured in Spring Boot 3.x. The old keys are silently ignored.

| Deprecated (Boot 2.x) | Replacement (Boot 3.x) | Since |
|------------------------|------------------------|-------|
| `spring.redis.*` | `spring.data.redis.*` | 3.0 |
| `spring.data.cassandra.*` | `spring.cassandra.*` | 3.0 |
| `spring.flyway.url` | `spring.flyway.jdbc-url` | 3.0 |
| `spring.liquibase.url` | `spring.liquibase.jdbc-url` | 3.0 |
| `management.metrics.export.*` | `management.*.<system>.metrics.export.*` | 3.0 |
| `spring.mvc.throw-exception-if-no-handler-found` | Always `true` (removed) | 3.2 |
| `spring.resources.add-mappings` | `spring.web.resources.add-mappings` | 3.0 |
| `spring.session.store-type` | Auto-detected from classpath | 3.0 |
| `server.max-http-header-size` | `server.max-http-request-header-size` | 3.0 |
| `spring.security.oauth2.resourceserver.jwt.jws-algorithm` | `spring.security.oauth2.resourceserver.jwt.jws-algorithms` (plural) | 3.0 |
| `management.endpoint.health.group.*.show-details` | `management.endpoint.health.group.*.show-components` | 3.0 |
| `spring.config.use-legacy-processing` | Removed | 3.0 |
| `spring.jpa.open-in-view` (warning log) | Still works but warns | 3.0 |

---

## Timeout Alignment Matrix

Timeouts across subsystems must be coordinated. If inner timeouts exceed outer ones, the outer layer gives up first and the inner timeout provides no protection.

### Correct ordering (inner < outer)

```
Database wait_timeout (e.g., 28800s / 8h)
  └─ HikariCP maxLifetime (must be < DB timeout, e.g., 1740s / 29min)
      └─ HikariCP connectionTimeout (e.g., 5s)

Resilience4j timeoutDuration (e.g., 10s)
  └─ Feign/RestTemplate connectTimeout + readTimeout (must be < circuit breaker, e.g., 3s + 5s = 8s)

Tomcat connection-timeout (e.g., 10s)
  └─ HikariCP connectionTimeout (should be < Tomcat timeout, e.g., 5s)
```

### BAD — Timeouts misaligned

```yaml
# Feign timeout (30s) > circuit breaker timeout (5s)
# Circuit breaker trips before Feign gives up — no actual timeout protection
spring:
  cloud:
    openfeign:
      client:
        config:
          default:
            connect-timeout: 10000   # 10s
            read-timeout: 30000      # 30s — way too long

resilience4j:
  timelimiter:
    instances:
      default:
        timeout-duration: 5s         # Trips before Feign finishes

# HikariCP waits 60s but Tomcat gives up at 10s
spring:
  datasource:
    hikari:
      connection-timeout: 60000      # 60s — request already timed out
server:
  tomcat:
    connection-timeout: 10s          # Client sees timeout at 10s
```

### GOOD — Timeouts properly aligned

```yaml
spring:
  cloud:
    openfeign:
      client:
        config:
          default:
            connect-timeout: 3000    # 3s
            read-timeout: 5000       # 5s (total 8s < circuit breaker 10s)
  datasource:
    hikari:
      connection-timeout: 5000       # 5s (< Tomcat 10s)
      max-lifetime: 1740000          # 29min (< DB 30min wait_timeout)

resilience4j:
  timelimiter:
    instances:
      default:
        timeout-duration: 10s        # > Feign total (8s), provides protection

server:
  tomcat:
    connection-timeout: 10s          # > HikariCP (5s)
```

---

## HikariCP Pool Sizing

### Formula

A widely referenced guideline from the HikariCP wiki:

```
connections = (core_count * 2) + effective_spindle_count
```

For SSDs (spindle count = 0): `connections = core_count * 2`

Example: 4-core server → 8-10 connections is often optimal. More connections increase contention overhead.

### Pool vs Thread Alignment

| Tomcat `max-threads` | HikariCP `maximum-pool-size` | Verdict |
|----------------------|------------------------------|---------|
| 200 | 5 | BAD — threads starve waiting for connections |
| 200 | 200 | BAD — too many connections, DB overloaded |
| 200 | 30-50 | GOOD — reasonable ratio for typical web workloads |

### maxLifetime vs Database

| Database | Default Timeout | HikariCP maxLifetime |
|----------|-----------------|----------------------|
| MySQL | `wait_timeout` = 28800s (8h) | 1740000ms (29min) recommended |
| PostgreSQL | No default idle timeout | 1800000ms (30min) reasonable |
| MariaDB | `wait_timeout` = 28800s (8h) | 1740000ms (29min) recommended |

Always set `maxLifetime` shorter than the DB's idle connection timeout. HikariCP default (30min) works for most databases, but verify against your DB configuration.

---

## Production Hardening — Actuator

### BAD — Actuator wide open

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"      # Exposes heapdump, env, shutdown
  endpoint:
    env:
      show-values: ALWAYS # Leaks secrets via /actuator/env
```

### GOOD — Actuator locked down

```yaml
management:
  server:
    port: 8081            # Separate port, not exposed to public
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      show-details: when-authorized
    env:
      show-values: NEVER
```

---

## Common Misspellings

| Misspelled | Correct |
|------------|---------|
| `spring.datasource.hikari.maxLiftime` | `spring.datasource.hikari.max-lifetime` |
| `spring.datasource.hikari.maxPoolSize` | `spring.datasource.hikari.maximum-pool-size` |
| `spring.jpa.hibernate.ddl_auto` | `spring.jpa.hibernate.ddl-auto` |
| `spring.datasource.jdbc-url` (with HikariCP) | `spring.datasource.url` (Boot auto-config) |
| `server.servlet.contextPath` | `server.servlet.context-path` |
| `spring.jackson.serialization.write_dates_as_timestamps` | `spring.jackson.serialization.write-dates-as-timestamps` |
| `spring.datasource.tomcat.max-active` | `spring.datasource.hikari.maximum-pool-size` (HikariCP replaced Tomcat pool) |
| `logging.level.org.springframework.Security` | `logging.level.org.springframework.security` (lowercase) |

Note: Spring Boot's relaxed binding accepts camelCase, kebab-case, and underscore variants for most properties. However, mixing styles within the same file creates confusion and makes property searches unreliable. Pick kebab-case (the Spring Boot convention) and use it consistently.
