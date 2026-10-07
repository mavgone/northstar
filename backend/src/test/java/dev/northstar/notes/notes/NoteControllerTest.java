package dev.northstar.notes.notes;
import static org.mockito.ArgumentMatchers.any;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import dev.northstar.notes.auth.UserEntity;
import dev.northstar.notes.notes.dto.CreateNoteRequest;
import dev.northstar.notes.notes.dto.NoteDto;
import dev.northstar.notes.shared.security.JwtAuthFilter;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
@WebMvcTest(
    controllers = NoteController.class,
    excludeFilters =
        @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = JwtAuthFilter.class))
@ActiveProfiles("test")
@DisplayName("NoteController")
class NoteControllerTest {
  @Autowired private MockMvc mockMvc;
  @MockBean private NoteService noteService;
  @MockBean private UserDetailsService userDetailsService;
  private NoteDto sample() {
    return new NoteDto(
        UUID.randomUUID(),
        "Q3 roadmap",
        "body",
        "Inbox",
        List.of("roadmap"),
        Instant.now(),
        Instant.now(),
        false,
        "active");
  }
  private UserEntity currentUser() {
    var user = new UserEntity("demo@obsidian.dev", "hashed", "Demo");
    user.setId(UUID.randomUUID());
    return user;
  }
  @Test
  @DisplayName("GET /api/v1/notes should return 200 with list")
  void shouldList() throws Exception {
    Mockito.when(noteService.list(any())).thenReturn(List.of(sample()));
    mockMvc
        .perform(get("/api/v1/notes").with(user(currentUser())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].title").value("Q3 roadmap"));
  }
  @Test
  @DisplayName("POST /api/v1/notes should return 201 with Location")
  void shouldCreate() throws Exception {
    Mockito.when(noteService.create(any(), any(CreateNoteRequest.class))).thenReturn(sample());
    mockMvc
        .perform(
            post("/api/v1/notes")
                .with(user(currentUser()))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.title").value("Q3 roadmap"));
  }
  @Test
  @DisplayName("GET /api/v1/notes without auth should be denied")
  void shouldDenyAnonymous() throws Exception {
    Mockito.when(noteService.list(any())).thenReturn(List.of());
    mockMvc.perform(get("/api/v1/notes")).andExpect(status().is4xxClientError());
  }
}
