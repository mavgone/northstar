package dev.northstar.notes.auth;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import dev.northstar.notes.auth.dto.SignInRequest;
import dev.northstar.notes.auth.dto.SignUpRequest;
import dev.northstar.notes.shared.config.JwtProperties;
import dev.northstar.notes.shared.security.JwtService;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;
@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService")
class AuthServiceTest {
  @Mock private UserRepository users;
  @Mock private PasswordEncoder passwordEncoder;
  @Mock private AuthenticationManager authenticationManager;
  private AuthService authService;
  @BeforeEach
  void setUp() {
    var props = new JwtProperties();
    props.setSecret("test-secret-min-32-chars-for-unit-tests-123456");
    props.setIssuer("northstar-notes-test");
    authService =
        new AuthService(users, passwordEncoder, new JwtService(props), authenticationManager);
  }
  @Nested
  @DisplayName("signUp")
  class SignUp {
    @Test
    @DisplayName("Should create user and return token pair")
    void shouldCreateUser() {
      when(users.existsByEmail("demo@obsidian.dev")).thenReturn(false);
      when(passwordEncoder.encode("demo1234")).thenReturn("hashed");
      when(users.saveAndFlush(any(UserEntity.class)))
          .thenAnswer(
              inv -> {
                UserEntity u = inv.getArgument(0);
                u.setId(UUID.randomUUID());
                return u;
              });
      var res = authService.signUp(new SignUpRequest("Demo", "demo@obsidian.dev", "demo1234"));
      assertThat(res.accessToken()).isNotBlank();
      assertThat(res.refreshToken()).isNotBlank();
      assertThat(res.user().email()).isEqualTo("demo@obsidian.dev");
    }
    @Test
    @DisplayName("Should reject duplicate email")
    void shouldRejectDuplicate() {
      when(users.existsByEmail("demo@obsidian.dev")).thenReturn(true);
      assertThatThrownBy(
              () -> authService.signUp(new SignUpRequest("Demo", "demo@obsidian.dev", "demo1234")))
          .isInstanceOf(IllegalArgumentException.class)
          .hasMessageContaining("already exists");
    }
  }
  @Nested
  @DisplayName("signIn")
  class SignIn {
    @Test
    @DisplayName("Should return tokens for known user")
    void shouldSignIn() {
      var user = new UserEntity("demo@obsidian.dev", "hashed", "Demo");
      user.setId(UUID.randomUUID());
      when(users.findByEmail("demo@obsidian.dev")).thenReturn(Optional.of(user));
      var res = authService.signIn(new SignInRequest("demo@obsidian.dev", "demo1234"));
      assertThat(res.user().name()).isEqualTo("Demo");
      assertThat(res.accessToken()).isNotBlank();
    }
  }
}
