# Spring Security Checklist

## SecurityFilterChain Template (Spring Security 6.x)

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                // Disable ONLY for stateless APIs:
                // .disable()
            )
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .sessionFixation().migrateSession()
                .maximumSessions(1)
            )
            .authorizeHttpRequests(auth -> auth
                // Most specific first
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/users/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers("/api/public/**", "/actuator/health").permitAll()
                // Default deny
                .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

## CORS Configuration

### Restrictive (Production)
```java
@Bean
CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://app.example.com"));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
    config.setAllowCredentials(true);
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

### Development
```java
@Bean
@Profile("dev")
CorsConfigurationSource devCorsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("http://localhost:3000", "http://localhost:5173"));
    config.setAllowedMethods(List.of("*"));
    config.setAllowedHeaders(List.of("*"));
    config.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return source;
}
```

## JWT Validation Checklist

1. **Algorithm**: Verify the algorithm in the token header matches expected (`RS256` for asymmetric, `HS256` for symmetric)
2. **Expiration**: `exp` claim must be checked and enforced
3. **Issuer**: `iss` claim must match expected issuer
4. **Audience**: `aud` claim must match your service
5. **Not Before**: `nbf` claim should be checked
6. **Signature**: Always validate cryptographic signature
7. **Key Rotation**: Support JWK Set endpoints for key rotation

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .oauth2ResourceServer(oauth2 -> oauth2
            .jwt(jwt -> jwt
                .decoder(jwtDecoder())
                .jwtAuthenticationConverter(jwtAuthenticationConverter())
            )
        )
        .build();
}

@Bean
public JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = JwtDecoders.fromIssuerLocation(issuerUri);
    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
        JwtValidators.createDefaultWithIssuer(issuerUri),
        new JwtClaimValidator<>("aud", aud -> aud.contains(expectedAudience))
    ));
    return decoder;
}
```

## Security Headers

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .headers(headers -> headers
            .contentSecurityPolicy(csp -> csp
                .policyDirectives("default-src 'self'; script-src 'self'; style-src 'self'"))
            .frameOptions(frame -> frame.deny())
            .httpStrictTransportSecurity(hsts -> hsts
                .includeSubDomains(true)
                .maxAgeInSeconds(31536000))
            .contentTypeOptions(Customizer.withDefaults()) // X-Content-Type-Options: nosniff
        )
        .build();
}
```

## Common Vulnerabilities

### Insecure Direct Object Reference (IDOR)
```java
// BAD — any authenticated user can access any user's data
@GetMapping("/users/{id}")
public UserDto getUser(@PathVariable Long id) {
    return userService.findById(id);
}

// GOOD — verify ownership
@GetMapping("/users/{id}")
public UserDto getUser(@PathVariable Long id, Authentication auth) {
    UserDto user = userService.findById(id);
    if (!user.username().equals(auth.getName())) {
        throw new AccessDeniedException("Not your resource");
    }
    return user;
}

// BETTER — use @PreAuthorize
@PreAuthorize("#id == authentication.principal.id or hasRole('ADMIN')")
@GetMapping("/users/{id}")
public UserDto getUser(@PathVariable Long id) {
    return userService.findById(id);
}
```

### Mass Assignment
```java
// BAD — user can set role via request body
@PostMapping("/users")
public User createUser(@RequestBody User user) {
    return userRepository.save(user); // user.role could be "ADMIN"
}

// GOOD — use a DTO that excludes sensitive fields
@PostMapping("/users")
public UserDto createUser(@RequestBody @Valid CreateUserRequest request) {
    return userService.createUser(request); // CreateUserRequest has no role field
}
```

## Actuator Security

```java
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/actuator/health", "/actuator/info").permitAll()
    .requestMatchers("/actuator/**").hasRole("ADMIN")
)
```

```properties
# Expose only needed endpoints
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=when-authorized
management.server.port=9090  # Separate management port
```
