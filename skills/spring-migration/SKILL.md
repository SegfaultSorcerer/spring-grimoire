---
name: spring-migration
description: >
  Analyze a Spring Boot project for migration from Spring Boot 2 to 3
  (or between minor versions). Generates a migration report covering
  javax→jakarta namespace changes, Spring Security 6 API changes,
  configuration property renames, behavior changes, and effort estimate.
  Use this skill whenever the user wants to upgrade, migrate, or update
  their Spring Boot version, move from Boot 2 to 3, or asks about
  javax to jakarta changes, Spring Security migration, or Spring Boot
  compatibility issues.
argument-hint: "[target-version]"
allowed-tools: Bash(*)
---

# Spring Boot Migration Analysis

Analyze the project for Spring Boot migration requirements.

## Project Context

Current Spring Boot version:
!`grep -A1 "spring-boot-starter-parent\|spring-boot.*version" pom.xml 2>/dev/null | head -5`
!`grep "org.springframework.boot" build.gradle build.gradle.kts 2>/dev/null | head -5`

Java version:
!`grep -E "java.version|sourceCompatibility|targetCompatibility" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -5`

Files using javax namespace:
!`grep -rln "^import javax\." --include="*.java" . 2>/dev/null | head -20`

Spring Security configuration:
!`grep -rln "WebSecurityConfigurerAdapter\|authorizeRequests\|antMatchers\|mvcMatchers\|EnableGlobalMethodSecurity" --include="*.java" . 2>/dev/null | head -10`

Properties files:
!`ls src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null`

Spring Cloud dependencies:
!`grep -E "spring-cloud|spring-cloud-dependencies" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -5`

Database migration tool:
!`grep -E "flyway|liquibase" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -5`

Deprecated test patterns:
!`grep -rln "@MockBean\|@SpyBean" --include="*.java" . 2>/dev/null | head -10`

## Migration Analysis Steps

Read the reference files before producing the report — they contain the complete mappings and code examples that the analysis should draw from:
- [javax-to-jakarta-mappings.md](references/javax-to-jakarta-mappings.md) for namespace changes and dependency coordinates
- [spring-boot-3-breaking-changes.md](references/spring-boot-3-breaking-changes.md) for Security, property, and behavior changes

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

**Critical:** `javax.sql.*`, `javax.crypto.*`, `javax.net.*` do NOT change — they are part of the JDK, not Jakarta EE. Incorrectly renaming these will break compilation.

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

### 6. Spring Cloud Compatibility

If the project uses Spring Cloud, check the compatibility matrix. Spring Cloud releases are tied to specific Spring Boot versions:

| Spring Boot | Spring Cloud |
|-------------|-------------|
| 3.0.x | 2022.0.x (Kilburn) |
| 3.1.x | 2022.0.x |
| 3.2.x | 2023.0.x (Leyton) |
| 3.3.x | 2023.0.x |
| 3.4.x | 2024.0.x |

### 7. Automated Migration Tooling

Recommend OpenRewrite for automated refactoring — it handles the bulk of mechanical changes (namespace renames, API replacements):

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <version>5.x</version>
    <configuration>
        <activeRecipes>
            <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0</recipe>
        </activeRecipes>
    </configuration>
</plugin>
```

## Output Format

### Migration Report

**Current Version:** X.Y.Z → **Target Version:** X.Y.Z

**Effort Estimate:** LOW / MEDIUM / HIGH
- **LOW**: Only namespace changes, no Security or behavior changes
- **MEDIUM**: Namespace + Security config rewrite, few property changes
- **HIGH**: Major Security rewrite, Spring Cloud upgrade, Hibernate query changes, or 50+ files affected

| Priority | Category | Files Affected | Change Required | Effort |
|----------|----------|----------------|-----------------|--------|
| 1 | javax → jakarta | file1.java, file2.java | Replace imports | LOW |
| 2 | Security config | SecurityConfig.java | Rewrite filter chain | HIGH |
| ... | ... | ... | ... | ... |

For each category, provide:
1. Files affected (list with count)
2. Specific changes needed (with before/after examples for non-trivial changes)
3. Potential breaking changes to watch for
4. Testing recommendations

End with a **Top 3 Migration Steps** summary — the three highest-impact actions to take first, ordered by risk.
