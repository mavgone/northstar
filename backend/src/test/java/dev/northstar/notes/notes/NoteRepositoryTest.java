package dev.northstar.notes.notes;
import static org.assertj.core.api.Assertions.assertThat;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
@DataJpaTest
@ActiveProfiles("test")
@DisplayName("NoteRepository")
class NoteRepositoryTest {
  @Autowired private NoteRepository notes;
  @Test
  @DisplayName("Should save and find by owner ordered by updatedAt")
  void shouldSaveAndFindByOwner() {
    UUID owner = UUID.randomUUID();
    var note = new NoteEntity();
    note.setOwnerId(owner);
    note.setTitle("Desktop layout principles");
    note.setBody("Sidebar 264px");
    note.getTags().add("design");
    notes.save(note);
    var other = new NoteEntity();
    other.setOwnerId(UUID.randomUUID());
    notes.save(other);
    var mine = notes.findByOwnerIdOrderByUpdatedAtDesc(owner);
    assertThat(mine).hasSize(1);
    assertThat(mine.get(0).getTitle()).isEqualTo("Desktop layout principles");
    assertThat(notes.findByIdAndOwnerId(note.getId(), owner)).isPresent();
    assertThat(notes.findByIdAndOwnerId(note.getId(), UUID.randomUUID())).isEmpty();
  }
}
