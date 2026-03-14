---
name: dockerfile
description: >
  Generate an optimized, production-ready Dockerfile for a Spring Boot application.
  Multi-stage build with dependency layer caching, JVM container flags, non-root user,
  health checks, .dockerignore, and docker-compose.yml snippet.
  Use this skill whenever the user wants to containerize, dockerize, or deploy a Spring Boot app,
  or asks about Docker, containers, Kubernetes, or cloud deployment for a Java/Spring project.
  Also use when improving or reviewing an existing Dockerfile in a Spring Boot project.
argument-hint: "[--native] [--compose] [--distroless]"
allowed-tools: Bash(*)
---

# Generate Spring Boot Dockerfile

Generate an optimized, production-ready Dockerfile for this Spring Boot application.

## Project Context

Build tool and Java version:
!`head -30 pom.xml 2>/dev/null`
!`head -20 build.gradle 2>/dev/null || head -20 build.gradle.kts 2>/dev/null`

Application main class:
!`grep -rn "@SpringBootApplication" --include="*.java" --include="*.kt" . 2>/dev/null | head -3`

Existing Dockerfile:
!`cat Dockerfile 2>/dev/null || echo "No Dockerfile found"`

Existing .dockerignore:
!`cat .dockerignore 2>/dev/null || echo "No .dockerignore found"`

Actuator dependency (for health check):
!`grep -i "actuator" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -3`

Spring Boot version (for layered JAR support):
!`grep -E "spring-boot|springBootVersion" pom.xml build.gradle build.gradle.kts 2>/dev/null | head -3`

## Existing Dockerfile Analysis

If a Dockerfile already exists, analyze it first and report issues before generating a replacement. Common problems:
- Fat JAR copy without layer extraction (no dependency caching between builds)
- Running as root (no `USER` directive)
- Using JDK instead of JRE for runtime
- Missing `EXPOSE`, missing health check
- Shell form `ENTRYPOINT` instead of exec form (breaks signal handling)
- Secrets baked into image layers via `COPY` or `ENV`

## Dockerfile Requirements

### Multi-Stage Build

**Stage 1: Build**
- Use official Maven or Gradle image matching the project's Java version
- Copy dependency descriptor first (`pom.xml` / `build.gradle` / `build.gradle.kts`) for layer caching
- Download dependencies in a separate layer (`mvn dependency:go-offline` or `gradle dependencies`)
- Copy source code and build the application
- Extract Spring Boot layered JAR using `java -Djarmode=tools extract --layers --launcher` (Spring Boot 3.2+) or `java -Djarmode=layertools extract` (Spring Boot 2.3–3.1)

**Stage 2: Runtime**
- Use `eclipse-temurin:<version>-jre-alpine` as default base image (smallest, production-proven)
- If user passes `--distroless`, use `gcr.io/distroless/java<version>-debian12` instead (no shell, maximum security, but harder to debug)
- Copy layered JAR contents in dependency order: dependencies → spring-boot-loader → snapshot-dependencies → application. This ordering matters because Docker caches layers top-down — dependencies change rarely, application code changes often.
- Add OCI labels and `EXPOSE` instruction

### JVM Configuration

Container-aware JVM flags. Note: `-XX:+UseContainerSupport` is default since JDK 10 and does not need to be set explicitly for Java 17+.

```dockerfile
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+UseG1GC \
               -Djava.security.egd=file:/dev/./urandom"
```

### ENTRYPOINT — Exec Form and Signal Handling

Always use **exec form** for ENTRYPOINT so the JVM runs as PID 1 and receives SIGTERM directly for graceful shutdown. Shell form (`ENTRYPOINT java ...`) wraps the JVM in `/bin/sh` which swallows signals, causing hard kills after the timeout.

```dockerfile
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-XX:+UseG1GC", "org.springframework.boot.loader.launch.JarLauncher"]
```

If `JAVA_OPTS` flexibility is needed, use a shell script entrypoint with `exec`:
```dockerfile
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```
```bash
#!/bin/sh
exec java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher "$@"
```

### Security

- Create non-root user: `RUN addgroup --system app && adduser --system --ingroup app app`
- `USER app` before `ENTRYPOINT`
- No secrets in image layers — use runtime environment variables or mounted secrets
- Use `.dockerignore` to exclude `.git`, `target/`, `build/`, `.env`, IDE files

### Labels

Add OCI-standard labels for image metadata:
```dockerfile
LABEL org.opencontainers.image.title="app-name" \
      org.opencontainers.image.description="Spring Boot application" \
      org.opencontainers.image.source="https://github.com/org/repo"
```

### EXPOSE

Always declare the application port:
```dockerfile
EXPOSE 8080
```

### Health Check

If Spring Boot Actuator is present, add a health check. Alpine images don't include `wget` or `curl` by default — install `curl` in the runtime stage:

```dockerfile
RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
```

For distroless images (no shell), omit `HEALTHCHECK` from the Dockerfile and use the orchestrator's health check (Kubernetes `livenessProbe`, Docker Compose `healthcheck`).

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
*.env
docker-compose*.yml
Dockerfile
```

### docker-compose.yml snippet

Provide a `docker-compose.yml` snippet for local development. Use Compose v3+ syntax — `mem_limit` is deprecated, use `deploy.resources.limits.memory` instead:

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - JAVA_OPTS=-XX:MaxRAMPercentage=75.0
    deploy:
      resources:
        limits:
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      start-period: 40s
      retries: 3
```

## Output

Generate these files:
1. `Dockerfile` — optimized multi-stage build with comments explaining each significant line
2. `.dockerignore` — exclude unnecessary files from build context
3. `docker-compose.yml` — local development snippet (always include unless user opts out)

If an existing Dockerfile was found, start by listing the issues found and what the new version improves.
