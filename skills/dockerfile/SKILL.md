---
name: dockerfile
description: Generate an optimized multi-stage Dockerfile for a Spring Boot application with layer caching, JVM container flags, non-root user, and health checks.
allowed-tools: Bash(*)
---

# Generate Spring Boot Dockerfile

Generate an optimized, production-ready Dockerfile for this Spring Boot application.

## Project Context

Build tool and Java version:
!`head -30 pom.xml 2>/dev/null`
!`head -20 build.gradle 2>/dev/null || head -20 build.gradle.kts 2>/dev/null`

Application main class:
!`grep -rn "@SpringBootApplication" --include="*.java" . 2>/dev/null | head -3`

Existing Dockerfile:
!`cat Dockerfile 2>/dev/null || echo "No Dockerfile found"`

Existing .dockerignore:
!`cat .dockerignore 2>/dev/null || echo "No .dockerignore found"`

Actuator dependency (for health check):
!`grep "actuator" pom.xml build.gradle 2>/dev/null | head -3`

## Dockerfile Requirements

### Multi-Stage Build

**Stage 1: Build**
- Use official Maven or Gradle image matching the project's Java version
- Copy dependency descriptor first (`pom.xml` / `build.gradle`) for layer caching
- Download dependencies in a separate layer (`mvn dependency:go-offline` or `gradle dependencies`)
- Copy source code and build the application
- Extract Spring Boot layered JAR if supported

**Stage 2: Runtime**
- Use `eclipse-temurin:<version>-jre-alpine` or `eclipse-temurin:<version>-jre-noble` as base
- Use distroless (`gcr.io/distroless/java<version>-debian12`) for maximum security if appropriate
- Copy layered JAR contents in dependency order (dependencies, spring-boot-loader, snapshot-dependencies, application)
- Set JVM container-aware flags

### JVM Configuration

```dockerfile
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+UseG1GC \
               -XX:+UseContainerSupport \
               -Djava.security.egd=file:/dev/./urandom"
```

### Security

- Create non-root user: `RUN addgroup --system app && adduser --system --ingroup app app`
- `USER app` before `ENTRYPOINT`
- No secrets in image layers
- Use `.dockerignore` to exclude `.git`, `target/`, `build/`, `.env`, IDE files

### Health Check

If Spring Boot Actuator is present:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
```

### .dockerignore

Also generate a `.dockerignore` file:
```
.git
.gitignore
.idea
*.iml
.vscode
target/
build/
!build.gradle
!build.gradle.kts
.env
*.md
docker-compose*.yml
Dockerfile
```

### docker-compose.yml snippet

Provide a `docker-compose.yml` snippet for local development:
```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
    mem_limit: 512m
```

## Output

Generate these files:
1. `Dockerfile` — optimized multi-stage build
2. `.dockerignore` — exclude unnecessary files
3. Optionally: `docker-compose.yml` snippet for local development

Add comments explaining each significant line in the Dockerfile.
