# Spring Boot 3 Breaking Changes

## Spring Security 6

### WebSecurityConfigurerAdapter Removed

```java
// OLD (Spring Security 5)
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
            .antMatchers("/public/**").permitAll()
            .anyRequest().authenticated();
    }
}

// NEW (Spring Security 6)
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .build();
    }
}
```

### Method Changes

| Old | New |
|-----|-----|
| `authorizeRequests()` | `authorizeHttpRequests()` |
| `antMatchers()` | `requestMatchers()` |
| `mvcMatchers()` | `requestMatchers()` |
| `regexMatchers()` | `requestMatchers(new RegexRequestMatcher(...))` |
| `access("hasRole('ADMIN')")` | `access(new WebExpressionAuthorizationManager(...))` or `hasRole("ADMIN")` |
| `@EnableGlobalMethodSecurity` | `@EnableMethodSecurity` |

### @EnableMethodSecurity Defaults

```java
// OLD
@EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true)

// NEW — prePostEnabled is true by default
@EnableMethodSecurity(securedEnabled = true)
```

## Configuration Property Changes

| Old Property | New Property |
|-------------|-------------|
| `spring.redis.*` | `spring.data.redis.*` |
| `spring.data.cassandra.*` | `spring.cassandra.*` |
| `spring.jpa.hibernate.use-new-id-generator-mappings` | Removed (always true) |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `spring.security.oauth2.resourceserver.jwt.jws-algorithm` | `spring.security.oauth2.resourceserver.jwt.jws-algorithms` |
| `spring.mvc.throw-exception-if-no-handler-found` | Now true by default |
| `spring.resources.add-mappings` | `spring.web.resources.add-mappings` |
| `spring.session.store-type` | Auto-detected, property removed |

## Behavior Changes

### Trailing Slash Matching Disabled

```java
// Spring Boot 2: GET /users/ matched GET /users
// Spring Boot 3: GET /users/ returns 404

// To restore old behavior (not recommended):
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.setUseTrailingSlashMatch(true); // deprecated, will be removed
    }
}
```

### PathPatternParser is Default

```
// AntPathMatcher patterns that won't work with PathPatternParser:
/users/{name:regex}  // named regex groups syntax changed
/**/*.json           // suffix patterns no longer supported
```

### Hibernate 6

- HQL/JPQL implicit joins behavior changed
- `@Type` annotation replaced with `@JdbcTypeCode`
- ID generation defaults changed (always uses new generator mappings)
- Some SQL dialect changes

### Auto-Configuration Changes

| Change | Impact |
|--------|--------|
| `spring.jpa.open-in-view` still defaults to `true` | No change, but you should set to `false` |
| Flyway 9+ | `FlywayCallback` interface changes |
| Jackson `ObjectMapper` | ISO-8601 date formatting by default |
| Micrometer | Tags API changed in some places |

### Observability

Spring Boot 3 uses Micrometer Observation API:
- `spring-boot-starter-actuator` includes Micrometer
- Distributed tracing via Micrometer Tracing (replaces Spring Cloud Sleuth)
- `management.tracing.*` properties replace `spring.sleuth.*`

## Java Version

- Spring Boot 3.0+ requires **Java 17** minimum
- Spring Boot 3.2+ supports **Java 21** (virtual threads via `spring.threads.virtual.enabled=true`)
- Spring Boot 3.4+ requires **Java 17** minimum, recommends **Java 21**

## Migration Tooling

- **OpenRewrite**: Automated migration recipes
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
- **Spring Boot Migrator**: CLI tool for automated analysis
- **IntelliJ IDEA**: Refactor > Migrate Packages and Classes
