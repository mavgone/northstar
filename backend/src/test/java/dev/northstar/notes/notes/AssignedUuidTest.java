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
@DisplayName("Assigned UUID")
class AssignedUuidTest {

  @Autowired private NoteRepository notes;

  @Test
  @DisplayName("save entity with client-assigned UUID")
  void shouldSaveAssignedId() {
    UUID id = UUID.randomUUID();
    var entity = new NoteEntity();
    entity.setId(id);
    entity.setOwnerId(UUID.randomUUID());
    entity.setFolderId(UUID.randomUUID());
    entity.setTitle("T");
    var saved = notes.saveAndFlush(entity);
    assertThat(saved.getId()).isEqualTo(id);
    assertThat(notes.findById(id)).isPresent();
  }
}
