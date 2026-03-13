---
name: test-gen
description: Generate JUnit 5 tests with Mockito and Testcontainers for a given Java class. Detects class type (Controller, Service, Repository) and applies the appropriate testing strategy.
argument-hint: "[class-file-path]"
---

# Generate Tests

Generate comprehensive JUnit 5 tests for the specified class: `$ARGUMENTS`

## Source Class

!`cat $ARGUMENTS 2>/dev/null`

## Available Test Dependencies

!`grep -E "junit|mockito|testcontainers|assertj|spring-boot-starter-test" pom.xml 2>/dev/null | head -10`
!`grep -E "junit|mockito|testcontainers|assertj|spring-boot-starter-test" build.gradle 2>/dev/null | head -10`

## Existing Test Patterns

!`find . -path "*/test/java" -name "*Test.java" | head -5 | xargs head -30 2>/dev/null`

## Strategy

Detect the class type and apply the appropriate testing approach:

### Controller (`@RestController`, `@Controller`)
- Use `@WebMvcTest(ControllerUnderTest.class)`
- Inject `MockMvc` via `@Autowired`
- Mock dependencies with `@MockBean`
- Test each endpoint: request mapping, input validation, response status, response body
- Test error scenarios (400, 404, 500)

### Service (`@Service`, `@Component`)
- Use `@ExtendWith(MockitoExtension.class)`
- Mock dependencies with `@Mock`, inject with `@InjectMocks`
- Test each public method: happy path, edge cases, error/exception scenarios
- Verify interactions with `verify()`

### Repository (`@Repository`, extends `JpaRepository`)
- Use `@DataJpaTest` with `@AutoConfigureTestDatabase`
- For complex queries: use Testcontainers with `@Testcontainers` and `@Container`
- Test custom query methods, not inherited CRUD methods
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

## Rules

- Use AssertJ assertions (`assertThat`) over JUnit assertions
- Follow naming convention: `methodName_stateUnderTest_expectedBehavior`
- Use `@Nested` classes to group tests by method
- Use `@DisplayName` for readable test output
- Use `@ParameterizedTest` with `@CsvSource` or `@MethodSource` for multiple input cases
- Never test private methods directly
- Mock external dependencies, not the class under test
- Place the test file in the mirror package under `src/test/java`

For detailed testing patterns, see [testing-patterns.md](references/testing-patterns.md).
