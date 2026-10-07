package dev.northstar.notes.auth;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class UserEntity implements UserDetails {
  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  private UUID id;
  @Column(nullable = false, unique = true)
  private String email;
  @Column(name = "password_hash", nullable = false)
  private String passwordHash;
  @Column(nullable = false, length = 100)
  private String name;
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt = Instant.now();
  public UserEntity(String email, String passwordHash, String name) {
    this.email = email;
    this.passwordHash = passwordHash;
    this.name = name;
  }
  @Override
  public Collection<? extends GrantedAuthority> getAuthorities() {
    return List.of(new SimpleGrantedAuthority("ROLE_USER"));
  }
  @Override
  public String getPassword() {
    return passwordHash;
  }
  @Override
  public String getUsername() {
    return email;
  }
}
