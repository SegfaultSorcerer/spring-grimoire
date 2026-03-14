---
name: spring-migration
description: Analyze a Spring Boot project for migration from Spring Boot 2 to 3 and javax to jakarta namespace changes. Generates a migration report with file-by-file changes needed.
allowed-tools: Bash(*)
---

# Spring Boot Migration Analysis

Analyze the project for Spring Boot 2 to 3 migration requirements.

## Project Context

Current Spring Boot version:
!`grep -A1 "spring-boot-starter-parent\|spring-boot.*version" pom.xml 2>/dev/null | head -5`
!`grep "org.springframework.boot" build.gradle 2>/dev/null | head -5`

Java version:
!`grep -E "java.version|sourceCompatibility|targetCompatibility" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -5`

Files using javax namespace:
!`grep -rln "^import javax\." --include="*.java" . 2>/dev/null | head -20`

Spring Security configuration:
!`grep -rln "WebSecurityConfigurerAdapter\|authorizeRequests\|antMatchers\|mvcMatchers" --include="*.java" . 2>/dev/null | head -10`

Properties files:
!`ls src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null`

## Migration Analysis Steps

### 1. Namespace Migration (javax → jakarta)

Scan all Java files for `javax.*` imports that need to change:

| Old Package | New Package |
|-------------|-------------|
| `javax.persistence.*` | `jakarta.persistence.*` |
| `javax.servlet.*` | `jakarta.servlet.*` |
| `javax.validation.*` | `jakarta.validation.*` |
| `javax.annotation.*` | `jakarta.annotation.*` |
| `javax.transaction.*` | `jakarta.transaction.*` |
| `javax.websocket.*` | `jakarta.websocket.*` |
| `javax.mail.*` | `jakarta.mail.*` |
| `javax.inject.*` | `jakarta.inject.*` |

**Note:** `javax.sql.*`, `javax.crypto.*`, `javax.net.*` do NOT change — they are part of the JDK.

For complete mappings, see [javax-to-jakarta-mappings.md](references/javax-to-jakarta-mappings.md).

### 2. Spring Security 6 Changes

1. **`WebSecurityConfigurerAdapter` removed**: Migrate to component-based `SecurityFilterChain` `@Bean`
2. **`authorizeRequests()` → `authorizeHttpRequests()`**
3. **`antMatchers()` → `requestMatchers()`**
4. **`mvcMatchers()` → `requestMatchers()`**
5. **`@EnableGlobalMethodSecurity` → `@EnableMethodSecurity`**: `prePostEnabled` is now true by default
6. **`access()` expressions**: Migrate from String-based to `AuthorizationManager`-based

### 3. Configuration Property Changes

| Old Property | New Property |
|-------------|-------------|
| `spring.redis.*` | `spring.data.redis.*` |
| `spring.data.cassandra.*` | `spring.cassandra.*` |
| `spring.jpa.hibernate.use-new-id-generator-mappings` | Removed (always true) |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `spring.security.oauth2.resourceserver.jwt.jws-algorithm` | `spring.security.oauth2.resourceserver.jwt.jws-algorithms` |

### 4. Behavior Changes

1. **Trailing slash matching disabled**: `GET /users/` no longer matches `GET /users` by default
2. **`PathPatternParser` is default**: Replaces `AntPathMatcher` — some patterns may differ
3. **Hibernate 6**: Query behavior changes, especially around implicit joins and HQL
4. **Flyway 9+**: Callback interface changes
5. **`@ConstructorBinding` on type removed**: Now only needed on specific constructor if multiple exist

### 5. Dependency Coordinate Changes

Check `pom.xml` / `build.gradle` for outdated coordinates.

For complete breaking changes, see [spring-boot-3-breaking-changes.md](references/spring-boot-3-breaking-changes.md).

## Output Format

### Migration Report

**Effort Estimate:** LOW / MEDIUM / HIGH

| Priority | Category | Files Affected | Change Required |
|----------|----------|----------------|-----------------|
| 1 | javax → jakarta | file1.java, file2.java | Replace imports |
| 2 | Security config | SecurityConfig.java | Rewrite filter chain |
| ... | ... | ... | ... |

For each category, provide:
1. Files affected (list)
2. Specific changes needed
3. Potential breaking changes to watch for
4. Testing recommendations
