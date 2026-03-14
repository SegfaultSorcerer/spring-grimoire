---
name: spring-test-gen
description: >
  Generate JUnit 5 tests for a Java or Kotlin class. Detects class type
  (Controller, Service, Repository, Configuration) and applies the right testing
  strategy: @WebMvcTest + MockMvc for controllers, Mockito for services,
  @DataJpaTest + Testcontainers for repositories.
  Use this skill whenever the user wants to write tests, generate test cases,
  cover a class with tests, add unit tests, or create integration tests for any
  Spring Boot or plain Java/Kotlin class.
argument-hint: "<class-file-path>"
allowed-tools: Bash(*)
---

# Generate Tests

Generate comprehensive JUnit 5 tests for the specified class: `$ARGUMENTS`

## Source Class

!`cat $ARGUMENTS 2>/dev/null`

## Available Test Dependencies

!`grep -E "junit|mockito|testcontainers|assertj|spring-boot-starter-test" pom.xml 2>/dev/null | head -10`
!`grep -E "junit|mockito|testcontainers|assertj|spring-boot-starter-test" build.gradle build.gradle.kts 2>/dev/null | head -10`

## Existing Test Patterns

!`ls src/test/java -R 2>/dev/null | grep "Test\.\(java\|kt\)$" | head -5`

## Strategy

Detect the class type from annotations and apply the appropriate testing approach:

### Controller (`@RestController`, `@Controller`)
- Use `@WebMvcTest(ControllerUnderTest.class)` — loads only the web layer, not the full context
- Inject `MockMvc` via `@Autowired`
- Mock dependencies with `@MockBean`
- Test each endpoint: request mapping, input validation, response status, response body
- Test error scenarios (400, 404, 500)
- If endpoints are secured, use `@WithMockUser` / `@WithMockUser(roles = "ADMIN")` to test authorization. Include at least one test verifying that unauthenticated requests return 401/403.

### Service (`@Service`, `@Component`)
- Use `@ExtendWith(MockitoExtension.class)` — no Spring context needed
- Mock dependencies with `@Mock`, inject with `@InjectMocks`
- Test each public method: happy path, edge cases, error/exception scenarios
- For void methods: use `verify()` to assert interactions, `doThrow()` to test error paths
- For methods with `@Transactional`: test is about business logic, not transaction boundaries (those are integration tests)

### Repository (`@Repository`, extends `JpaRepository`)
- Use `@DataJpaTest` with `@AutoConfigureTestDatabase` — automatically transactional, rolls back after each test
- For complex queries: use Testcontainers with `@Testcontainers` and `@Container`
- Only test custom query methods (`@Query`, derived queries), not inherited CRUD methods from `JpaRepository` — those are already tested by Spring Data
- Verify pagination and sorting if applicable

### Configuration (`@Configuration`)
- Use `@SpringBootTest` with specific properties
- Verify bean creation and wiring
- Test conditional configuration (`@ConditionalOnProperty`, etc.)

## Test Structure

```java
@DisplayName("ClassName Tests")
class ClassNameTest {

    @Nested
    @DisplayName("methodName")
    class MethodName {

        @Test
        @DisplayName("should [expected behavior] when [state]")
        void methodName_stateUnderTest_expectedBehavior() {
            // given

            // when

            // then
        }
    }
}
```

## What NOT to Test

- Getters, setters, constructors — trivial code with no logic
- Framework behavior — don't test that `@Autowired` works or that `JpaRepository.save()` persists
- Private methods — test them through the public API that calls them
- Third-party libraries — trust their own test suites

## Rules

- Use AssertJ assertions (`assertThat`) over JUnit assertions — they provide better error messages and fluent API
- Follow naming convention: `methodName_stateUnderTest_expectedBehavior`
- Use `@Nested` classes to group tests by method
- Use `@DisplayName` for readable test output
- Use `@ParameterizedTest` with `@CsvSource` or `@MethodSource` when testing multiple inputs with the same logic
- Never test private methods directly
- Mock external dependencies, not the class under test
- Place the test file in the mirror package under `src/test/java`
- Include edge cases: null inputs, empty collections, boundary values (0, MAX_VALUE, empty strings)
- For Kotlin classes: use the same JUnit 5 + Mockito approach but with `mockk` if MockK is in the dependencies

For detailed testing patterns and code examples, see [testing-patterns.md](references/testing-patterns.md).
