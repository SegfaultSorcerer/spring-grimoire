---
name: jpa-audit
description: Audit JPA entities for N+1 query problems, missing database indexes, lazy loading issues, and relationship anti-patterns. Use when reviewing entity classes, repositories, or investigating database performance.
argument-hint: "[entity-or-directory]"
---

# JPA Entity Audit

Audit JPA entities and repositories for performance problems and anti-patterns.

## Scope

If a specific file or directory is provided: `$ARGUMENTS`
Otherwise, audit all entities in the project.

## Project Context

Entity classes:
!`grep -rln "@Entity" --include="*.java" . 2>/dev/null | head -20`

Relationship annotations:
!`grep -rn "@OneToMany\|@ManyToOne\|@ManyToMany\|@OneToOne\|@ElementCollection" --include="*.java" . 2>/dev/null | head -30`

Repository interfaces:
!`grep -rln "extends.*Repository\|extends.*CrudRepository\|extends.*JpaRepository" --include="*.java" . 2>/dev/null | head -15`

Hibernate/JPA configuration:
!`grep -E "spring.jpa|hibernate" src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null | head -15`

## Audit Checklist

### N+1 Query Detection

1. **`@OneToMany` / `@ManyToMany` without fetch strategy**: Default is `LAZY`, but accessing the collection in a loop after querying the parent causes N+1
2. **Repository methods returning entities with lazy collections**: If the collection is accessed outside the transaction (e.g., in the controller or serializer), it triggers N+1 or `LazyInitializationException`
3. **Missing `@EntityGraph`**: Repository queries that need related data but don't use `@EntityGraph` or `JOIN FETCH`
4. **`FetchType.EAGER` on collections**: Solves N+1 but creates cartesian product and overfetching — almost always wrong

**Solutions to recommend:**
- `@EntityGraph(attributePaths = {"relatedEntity"})` on repository methods
- JPQL with `JOIN FETCH`
- `@BatchSize(size = 20)` on lazy collections
- DTO projections for read-only use cases

### Missing Index Detection

1. **Columns used in WHERE clauses**: Check repository method names (Spring Data derives queries from method names) and `@Query` annotations for filtered columns
2. **Foreign key columns**: `@ManyToOne` / `@OneToOne` join columns should have indexes
3. **Unique constraints without index**: `@Column(unique = true)` creates an index, but composite uniqueness via `@Table(uniqueConstraints)` should be verified
4. **Columns used in ORDER BY**: Frequently sorted columns benefit from indexes

**How to declare:**
```java
@Table(indexes = {
    @Index(name = "idx_user_email", columnList = "email"),
    @Index(name = "idx_order_status_date", columnList = "status, createdAt")
})
```

### Lazy Loading Issues

1. **Entity returned directly from `@RestController`**: Jackson serialization triggers lazy loading outside transaction — use DTOs
2. **`toString()` accessing lazy collections**: Causes `LazyInitializationException` or unintended queries
3. **`equals()` / `hashCode()` using lazy fields**: Should use only `@Id` or business key
4. **`spring.jpa.open-in-view=true`** (default!): Keeps session open in view layer — hides lazy loading issues, causes performance problems

### Relationship Anti-Patterns

1. **Bidirectional `@ManyToMany`**: Should use a join entity for extra attributes or better control
2. **Missing `mappedBy`**: Bidirectional relationships without `mappedBy` create duplicate join tables
3. **Missing `orphanRemoval`**: `@OneToMany` without `orphanRemoval = true` leaves orphaned records
4. **`CascadeType.ALL` on `@ManyToOne`**: Cascading from child to parent is almost always wrong
5. **Missing `@JoinColumn`**: Relying on default join column names is fragile

### General Issues

1. **Missing `@Version` for optimistic locking**: Entities modified concurrently need `@Version`
2. **`GenerationType.IDENTITY`**: Prevents JDBC batch inserts — prefer `SEQUENCE` with `@SequenceGenerator`
3. **Large `@Lob` fields on main entity**: Should be in a separate entity to avoid loading on every query
4. **Missing auditing**: Consider `@CreatedDate`, `@LastModifiedDate` via `@EntityListeners(AuditingEntityListener.class)`

## Output Format

| Severity | Entity | Issue | Impact | Fix |
|----------|--------|-------|--------|-----|
| CRITICAL / WARNING / INFO | Entity:field | Description | Performance/correctness impact | Recommended fix |

For detailed anti-patterns and solutions, see [jpa-antipatterns.md](references/jpa-antipatterns.md).
