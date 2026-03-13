# Spring Boot Code Review Checklist

## Controller Layer

### Request Handling
- All request parameters validated with `@Valid` / `@Validated`
- `@RequestBody` DTOs use Bean Validation annotations (`@NotNull`, `@Size`, `@Email`, etc.)
- `@PathVariable` validated for format (e.g., UUID pattern)
- No business logic in controllers — delegate to services
- Controllers are stateless (no instance fields holding request state)

### Response Handling
- Use `ResponseEntity<T>` for explicit status code control
- Return DTOs, never JPA entities directly
- Consistent error response format via `@RestControllerAdvice`
- No stack traces or internal details in error responses
- Pagination on all collection endpoints

### Mapping
- Use specific `@GetMapping`, `@PostMapping`, etc. over generic `@RequestMapping`
- No duplicate mappings
- Base path defined at class level with `@RequestMapping("/api/v1/resource")`

## Service Layer

### Transaction Management
- `@Transactional` on service methods that modify data, not on read-only methods
- `@Transactional(readOnly = true)` on read-only methods for optimization
- No `@Transactional` on private methods (won't work — proxy-based AOP)
- Propagation explicitly set when nesting transactions
- Rollback rules specified: `@Transactional(rollbackFor = Exception.class)` — default only rolls back on unchecked exceptions

### Exception Handling
- Use domain-specific exceptions (not generic `RuntimeException`)
- Don't catch exceptions just to re-throw them
- Don't swallow exceptions silently
- Log exceptions at the appropriate level

### Business Logic
- No direct repository calls from controllers — always go through service
- Service methods have single responsibility
- No circular service dependencies

## Repository Layer

### Query Methods
- Spring Data method names don't exceed 3-4 conditions (use `@Query` for complex queries)
- `@Query` uses named parameters (`:name`) not positional (`?1`)
- No string concatenation in queries (SQL injection risk)
- `@Modifying` annotation on update/delete queries
- `@Modifying(clearAutomatically = true)` to sync persistence context

### Performance
- Custom queries use projections (interface or class-based DTOs) for read-only data
- Pagination applied via `Pageable` parameter
- `@EntityGraph` used to avoid N+1 queries where needed
- Batch operations for bulk inserts/updates

## Configuration

### Properties
- Secrets not hardcoded — use environment variables, Vault, or encrypted properties
- Profile-specific configs (`application-dev.yml`, `application-prod.yml`) for environment differences
- `@ConfigurationProperties` with `@Validated` for type-safe config
- Reasonable defaults provided

### Beans
- Constructor injection (not field injection with `@Autowired`)
- `@Configuration` classes focused (not one giant config class)
- `@ConditionalOnProperty` / `@Profile` for environment-specific beans
- No `@ComponentScan` with overly broad base packages

### Actuator
- Actuator endpoints secured in production
- Only necessary endpoints exposed (`health`, `info`, `metrics`)
- Custom health indicators for critical dependencies
- `/actuator` base path changed from default in production

## Async and Scheduling

### `@Async`
- `@EnableAsync` configured with custom `TaskExecutor` (not default `SimpleAsyncTaskExecutor`)
- Thread pool sized appropriately (core, max, queue capacity)
- Return type is `CompletableFuture<T>` or `void` — not a regular return type
- Exception handling configured via `AsyncUncaughtExceptionHandler`

### `@Scheduled`
- `@EnableScheduling` present
- Fixed-rate vs. fixed-delay chosen correctly
- Cron expressions externalized to properties
- Distributed lock (ShedLock, etc.) for clustered deployments

## Logging

- SLF4J used (not `System.out.println` or `java.util.logging` directly)
- Log levels appropriate (ERROR for errors, WARN for recoverable issues, INFO for business events, DEBUG for debugging)
- No sensitive data in logs (passwords, tokens, PII)
- Parameterized logging: `log.info("User {} logged in", userId)` not `log.info("User " + userId + " logged in")`
- MDC used for request tracing
