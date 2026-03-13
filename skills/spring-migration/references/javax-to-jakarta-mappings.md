# javax to jakarta Namespace Mappings

## Packages That Change

| javax Package | jakarta Package | Used In |
|---------------|-----------------|---------|
| `javax.persistence.*` | `jakarta.persistence.*` | JPA entities, repositories |
| `javax.persistence.criteria.*` | `jakarta.persistence.criteria.*` | Criteria API |
| `javax.servlet.*` | `jakarta.servlet.*` | Filters, listeners, HttpServletRequest |
| `javax.servlet.http.*` | `jakarta.servlet.http.*` | HttpServletRequest, HttpServletResponse |
| `javax.validation.*` | `jakarta.validation.*` | Bean Validation |
| `javax.validation.constraints.*` | `jakarta.validation.constraints.*` | @NotNull, @Size, @Email, etc. |
| `javax.annotation.*` | `jakarta.annotation.*` | @PostConstruct, @PreDestroy, @Resource |
| `javax.transaction.*` | `jakarta.transaction.*` | @Transactional (JTA) |
| `javax.inject.*` | `jakarta.inject.*` | @Inject, @Named |
| `javax.websocket.*` | `jakarta.websocket.*` | WebSocket endpoints |
| `javax.mail.*` | `jakarta.mail.*` | JavaMail |
| `javax.activation.*` | `jakarta.activation.*` | JavaBeans Activation Framework |
| `javax.xml.bind.*` | `jakarta.xml.bind.*` | JAXB |
| `javax.ws.rs.*` | `jakarta.ws.rs.*` | JAX-RS |
| `javax.el.*` | `jakarta.el.*` | Expression Language |
| `javax.faces.*` | `jakarta.faces.*` | JSF |

## Packages That DO NOT Change

These are part of the JDK itself, not Jakarta EE:

| Package | Reason |
|---------|--------|
| `javax.sql.*` | Part of JDK (JDBC) |
| `javax.crypto.*` | Part of JDK (JCE) |
| `javax.net.*` | Part of JDK |
| `javax.net.ssl.*` | Part of JDK |
| `javax.security.auth.*` | Part of JDK |
| `javax.naming.*` | Part of JDK (JNDI) |
| `javax.management.*` | Part of JDK (JMX) |
| `javax.swing.*` | Part of JDK |
| `javax.xml.parsers.*` | Part of JDK |
| `javax.xml.transform.*` | Part of JDK |

## Dependency Coordinate Changes

### Maven

| Old | New |
|-----|-----|
| `javax.persistence:javax.persistence-api` | `jakarta.persistence:jakarta.persistence-api` |
| `javax.validation:validation-api` | `jakarta.validation:jakarta.validation-api` |
| `javax.servlet:javax.servlet-api` | `jakarta.servlet:jakarta.servlet-api` |
| `javax.annotation:javax.annotation-api` | `jakarta.annotation:jakarta.annotation-api` |
| `javax.inject:javax.inject` | `jakarta.inject:jakarta.inject-api` |
| `javax.mail:javax.mail-api` | `jakarta.mail:jakarta.mail-api` |
| `javax.xml.bind:jaxb-api` | `jakarta.xml.bind:jakarta.xml.bind-api` |

### Spring Boot Managed

Spring Boot 3.x manages Jakarta dependencies automatically. Remove explicit versions of Jakarta APIs from your POM — let the Spring Boot BOM handle them:

```xml
<!-- Remove these explicit dependencies if present -->
<!-- Spring Boot 3 includes them transitively -->
<dependency>
    <groupId>jakarta.persistence</groupId>
    <artifactId>jakarta.persistence-api</artifactId>
    <!-- No version needed — managed by spring-boot-starter-parent -->
</dependency>
```

## Third-Party Library Compatibility

| Library | Jakarta-Compatible Version | Notes |
|---------|---------------------------|-------|
| Hibernate | 6.x+ | Bundled with Spring Boot 3 |
| Flyway | 9.x+ | Callback changes |
| Liquibase | 4.17+ | Fully compatible |
| Lombok | 1.18.30+ | `@Builder` works with records |
| MapStruct | 1.5.5+ | jakarta.annotation support |
| Querydsl | 5.0.0+ (jakarta classifier) | Use `jakarta` classifier |
| Springdoc OpenAPI | 2.x (springdoc-openapi-starter-webmvc-ui) | v1 does not support Spring Boot 3 |
| jjwt (io.jsonwebtoken) | 0.12.x+ | Namespace changes |
