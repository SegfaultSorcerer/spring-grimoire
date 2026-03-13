# Spring Boot Testing Patterns

## Test Slice Annotations

| Annotation | Purpose | What it loads |
|------------|---------|---------------|
| `@SpringBootTest` | Full integration test | Entire application context |
| `@WebMvcTest` | Controller tests | Web layer only (controllers, filters, advices) |
| `@DataJpaTest` | Repository tests | JPA layer only (entities, repositories, EntityManager) |
| `@WebFluxTest` | Reactive controller tests | WebFlux layer only |
| `@JsonTest` | JSON serialization tests | Jackson ObjectMapper |
| `@RestClientTest` | REST client tests | RestTemplate, WebClient |

## MockMvc Patterns (Controller Testing)

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    void getUser_existingId_returnsUser() throws Exception {
        // given
        var user = new UserDto(1L, "john@example.com", "John");
        when(userService.findById(1L)).thenReturn(user);

        // when & then
        mockMvc.perform(get("/api/users/{id}", 1L)
                .accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("john@example.com"))
            .andExpect(jsonPath("$.name").value("John"));
    }

    @Test
    void createUser_invalidEmail_returns400() throws Exception {
        // given
        var request = """
            {"email": "not-an-email", "name": "John"}
            """;

        // when & then
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(request))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errors[0].field").value("email"));
    }
}
```

## Mockito Patterns (Service Testing)

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private UserService userService;

    @Test
    void createUser_validInput_savesAndSendsEmail() {
        // given
        var request = new CreateUserRequest("john@example.com", "John");
        var savedUser = new User(1L, "john@example.com", "John");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        // when
        var result = userService.createUser(request);

        // then
        assertThat(result.id()).isEqualTo(1L);
        verify(emailService).sendWelcomeEmail("john@example.com");
        verify(userRepository).save(argThat(user ->
            user.getEmail().equals("john@example.com")));
    }

    @Test
    void findById_nonExistingId_throwsNotFoundException() {
        // given
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        // when & then
        assertThatThrownBy(() -> userService.findById(99L))
            .isInstanceOf(UserNotFoundException.class)
            .hasMessageContaining("99");
    }
}
```

## DataJpaTest Patterns (Repository Testing)

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class UserRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    void findByEmail_existingEmail_returnsUser() {
        // given
        var user = new User(null, "john@example.com", "John");
        entityManager.persistAndFlush(user);

        // when
        var result = userRepository.findByEmail("john@example.com");

        // then
        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("John");
    }
}
```

## Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "valid@email.com, true",
    "invalid-email, false",
    "'', false",
    "a@b.c, true"
})
void isValidEmail_variousInputs_returnsExpected(String email, boolean expected) {
    assertThat(validator.isValid(email)).isEqualTo(expected);
}

@ParameterizedTest
@MethodSource("invalidUserRequests")
void createUser_invalidRequest_throwsValidationException(CreateUserRequest request, String expectedField) {
    assertThatThrownBy(() -> userService.createUser(request))
        .isInstanceOf(ValidationException.class);
}

static Stream<Arguments> invalidUserRequests() {
    return Stream.of(
        Arguments.of(new CreateUserRequest(null, "John"), "email"),
        Arguments.of(new CreateUserRequest("a@b.c", null), "name"),
        Arguments.of(new CreateUserRequest("a@b.c", ""), "name")
    );
}
```

## Test Fixtures

### Builder Pattern
```java
class TestUserBuilder {
    private Long id = 1L;
    private String email = "default@example.com";
    private String name = "Default User";

    static TestUserBuilder aUser() { return new TestUserBuilder(); }

    TestUserBuilder withEmail(String email) { this.email = email; return this; }
    TestUserBuilder withName(String name) { this.name = name; return this; }
    TestUserBuilder withId(Long id) { this.id = id; return this; }

    User build() { return new User(id, email, name); }
    UserDto buildDto() { return new UserDto(id, email, name); }
}
```

## AssertJ Custom Assertions

```java
// Prefer AssertJ over JUnit assertions
assertThat(user.getEmail()).isEqualTo("john@example.com");      // not assertEquals
assertThat(users).hasSize(3);                                     // not assertEquals(3, users.size())
assertThat(users).extracting("email").contains("john@example.com");
assertThat(result).isPresent().get().extracting("name").isEqualTo("John");
assertThatThrownBy(() -> service.delete(id)).isInstanceOf(NotFoundException.class);
```
