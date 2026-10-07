package dev.northstar.notes.auth;
import dev.northstar.notes.auth.dto.AuthResponse;
import dev.northstar.notes.auth.dto.RefreshRequest;
import dev.northstar.notes.auth.dto.SignInRequest;
import dev.northstar.notes.auth.dto.SignUpRequest;
import dev.northstar.notes.auth.dto.UpdateProfileRequest;
import dev.northstar.notes.auth.dto.UserDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "auth", description = "Sign up / sign in / refresh + current user")
public class AuthController {
  private final AuthService authService;
  @PostMapping("/auth/signup")
  @Operation(summary = "Register a new user")
  public ResponseEntity<AuthResponse> signUp(@Valid @RequestBody SignUpRequest req) {
    AuthResponse res = authService.signUp(req);
    return ResponseEntity.created(URI.create("/api/v1/users/me")).body(res);
  }
  @PostMapping("/auth/signin")
  @Operation(summary = "Sign in with email + password")
  public ResponseEntity<AuthResponse> signIn(@Valid @RequestBody SignInRequest req) {
    return ResponseEntity.ok(authService.signIn(req));
  }
  @PostMapping("/auth/refresh")
  @Operation(summary = "Rotate token pair with a refresh token")
  public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest req) {
    return ResponseEntity.ok(authService.refresh(req));
  }
  @GetMapping("/users/me")
  @Operation(summary = "Current user")
  public ResponseEntity<UserDto> me(@AuthenticationPrincipal UserEntity current) {
    return ResponseEntity.ok(authService.toDto(current));
  }
  @PatchMapping("/users/me")
  @Operation(summary = "Rename current user")
  public ResponseEntity<UserDto> updateProfile(
      @AuthenticationPrincipal UserEntity current, @Valid @RequestBody UpdateProfileRequest req) {
    return ResponseEntity.ok(authService.updateProfile(current, req));
  }
}
