package dev.northstar.notes.auth;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
@Service
@RequiredArgsConstructor
public class DbUserDetailsService implements UserDetailsService {
  private final UserRepository users;
  @Override
  public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
    return users
        .findByEmail(email.trim().toLowerCase())
        .orElseThrow(() -> new UsernameNotFoundException("No account found for this email."));
  }
}
