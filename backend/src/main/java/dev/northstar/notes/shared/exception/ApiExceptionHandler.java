package dev.northstar.notes.shared.exception;
import io.jsonwebtoken.JwtException;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;
@RestControllerAdvice
public class ApiExceptionHandler {
  public record Problem(String type, String title, int status, String detail, String instance, Instant timestamp) {}
  private ResponseEntity<Problem> problem(HttpStatus status, String title, String detail) {
    var body =
        new Problem(
            "https://northstar.dev/errors/" + title.toLowerCase().replace(' ', '-'),
            title,
            status.value(),
            detail,
            "",
            Instant.now());
    return ResponseEntity.status(status).contentType(MediaType.parseMediaType("application/problem+json")).body(body);
  }
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<Problem> validation(MethodArgumentNotValidException ex) {
    List<String> messages =
        ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
    return problem(HttpStatus.BAD_REQUEST, "Validation failed", String.join("; ", messages));
  }
  @ExceptionHandler(NotFoundException.class)
  public ResponseEntity<Problem> notFound(NotFoundException ex) {
    return problem(HttpStatus.NOT_FOUND, "Not found", ex.getMessage());
  }
  @ExceptionHandler({BadCredentialsException.class, JwtException.class, AuthenticationException.class})
  public ResponseEntity<Problem> unauthorized(RuntimeException ex) {
    return problem(HttpStatus.UNAUTHORIZED, "Unauthorized", "Invalid email or password.");
  }
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<Problem> badRequest(IllegalArgumentException ex) {
    return problem(HttpStatus.BAD_REQUEST, "Bad request", ex.getMessage());
  }
  @ExceptionHandler(NoResourceFoundException.class)
  public ResponseEntity<Problem> noResource(NoResourceFoundException ex) {
    return problem(HttpStatus.NOT_FOUND, "Not found", "Resource not found.");
  }
  @ExceptionHandler(Exception.class)
  public ResponseEntity<Problem> unexpected(Exception ex) {
    return problem(HttpStatus.INTERNAL_SERVER_ERROR, "Internal error", "An unexpected error occurred.");
  }
}
