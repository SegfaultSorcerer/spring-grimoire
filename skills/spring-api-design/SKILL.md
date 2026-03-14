---
name: spring-api-design
description: Review REST API design against best practices — URL naming, HTTP verbs, status codes, error handling, pagination, versioning, and idempotency. Use this skill whenever the user wants to review, check, or improve their REST API, endpoints, or controller design — even if they just say "passt meine API so?", "check my endpoints", "schau dir mal die Controller an", or ask about REST conventions.
argument-hint: "[controller-file]"
allowed-tools: Bash(*)
---

# REST API Design Review

Review REST API design against industry best practices. Read [rest-api-conventions.md](references/rest-api-conventions.md) for code examples (RFC 7807 error handler, pagination patterns, OpenAPI annotations, versioning strategies) before starting your review — the reference contains implementation patterns you should recommend.

## Scope

If a specific file is provided: `$ARGUMENTS`
Otherwise, review all controllers.

## Project Context

Endpoint mappings:
!`grep -rn "@RequestMapping\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping" --include="*.java" --include="*.kt" . 2>/dev/null | head -50`

Response entities and DTOs:
!`grep -rln "ResponseEntity\|@ResponseStatus\|@ResponseBody" --include="*.java" --include="*.kt" . 2>/dev/null | head -15`

Exception handlers:
!`grep -rn "@ExceptionHandler\|@ControllerAdvice\|@RestControllerAdvice" --include="*.java" --include="*.kt" . 2>/dev/null | head -10`

## Review Dimensions

### 1. URL Naming

1. **Use nouns, not verbs**: `/users` not `/getUsers`, `/orders/{id}` not `/fetchOrder/{id}`
2. **Plural resource names**: `/users`, `/products`, `/orders` — consistently plural
3. **Lowercase with hyphens**: `/order-items` not `/orderItems` or `/order_items`
4. **No trailing slashes**: `/users` not `/users/`
5. **Nested resources for relationships**: `/users/{id}/orders` not `/getUserOrders`
6. **Max 2 levels of nesting**: Beyond that, use query parameters or top-level resources
7. **No file extensions**: `/users` not `/users.json`

### 2. HTTP Verbs & Idempotency

| Operation | Verb | Status Code | Idempotent |
|-----------|------|-------------|------------|
| List/Search | GET | 200 | Yes |
| Get by ID | GET | 200, 404 | Yes |
| Create | POST | 201 + Location header | No |
| Full update | PUT | 200, 404 | Yes |
| Partial update | PATCH | 200, 404 | No |
| Delete | DELETE | 204, 404 | Yes |

1. **GET must not mutate state**: No side effects, no database writes. A GET that triggers a write (even logging to DB) is a design violation because clients and intermediaries (caches, proxies) assume GET is safe to retry
2. **POST for creation**: Return `201 Created` with `Location` header pointing to the new resource
3. **PUT vs PATCH**: PUT replaces the entire resource, PATCH updates specific fields — using PUT for partial updates leads to accidental field nulling
4. **DELETE returns 204**: No body needed on successful deletion
5. **Idempotency violations**: PUT and DELETE must produce the same result when called multiple times. Check that PUT handlers don't create new resources on each call, and DELETE handlers don't fail on already-deleted resources (return 204 or 404, not 500)

### 3. Response Status Codes

1. **Don't return 200 for everything**: Every endpoint that just returns 200 is hiding information from the client. Check for POST returning 200 instead of 201, DELETE returning 200 instead of 204
2. **400 for validation errors**: With details about which fields failed
3. **401 vs 403**: 401 = not authenticated (who are you?), 403 = authenticated but not authorized (you can't do that). Mixing these up confuses client-side error handling
4. **404 for missing resources**: Not 200 with empty body or null
5. **409 for conflicts**: Duplicate entries, concurrent modification, optimistic locking failures
6. **422 for semantic errors**: Request is syntactically valid but semantically wrong

### 4. Error Response Format

Follow RFC 7807 (Problem Details for HTTP APIs) — Spring Boot 3.x has built-in support via `ProblemDetail`:

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The request body contains invalid fields.",
  "instance": "/users/123",
  "errors": [
    { "field": "email", "message": "must be a valid email address" }
  ]
}
```

1. **Consistent error structure**: All errors must follow the same format — clients should be able to write one error parser
2. **Global `@RestControllerAdvice`**: Handle exceptions centrally, don't catch in each controller. Without this, Spring returns its default whitelabel error page or inconsistent JSON
3. **No stack traces in production**: Never expose internal details in error responses
4. **Validation error details**: Include field-level errors for 400 responses so clients can highlight the right form field

### 5. Pagination

1. **Collection endpoints must be paginated**: Never return unbounded lists — this is a correctness issue, not just performance. An endpoint that returns 100k rows will crash mobile clients
2. **Use `Pageable` parameter**: `GET /users?page=0&size=20&sort=name,asc`
3. **Return page metadata**: total elements, total pages, current page, page size
4. **Default page size**: Set a reasonable default (e.g., 20) and a maximum (e.g., 100) to prevent `?size=999999`
5. **Consistent response wrapper**: Use Spring's `Page<T>` or a custom wrapper — don't return raw `List<T>` from some endpoints and `Page<T>` from others

### 6. Versioning

1. **API version strategy**: URL path (`/v1/users`), header, or media type — pick one, be consistent across the entire API
2. **No version is a risk**: APIs without versioning cannot evolve without breaking clients. At minimum, use a `/api/v1/` prefix so there's a migration path

### 7. Request/Response Design

1. **Use DTOs**: Never expose JPA entities directly as API responses — this leaks internal fields (IDs, foreign keys, passwords) and couples your API contract to your database schema. Any schema migration breaks all clients
2. **Separate request and response DTOs**: A create request usually has different fields than the response (e.g., no `id`, no `createdAt`)
3. **Accept and Content-Type headers**: Respect them properly, default to `application/json`
4. **Consistent field naming**: Pick `camelCase` or `snake_case` for JSON and stick with it project-wide

## Output Format

First, build a full endpoint inventory table:

| Method | URL | Status Code | Issues | Recommendation |
|--------|-----|-------------|--------|----------------|
| GET | /api/users | 200 | No pagination | Add `Pageable`, return `Page<UserDto>` |
| POST | /api/createUser | 200 | Verb in URL, wrong status code, no Location header | Rename to `POST /api/v1/users`, return 201 + Location |

Then list any cross-cutting issues (missing `@RestControllerAdvice`, no versioning strategy, inconsistent DTOs).

End with a summary: total endpoints reviewed, issues by severity, and the **top 3 things to fix first**.

For implementation patterns, see [rest-api-conventions.md](references/rest-api-conventions.md).
