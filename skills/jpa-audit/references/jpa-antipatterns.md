# JPA Anti-Patterns and Solutions

## N+1 Query Problem

### The Problem
```java
// This generates 1 query for orders + N queries for order items
List<Order> orders = orderRepository.findAll();
for (Order order : orders) {
    order.getItems().size(); // triggers lazy load for EACH order
}
```

### Solution 1: JOIN FETCH
```java
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.status = :status")
List<Order> findByStatusWithItems(@Param("status") OrderStatus status);
```

### Solution 2: @EntityGraph
```java
@EntityGraph(attributePaths = {"items", "items.product"})
List<Order> findByStatus(OrderStatus status);
```

### Solution 3: @BatchSize
```java
@Entity
public class Order {
    @OneToMany(mappedBy = "order")
    @BatchSize(size = 20) // loads items in batches of 20 instead of 1-by-1
    private List<OrderItem> items;
}
```

### Solution 4: DTO Projection (best for read-only)
```java
public interface OrderSummary {
    Long getId();
    String getStatus();
    int getItemCount(); // backed by @Query with COUNT
}

@Query("SELECT o.id as id, o.status as status, SIZE(o.items) as itemCount FROM Order o")
List<OrderSummary> findOrderSummaries();
```

## Missing Indexes

### Identifying Missing Indexes
Check every column that appears in:
- Repository method name derivations: `findByEmail` → `email` needs an index
- `@Query` WHERE clauses
- `@Query` ORDER BY clauses
- `@ManyToOne` join columns (foreign keys)

### Declaring Indexes
```java
@Entity
@Table(
    name = "orders",
    indexes = {
        @Index(name = "idx_order_status", columnList = "status"),
        @Index(name = "idx_order_customer_date", columnList = "customer_id, created_at"),
        @Index(name = "idx_order_tracking", columnList = "tracking_number", unique = true)
    }
)
public class Order { ... }
```

## Lazy Loading Pitfalls

### Anti-Pattern: Entity as API Response
```java
// BAD — Jackson triggers lazy loading during serialization
@GetMapping("/orders/{id}")
public Order getOrder(@PathVariable Long id) {
    return orderRepository.findById(id).orElseThrow();
}
```

```java
// GOOD — use DTO
@GetMapping("/orders/{id}")
public OrderDto getOrder(@PathVariable Long id) {
    Order order = orderRepository.findById(id).orElseThrow();
    return OrderDto.from(order);
}
```

### Anti-Pattern: toString() with Lazy Collections
```java
// BAD — triggers lazy load or LazyInitializationException
@Override
public String toString() {
    return "Order{items=" + items + "}"; // items is @OneToMany LAZY
}
```

### Anti-Pattern: equals/hashCode with Entity Fields
```java
// BAD — relies on DB-generated ID (null before persist) and lazy fields
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Order)) return false;
    return id != null && id.equals(((Order) o).id);
}

// GOOD — use business key or UUID
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Order order)) return false;
    return Objects.equals(orderNumber, order.orderNumber); // natural business key
}

@Override
public int hashCode() {
    return Objects.hash(orderNumber);
}
```

## Relationship Mistakes

### Missing mappedBy
```java
// BAD — creates TWO join tables
@Entity class Author {
    @ManyToMany
    private Set<Book> books;
}
@Entity class Book {
    @ManyToMany
    private Set<Author> authors;
}

// GOOD — single join table
@Entity class Author {
    @ManyToMany
    @JoinTable(name = "author_book")
    private Set<Book> books;
}
@Entity class Book {
    @ManyToMany(mappedBy = "books")
    private Set<Author> authors;
}
```

### CascadeType.ALL on @ManyToOne
```java
// BAD — deleting an OrderItem cascades to Order (deletes the parent!)
@Entity class OrderItem {
    @ManyToOne(cascade = CascadeType.ALL)
    private Order order;
}

// GOOD — no cascade from child to parent
@Entity class OrderItem {
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;
}
```

## Sequence Generation

### Anti-Pattern: IDENTITY Strategy
```java
// BAD — disables JDBC batch inserts
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;

// GOOD — allows batching
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "order_seq")
@SequenceGenerator(name = "order_seq", sequenceName = "order_seq", allocationSize = 50)
private Long id;
```

## Open Session in View

```properties
# Default is TRUE — change to FALSE in production
spring.jpa.open-in-view=false
```

When `true`: Hibernate session stays open through the entire HTTP request, including view rendering. This hides lazy loading issues during development but causes:
- Unpredictable query execution in the view layer
- Connection held longer than necessary
- Hard-to-debug performance issues in production

## Bulk Operations

### Anti-Pattern: Loading Entities for Mass Update
```java
// BAD — loads all entities into memory
List<Order> orders = orderRepository.findByStatus(PENDING);
orders.forEach(o -> o.setStatus(CANCELLED));
orderRepository.saveAll(orders); // N update queries

// GOOD — single UPDATE query
@Modifying
@Query("UPDATE Order o SET o.status = :newStatus WHERE o.status = :oldStatus")
int updateStatus(@Param("oldStatus") OrderStatus oldStatus, @Param("newStatus") OrderStatus newStatus);
```
