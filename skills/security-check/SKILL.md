---
name: security-check
description: Review Spring Security configuration for vulnerabilities, misconfigured filter chains, CORS/CSRF issues, and authentication/authorization gaps.
---

# Spring Security Check

Review the Spring Security configuration for vulnerabilities and misconfigurations.

## Project Context

Security configuration:
!`grep -rln "SecurityFilterChain\|WebSecurityConfigurerAdapter\|@EnableWebSecurity\|@EnableMethodSecurity\|@EnableGlobalMethodSecurity" --include="*.java" . 2>/dev/null | head -10`

Security dependencies:
!`grep -E "spring-boot-starter-security\|spring-security\|oauth2\|jwt\|jjwt" pom.xml build.gradle 2>/dev/null | head -10`

Endpoint mappings:
!`grep -rn "@RequestMapping\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping" --include="*.java" . 2>/dev/null | head -30`

Properties:
!`grep -E "spring.security\|jwt\|oauth2\|cors" src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null | head -15`

## Review Checklist

### Filter Chain Configuration

1. **Deprecated `WebSecurityConfigurerAdapter`**: Must use component-based `SecurityFilterChain` `@Bean` (Spring Security 6+)
2. **Matcher ordering**: Most specific matchers must come first — `antMatchers("/admin/**")` before `antMatchers("/**")`
3. **Missing default deny**: The chain should end with `.anyRequest().authenticated()` or `.anyRequest().denyAll()` — never leave endpoints unmatched
4. **`permitAll()` on sensitive endpoints**: Verify no admin, actuator, or data-modifying endpoints are accidentally public
5. **Deprecated `authorizeRequests()`**: Must use `authorizeHttpRequests()` in Spring Security 6+

### CORS

1. **Wildcard origins**: `allowedOrigins("*")` in production is a vulnerability — use specific origins
2. **`allowCredentials(true)` with wildcard**: This combination is rejected by browsers but may indicate intent to be too permissive
3. **Missing CORS configuration**: If the API serves a separate frontend, CORS must be explicitly configured
4. **`@CrossOrigin` on individual controllers**: Prefer centralized CORS configuration in `SecurityFilterChain`

### CSRF

1. **CSRF disabled without justification**: Only disable for stateless APIs (JWT/token-based auth). Session-based apps MUST have CSRF enabled
2. **Missing CSRF token in forms**: If using Thymeleaf/JSP with sessions, forms need `_csrf` token
3. **CSRF token in URL**: Tokens should be in headers or form fields, never in URLs (logged in access logs)

### Authentication

1. **Password encoding**: Must use `BCryptPasswordEncoder` or `Argon2PasswordEncoder` — never `NoOpPasswordEncoder` or plain text
2. **Session fixation**: Verify `sessionManagement().sessionFixation().migrateSession()` (default, but check it's not overridden)
3. **Session timeout**: Should be configured explicitly, not left at default
4. **Remember-me security**: If used, must use persistent tokens, not simple hash-based

### Authorization

1. **Method-level security**: `@PreAuthorize` / `@Secured` should be used for fine-grained access control
2. **`@EnableMethodSecurity`**: Must replace deprecated `@EnableGlobalMethodSecurity`
3. **Role hierarchy**: If roles have inheritance (ADMIN > USER), configure `RoleHierarchy` bean
4. **Missing authorization on service layer**: Controller-level security can be bypassed via other entry points

### JWT/OAuth2 (if applicable)

1. **Algorithm verification**: JWT must verify algorithm (`RS256` preferred over `HS256` for distributed systems)
2. **Token expiry**: Access tokens should be short-lived (15-60 min), refresh tokens longer
3. **Token storage**: Tokens in `localStorage` are vulnerable to XSS — prefer `httpOnly` cookies
4. **Audience/Issuer validation**: JWT validation must check `aud` and `iss` claims

### Security Headers

1. **Content Security Policy**: Should be configured to prevent XSS
2. **X-Frame-Options**: Must be `DENY` or `SAMEORIGIN` to prevent clickjacking
3. **Strict-Transport-Security**: Must be set for HTTPS-only applications
4. **X-Content-Type-Options**: Should be `nosniff`

## Output Format

Rate overall security posture: **RED** (critical issues) / **YELLOW** (warnings) / **GREEN** (solid)

| Severity | Category | File:Line | Issue | OWASP | Fix |
|----------|----------|-----------|-------|-------|-----|
| CRITICAL / WARNING / INFO | Category | path:line | Description | OWASP ref | Fix |

For detailed security checklist, see [spring-security-checklist.md](references/spring-security-checklist.md).
