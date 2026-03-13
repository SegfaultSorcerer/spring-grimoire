---
name: api-design
description: Review REST API design against best practices including URL naming, HTTP verbs, status codes, error responses, pagination, and versioning.
argument-hint: "[controller-file]"
---

# REST API Design Review

Review REST API design against industry best practices.

## Scope

If a specific file is provided: `$ARGUMENTS`
Otherwise, review all controllers.

## Project Context

Endpoint mappings:
!`grep -rn "@RequestMapping\|@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping" --include="*.java" . 2>/dev/null | head -50`

Response entities and DTOs:
!`grep -rln "ResponseEntity\|@ResponseStatus\|@ResponseBody" --include="*.java" . 2>/dev/null | head -15`

Exception handlers:
!`grep -rn "@ExceptionHandler\|@ControllerAdvice\|@RestControllerAdvice" --include="*.java" . 2>/dev/null | head -10`

## Review Dimensions

### URL Naming

1. **Use nouns, not verbs**: `/users` not `/getUsers`, `/orders/{id}` not `/fetchOrder/{id}`
2. **Plural resource names**: `/users`, `/products`, `/orders` — consistently plural
3. **Lowercase with hyphens**: `/order-items` not `/orderItems` or `/order_items`
4. **No trailing slashes**: `/users` not `/users/`
5. **Nested resources for relationships**: `/users/{id}/orders` not `/getUserOrders`
6. **Max 2 levels of nesting**: Beyond that, use query parameters or top-level resources
7. **No file extensions**: `/users` not `/users.json`

### HTTP Verbs

| Operation | Verb | Status Code | Idempotent |
|-----------|------|-------------|------------|
| List/Search | GET | 200 | Yes |
| Get by ID | GET | 200, 404 | Yes |
| Create | POST | 201 + Location header | No |
| Full update | PUT | 200, 404 | Yes |
| Partial update | PATCH | 200, 404 | No |
| Delete | DELETE | 204, 404 | Yes |

1. **GET must not mutate state**: No side effects, no database writes
2. **POST for creation**: Return `201 Created` with `Location` header pointing to the new resource
3. **PUT vs PATCH**: PUT replaces the entire resource, PATCH updates specific fields
4. **DELETE returns 204**: No body needed on successful deletion

### Response Status Codes

1. **Don't return 200 for everything**: Use appropriate status codes
2. **400 for validation errors**: With details about which fields failed
3. **401 vs 403**: 401 = not authenticated, 403 = authenticated but not authorized
4. **404 for missing resources**: Not 200 with empty body
5. **409 for conflicts**: Duplicate entries, concurrent modification
6. **422 for semantic errors**: Request is syntactically valid but semantically wrong

### Error Response Format

Follow RFC 7807 (Problem Details for HTTP APIs):

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

1. **Consistent error structure**: All errors must follow the same format
2. **Global `@RestControllerAdvice`**: Handle exceptions centrally, don't catch in each controller
3. **No stack traces in production**: Never expose internal details in error responses
4. **Validation error details**: Include field-level errors for 400 responses

### Pagination

1. **Collection endpoints must be paginated**: Never return unbounded lists
2. **Use `Pageable` parameter**: `GET /users?page=0&size=20&sort=name,asc`
3. **Return page metadata**: total elements, total pages, current page, page size
4. **Consistent response wrapper**: Use Spring's `Page<T>` or a custom wrapper

### Versioning

1. **API version strategy**: URL path (`/v1/users`), header, or media type — pick one, be consistent
2. **No version is a risk**: APIs without versioning cannot evolve without breaking clients

### Content Negotiation

1. **Accept and Content-Type headers**: Respect them properly
2. **Default to JSON**: But support `application/xml` if needed
3. **Use DTOs**: Never expose JPA entities directly as API responses

## Output Format

Endpoint inventory with issues:

| Method | URL | Issues | Recommendation |
|--------|-----|--------|----------------|
| GET | /api/users | - | Correct |
| POST | /api/createUser | Verb in URL, missing 201 | Rename to POST /api/users, return 201 |

For detailed conventions, see [rest-api-conventions.md](references/rest-api-conventions.md).
