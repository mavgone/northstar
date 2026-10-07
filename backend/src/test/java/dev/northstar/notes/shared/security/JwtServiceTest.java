package dev.northstar.notes.shared.security;

import static org.assertj.core.api.Assertions.assertThat;

import dev.northstar.notes.shared.config.JwtProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

@DisplayName("JwtService")
class JwtServiceTest {

  private JwtService jwtService;
  private UserDetails user;

  @BeforeEach
  void setUp() {
    var props = new JwtProperties();
    props.setSecret("test-secret-min-32-chars-for-unit-tests-123456");
    props.setIssuer("northstar-notes-test");
    props.setAccessTokenExpiration(900000);
    props.setRefreshTokenExpiration(604800000);
    jwtService = new JwtService(props);
    user = User.builder().username("demo@obsidian.dev").password("hashed").authorities("ROLE_USER").build();
  }

  @Test
  @DisplayName("access token validates as access, not as refresh")
  void accessTypeEnforced() {
    String access = jwtService.generateAccessToken(user);
    assertThat(jwtService.isTokenValid(access, user)).isTrue();
    assertThat(jwtService.isRefreshValid(access, user)).isFalse();
  }

  @Test
  @DisplayName("refresh token validates as refresh, not as access")
  void refreshTypeEnforced() {
    String refresh = jwtService.generateRefreshToken(user);
    assertThat(jwtService.isRefreshValid(refresh, user)).isTrue();
    assertThat(jwtService.isTokenValid(refresh, user)).isFalse();
  }

  @Test
  @DisplayName("tampered token rejected everywhere")
  void tamperedRejected() {
    String access = jwtService.generateAccessToken(user);
    String tampered = access.substring(0, access.length() - 2) + "ab";
    assertThat(jwtService.isTokenValid(tampered, user)).isFalse();
    assertThat(jwtService.isRefreshValid(tampered, user)).isFalse();
    assertThat(jwtService.extractUsername(access)).isEqualTo("demo@obsidian.dev");
  }
}
