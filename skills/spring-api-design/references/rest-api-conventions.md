# REST API Conventions Reference

## Richardson Maturity Model

| Level | Description | Example |
|-------|-------------|---------|
| 0 | Single URI, single verb | POST /api with action in body |
| 1 | Multiple URIs, single verb | POST /api/users, POST /api/orders |
| 2 | Multiple URIs, correct verbs | GET /users, POST /users, DELETE /users/1 |
| 3 | HATEOAS (Hypermedia) | Responses include links to related actions |

Target: Level 2 minimum, Level 3 for public APIs.

## Error Response Format (RFC 7807)

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Resource Not Found");
        problem.setType(URI.create("https://api.example.com/problems/not-found"));
        return problem;
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers,
            HttpStatusCode status, WebRequest request) {
        ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        problem.setTitle("Validation Error");

        List<Map<String, String>> errors = ex.getBindingResult()
            .getFieldErrors().stream()
            .map(fe -> Map.of(
                "field", fe.getField(),
                "message", fe.getDefaultMessage()))
            .toList();
        problem.setProperty("errors", errors);

        return ResponseEntity.badRequest().body(problem);
    }
}
```

## Pagination Patterns

### Spring Data Pageable
```java
@GetMapping("/users")
public Page<UserDto> getUsers(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(defaultValue = "name,asc") String[] sort) {
    Pageable pageable = PageRequest.of(page, size, Sort.by(parseSortOrders(sort)));
    return userService.findAll(pageable);
}
```

Response includes:
```json
{
  "content": [...],
  "totalElements": 142,
  "totalPages": 8,
  "size": 20,
  "number": 0,
  "first": true,
  "last": false
}
```

### Cursor-Based Pagination (for real-time data)
```java
@GetMapping("/events")
public CursorPage<EventDto> getEvents(
        @RequestParam(required = false) String cursor,
        @RequestParam(defaultValue = "20") int limit) {
    return eventService.findAfterCursor(cursor, limit);
}
```

## Filtering and Sorting

```
GET /users?status=active&role=admin&sort=name,asc&sort=createdAt,desc
GET /orders?minTotal=100&maxTotal=500&status=shipped
GET /products?search=laptop&category=electronics&inStock=true
```

- Use flat query parameters for simple filters
- Use specification pattern (Spring Data JPA Specifications) for dynamic queries
- Document available filter fields in API docs

## Versioning Strategies

### URL Path (Recommended for simplicity)
```java
@RestController
@RequestMapping("/api/v1/users")
public class UserControllerV1 { ... }

@RestController
@RequestMapping("/api/v2/users")
public class UserControllerV2 { ... }
```

### Header-Based
```java
@GetMapping(value = "/users", headers = "X-API-Version=2")
public List<UserV2Dto> getUsersV2() { ... }
```

### Media Type
```java
@GetMapping(value = "/users", produces = "application/vnd.api.v2+json")
public List<UserV2Dto> getUsersV2() { ... }
```

## Rate Limiting Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1672531200
Retry-After: 60
```

## OpenAPI Annotations

```java
@Operation(
    summary = "Get user by ID",
    description = "Returns a single user by their unique identifier")
@ApiResponses({
    @ApiResponse(responseCode = "200", description = "User found"),
    @ApiResponse(responseCode = "404", description = "User not found",
        content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
})
@GetMapping("/{id}")
public UserDto getUser(
    @Parameter(description = "User ID", example = "123")
    @PathVariable Long id) { ... }
```

## Response Wrapper Pattern

```java
// For APIs that need metadata beyond what Page<T> provides
public record ApiResponse<T>(
    T data,
    Map<String, Object> metadata
) {
    public static <T> ApiResponse<T> of(T data) {
        return new ApiResponse<>(data, Map.of());
    }

    public static <T> ApiResponse<T> of(T data, String key, Object value) {
        return new ApiResponse<>(data, Map.of(key, value));
    }
}
```
