package dev.northstar.notes.auth;
import dev.northstar.notes.auth.dto.AuthResponse;
import dev.northstar.notes.auth.dto.RefreshRequest;
import dev.northstar.notes.auth.dto.SignInRequest;
import dev.northstar.notes.auth.dto.SignUpRequest;
import dev.northstar.notes.auth.dto.UpdateProfileRequest;
import dev.northstar.notes.auth.dto.UserDto;
import dev.northstar.notes.shared.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
  private final UserRepository users;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;
  private final AuthenticationManager authenticationManager;
  @Transactional
  public AuthResponse signUp(SignUpRequest req) {
    String email = req.email().trim().toLowerCase();
    if (users.existsByEmail(email)) {
      throw new IllegalArgumentException("An account with this email already exists.");
    }
    var user =
        new UserEntity(email, passwordEncoder.encode(req.password()), req.name().trim());
    try {
      users.saveAndFlush(user);
    } catch (DataIntegrityViolationException e) {
      throw new IllegalArgumentException("An account with this email already exists.");
    }
    log.info("User registered: {}", user.getId());
    return tokens(user);
  }
  @Transactional(readOnly = true)
  public AuthResponse signIn(SignInRequest req) {
    String email = req.email().trim().toLowerCase();
    authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(email, req.password()));
    var user =
        users
            .findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("No account found for this email."));
    log.info("User signed in: {}", user.getId());
    return tokens(user);
  }
  @Transactional(readOnly = true)
  public AuthResponse refresh(RefreshRequest req) {
    String email = jwtService.extractUsername(req.refreshToken());
    var user =
        users
            .findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("No account found for this email."));
    if (!jwtService.isRefreshValid(req.refreshToken(), user)) {
      throw new IllegalArgumentException("Invalid refresh token.");
    }
    return tokens(user);
  }
  @Transactional
  public UserDto updateProfile(UserEntity current, UpdateProfileRequest req) {
    current.setName(req.name().trim());
    users.save(current);
    return toDto(current);
  }
  public UserDto toDto(UserEntity user) {
    return new UserDto(user.getId(), user.getName(), user.getEmail(), user.getCreatedAt());
  }
  private AuthResponse tokens(UserEntity user) {
    return new AuthResponse(
        jwtService.generateAccessToken(user),
        jwtService.generateRefreshToken(user),
        toDto(user));
  }
}
