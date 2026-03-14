---
name: spring-jpa-audit
description: Audit JPA entities and repositories for N+1 queries, missing indexes, lazy loading traps, relationship anti-patterns, and fetch strategy mistakes. Use this skill whenever the user wants to audit, review, or optimize their JPA entities, repositories, or database performance — even if they just say "meine Queries sind langsam", "warum dauert das so lange", "check my entities", or "ist das performant?".
argument-hint: "[entity-or-directory]"
allowed-tools: Bash(*)
---

# JPA Entity Audit

Audit JPA entities and repositories for performance problems and anti-patterns. Read [jpa-antipatterns.md](references/jpa-antipatterns.md) for code examples (N+1 solutions, index declarations, lazy loading pitfalls, bulk operations) before starting your audit — the reference contains BAD/GOOD comparisons you should use in recommendations.

## Scope

If a specific file or directory is provided: `$ARGUMENTS`
Otherwise, audit all entities in the project.

## Project Context

Entity classes:
!`grep -rln "@Entity" --include="*.java" --include="*.kt" . 2>/dev/null | head -20`

Relationship annotations:
!`grep -rn "@OneToMany\|@ManyToOne\|@ManyToMany\|@OneToOne\|@ElementCollection" --include="*.java" --include="*.kt" . 2>/dev/null | head -30`

Repository interfaces:
!`grep -rln "extends.*Repository\|extends.*CrudRepository\|extends.*JpaRepository" --include="*.java" --include="*.kt" . 2>/dev/null | head -15`

Hibernate/JPA configuration:
!`grep -rE "spring.jpa|hibernate|open-in-view" src/main/resources/application*.properties src/main/resources/application*.yml 2>/dev/null | head -15`

## Audit Checklist

### 1. N+1 Query Detection (audit first — this is the #1 JPA performance killer)

The N+1 problem means 1 query to load N parents, then N additional queries to load each parent's children. With 1000 orders, that is 1001 queries instead of 1-2. This turns millisecond operations into multi-second ones.

1. **Lazy collections accessed in loops**: `@OneToMany` / `@ManyToMany` default to `LAZY`, but iterating over parents and touching their children triggers a separate query per parent
2. **`FetchType.EAGER` on collections**: Appears to solve N+1 but creates cartesian products — if a User has 10 orders and 5 roles, Hibernate loads 50 rows. Almost always wrong on collections
3. **`@ManyToOne` defaults to `EAGER`**: Unlike collections, `@ManyToOne` and `@OneToOne` default to `FetchType.EAGER`. This is a common surprise — loading 100 OrderItems eagerly loads 100 Products even when not needed
4. **Repository methods returning entities with lazy collections**: If the collection is accessed outside the transaction (e.g., in the controller or during Jackson serialization), it triggers N+1 or `LazyInitializationException`
5. **Missing `@EntityGraph` or `JOIN FETCH`**: Repository queries that need related data but don't declare how to fetch it

**Solutions to recommend (from best to acceptable):**
- DTO projections for read-only use cases (eliminates the problem entirely)
- `@EntityGraph(attributePaths = {"relatedEntity"})` on repository methods
- JPQL with `JOIN FETCH`
- `@BatchSize(size = 20)` on lazy collections (reduces N+1 to N/20+1)

### 2. Missing Index Detection

Every unindexed column in a WHERE or ORDER BY clause causes a full table scan. With 100k rows, that is the difference between <1ms and 500ms+ per query.

1. **Columns in derived query methods**: `findByEmail` → `email` needs an index, `findByStatusAndCreatedAtBetween` → composite index on `(status, created_at)`
2. **Columns in `@Query` WHERE/ORDER BY clauses**: Parse the JPQL/SQL and check each filtered/sorted column
3. **Foreign key columns**: `@ManyToOne` / `@OneToOne` join columns should have indexes — the database does not always create them automatically
4. **Unique constraints**: `@Column(unique = true)` creates an index, but composite uniqueness via `@Table(uniqueConstraints)` should be verified

### 3. Lazy Loading Traps

1. **Entity returned directly from `@RestController`**: Jackson serialization triggers lazy loading outside the transaction — results in either N+1 queries (with `open-in-view=true`) or `LazyInitializationException` (with `open-in-view=false`). Use DTOs
2. **`spring.jpa.open-in-view=true`** (the default!): Keeps the Hibernate session open through the entire HTTP request including view rendering. This hides lazy loading bugs in development but causes unpredictable query execution and long-held database connections in production
3. **`toString()` accessing lazy collections**: Causes `LazyInitializationException` or unintended queries — especially dangerous in logging statements
4. **`equals()` / `hashCode()` using lazy fields or generated IDs**: Should use a business key or `@NaturalId`. Using `@Id` is fragile because it is `null` before `persist()`

### 4. Relationship Anti-Patterns

1. **`CascadeType.ALL` on `@ManyToOne`**: Cascading from child to parent is almost always wrong — deleting an OrderItem would cascade-delete the entire Order
2. **Missing `mappedBy`**: Bidirectional relationships without `mappedBy` create two separate join tables instead of one
3. **Missing `orphanRemoval`**: `@OneToMany` without `orphanRemoval = true` leaves orphaned child records when removed from the collection
4. **Bidirectional `@ManyToMany` without join entity**: Should use a join entity when extra attributes are needed (e.g., `UserRole` with `assignedAt`) or for better lifecycle control
5. **Missing `@JoinColumn`**: Relying on Hibernate's default join column naming is fragile and produces ugly names like `user_roles_id`

### 5. ID Generation & Batching

1. **`GenerationType.IDENTITY`**: Prevents JDBC batch inserts entirely because Hibernate must execute an INSERT immediately to get the generated ID. Use `SEQUENCE` with `@SequenceGenerator(allocationSize = 50)` for batching
2. **No batch size configured**: Without `spring.jpa.properties.hibernate.jdbc.batch_size`, Hibernate sends one INSERT/UPDATE per entity even with SEQUENCE strategy
3. **Bulk updates loading entities**: Using `findAll()` + `forEach(set...)` + `saveAll()` for mass updates generates N SELECT + N UPDATE queries. Use `@Modifying @Query("UPDATE ...")` for single-query bulk operations

### 6. General Issues

1. **Missing `@Version` for optimistic locking**: Entities modified concurrently need `@Version` to prevent lost updates — without it, the last write silently wins
2. **Large `@Lob` fields on main entity**: BLOBs/CLOBs should be in a separate entity to avoid loading them on every query
3. **Missing auditing**: Entities that track changes should use `@CreatedDate`, `@LastModifiedDate` via `@EntityListeners(AuditingEntityListener.class)`
4. **`List` instead of `Set` for `@ManyToMany`**: Using `List` with `@ManyToMany` causes Hibernate to delete all join table entries and re-insert them on every modification. Use `Set` instead

## Output Format

| Severity | Entity | Issue | Impact | Fix |
|----------|--------|-------|--------|-----|
| CRITICAL | Entity:field | Description | Quantified performance/correctness impact | Recommended fix with code example |
| WARNING | Entity:field | Description | Impact description | Recommended fix |
| INFO | Entity:field | Description | Impact description | Recommended fix |

**Severity guide:**
- **CRITICAL**: N+1 queries on hot paths, `CascadeType.ALL` on `@ManyToOne`, missing indexes on high-traffic queries — these cause production incidents
- **WARNING**: `FetchType.EAGER` on collections, `open-in-view=true`, `GenerationType.IDENTITY` with batch requirements, missing `mappedBy` — these degrade performance or cause data issues at scale
- **INFO**: Missing auditing, `@NaturalId` recommendations, `List` vs `Set` on `@ManyToMany` — improvements that make the code more robust

End with a summary: total findings by severity and the **top 3 things to fix first**, prioritized by production impact.

For detailed anti-patterns and solutions, see [jpa-antipatterns.md](references/jpa-antipatterns.md).
