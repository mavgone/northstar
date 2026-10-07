package dev.northstar.notes.shared.config;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
@Data
@Configuration
@ConfigurationProperties(prefix = "jwt")
public class JwtProperties {
  private String secret = "change-me-min-32-chars-in-production-0123456789";
  private long accessTokenExpiration = 900_000;
  private long refreshTokenExpiration = 604_800_000;
  private String issuer = "northstar-notes";
}
