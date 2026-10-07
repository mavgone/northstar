package dev.northstar.notes.shared.security;
import dev.northstar.notes.shared.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.util.Date;
import java.util.function.Function;
import javax.crypto.SecretKey;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
@Service
@RequiredArgsConstructor
public class JwtService {
  private final JwtProperties props;
  private SecretKey signingKey() {
    return Keys.hmacShaKeyFor(props.getSecret().getBytes());
  }
  public String generateAccessToken(UserDetails user) {
    return Jwts.builder()
        .subject(user.getUsername())
        .issuer(props.getIssuer())
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + props.getAccessTokenExpiration()))
        .claim("type", "access")
        .signWith(signingKey())
        .compact();
  }
  public String generateRefreshToken(UserDetails user) {
    return Jwts.builder()
        .subject(user.getUsername())
        .issuer(props.getIssuer())
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + props.getRefreshTokenExpiration()))
        .claim("type", "refresh")
        .signWith(signingKey())
        .compact();
  }
  public String extractUsername(String token) {
    return extractClaim(token, Claims::getSubject);
  }
  public boolean isTokenValid(String token, UserDetails user) {
    return isTokenValidAs(token, user, "access");
  }
  public boolean isRefreshValid(String token, UserDetails user) {
    return isTokenValidAs(token, user, "refresh");
  }
  private boolean isTokenValidAs(String token, UserDetails user, String type) {
    try {
      String username = extractUsername(token);
      String actual = extractClaim(token, c -> c.get("type", String.class));
      return username.equals(user.getUsername()) && !isExpired(token) && type.equals(actual);
    } catch (JwtException e) {
      return false;
    }
  }
  private boolean isExpired(String token) {
    return extractClaim(token, Claims::getExpiration).before(new Date());
  }
  private <T> T extractClaim(String token, Function<Claims, T> resolver) {
    Claims claims =
        Jwts.parser()
            .verifyWith(signingKey())
            .requireIssuer(props.getIssuer())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    return resolver.apply(claims);
  }
}
