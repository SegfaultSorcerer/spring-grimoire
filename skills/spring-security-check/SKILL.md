---
name: spring-security-check
description: Review Spring Security configuration for vulnerabilities, misconfigured filter chains, CORS/CSRF issues, authentication/authorization gaps, and security anti-patterns. Use this skill whenever the user wants to check, audit, or review the security of their Spring Boot application — even if they just say "ist meine App sicher?", "check mal die Auth", "security audit", "passt die Security Config?", or ask about CORS/CSRF/JWT issues.
argument-hint: "[security-config-file]"
allowed-tools: Bash(*)
---

# Spring Security Check

Review the Spring Security configuration for vulnerabilities and misconfigurations. Read [spring-security-checklist.md](references/spring-security-checklist.md) for code examples (SecurityFilterChain template, CORS configs, JWT validation, IDOR/Mass Assignment patterns) before starting your review — the reference contains fix patterns you should recommend.

## Scope

If a specific file is provided: `$ARGUMENTS`
Otherwise, review the entire project's security configuration.

## Project Context

Security configuration:
!`grep -rln "SecurityFilterChain\|WebSecurityConfigurerAdapter\|@EnableWebSecurity\|@EnableMethodSecurity\|@EnableGlobalMethodSecurity" --include="*.java" --include="*.kt" . 2>/dev/null | head -10`

Security dependencies:
!`grep -E "spring-boot-starter-security\|spring-security\|oauth2\|jwt\|jjwt" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -10`

Endpoint mappings:
!`grep -rn "@RequestMapping\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping" --include="*.java" --include="*.kt" . 2>/dev/null | head -30`

Properties:
!`grep -rE "spring.security|spring.h2|jwt|oauth2|cors|debug" src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null | head -20`

## Review Checklist

### 1. Filter Chain Configuration (review first — this is the foundation)

1. **Deprecated `WebSecurityConfigurerAdapter`**: Must use component-based `SecurityFilterChain` `@Bean` (Spring Security 6+)
2. **Deprecated `authorizeRequests()`**: Must use `authorizeHttpRequests()` in Spring Security 6+
3. **Matcher ordering**: Most specific matchers must come first — `requestMatchers("/admin/**")` before `requestMatchers("/**")`. Wrong order means permissive rules match first and restrictive ones are never reached
4. **Missing default deny**: The chain should end with `.anyRequest().authenticated()` or `.anyRequest().denyAll()` — unmatched endpoints are silently open
5. **`permitAll()` on sensitive endpoints**: Verify no admin, actuator, or data-modifying endpoints are accidentally public
6. **Missing security entirely**: If there is no `spring-boot-starter-security` dependency, all endpoints are completely open

### 2. CORS

1. **Wildcard origins**: `allowedOrigins("*")` in production allows any website to make authenticated requests to your API
2. **`allowCredentials(true)` with wildcard**: Browsers reject this combination, but it signals intent to be too permissive
3. **Missing CORS configuration**: If the API serves a separate frontend, CORS must be explicitly configured
4. **`@CrossOrigin` on individual controllers**: Prefer centralized CORS configuration in `SecurityFilterChain` — scattered annotations are easy to misconfigure and hard to audit

### 3. CSRF

1. **CSRF disabled without justification**: Only disable for stateless APIs (JWT/token-based auth). Session-based apps MUST have CSRF enabled — without it, any website can make authenticated requests using the user's session cookie
2. **Missing CSRF token in forms**: If using Thymeleaf/JSP with sessions, forms need `_csrf` token
3. **CSRF token in URL**: Tokens should be in headers or form fields, never in URLs (logged in access logs, browser history, Referer headers)

### 4. Authentication

1. **Password encoding**: Must use `BCryptPasswordEncoder` or `Argon2PasswordEncoder` — never `NoOpPasswordEncoder` or plain text. `NoOpPasswordEncoder` is deprecated for a reason
2. **Hardcoded credentials**: Passwords, API keys, or tokens in source code or non-profile-specific config files
3. **Session fixation**: Verify `sessionManagement().sessionFixation().migrateSession()` (default, but check it's not overridden to `none()`)
4. **Session timeout**: Should be configured explicitly, not left at server default (usually 30 min)
5. **Remember-me security**: If used, must use persistent tokens, not simple hash-based

### 5. Authorization

1. **Method-level security**: `@PreAuthorize` / `@Secured` should be used for fine-grained access control
2. **`@EnableMethodSecurity`**: Must replace deprecated `@EnableGlobalMethodSecurity`
3. **`@Secured` with wrong prefix**: `@Secured("ADMIN")` does not work — must be `@Secured("ROLE_ADMIN")`. This silently fails and grants no access or bypasses the check
4. **IDOR (Insecure Direct Object Reference)**: Endpoints like `GET /users/{id}` that don't verify the authenticated user owns the resource — any authenticated user can access any user's data
5. **Missing authorization on service layer**: Controller-level security can be bypassed via other entry points (schedulers, message listeners, internal calls)
6. **Role hierarchy**: If roles have inheritance (ADMIN > USER), configure `RoleHierarchy` bean

### 6. JWT/OAuth2 (if applicable)

1. **Algorithm verification**: JWT must verify algorithm (`RS256` preferred over `HS256` for distributed systems). Never accept `none` algorithm
2. **Token expiry**: Access tokens should be short-lived (15-60 min), refresh tokens longer
3. **Token storage**: Tokens in `localStorage` are vulnerable to XSS — prefer `httpOnly` cookies
4. **Audience/Issuer validation**: JWT validation must check `aud` and `iss` claims
5. **Secret key strength**: HMAC keys must be at least 256 bits. Hardcoded JWT secrets in source code are a critical vulnerability

### 7. Security Headers

1. **Content Security Policy**: Should be configured to prevent XSS — at minimum `default-src 'self'`
2. **X-Frame-Options**: Must be `DENY` or `SAMEORIGIN` to prevent clickjacking
3. **Strict-Transport-Security**: Must be set for HTTPS applications (Spring Security sets this by default for HTTPS)
4. **X-Content-Type-Options**: Should be `nosniff` (Spring Security default, but verify not overridden)

### 8. Dangerous Dev/Debug Settings in Production

These are settings that are fine in development but become security vulnerabilities in production:

1. **`spring.h2.console.enabled=true`**: Exposes an unauthenticated database console — attackers can read/write the entire database
2. **`spring.security.debug=true`**: Logs full security filter chain details including authentication tokens and headers
3. **Actuator `include: "*"`**: Exposes `/actuator/env` (leaks secrets), `/actuator/heapdump` (leaks memory), `/actuator/shutdown` (DoS)
4. **`ddl-auto: create` or `update`**: Hibernate can modify the production database schema unexpectedly

## Output Format

Rate overall security posture: **RED** (critical issues found) / **YELLOW** (warnings, no criticals) / **GREEN** (solid configuration)

| Severity | Category | File:Line | Issue | OWASP | Fix |
|----------|----------|-----------|-------|-------|-----|
| CRITICAL | Category | path:line | Description | OWASP ref | Recommended fix |
| WARNING | Category | path:line | Description | OWASP ref | Recommended fix |
| INFO | Category | path:line | Description | OWASP ref | Recommended fix |

**Severity guide:**
- **CRITICAL**: Exploitable vulnerabilities — missing auth, wildcard CORS with credentials, NoOpPasswordEncoder, hardcoded secrets, open H2 console, exposed actuator. These can be exploited today.
- **WARNING**: Misconfigurations that weaken security — CSRF disabled for session-based auth, missing default deny, missing security headers, `@Secured` with wrong prefix. These create attack surface.
- **INFO**: Best practice improvements — missing method-level security, session timeout not configured, missing HSTS. These are defense-in-depth.

End with a summary: overall rating (RED/YELLOW/GREEN), total findings by severity, and the **top 3 things to fix first**.

For implementation patterns, see [spring-security-checklist.md](references/spring-security-checklist.md).
