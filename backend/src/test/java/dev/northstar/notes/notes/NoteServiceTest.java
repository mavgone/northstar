package dev.northstar.notes.notes;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import dev.northstar.notes.notes.dto.CreateNoteRequest;
import dev.northstar.notes.notes.dto.UpdateNoteRequest;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
@ExtendWith(MockitoExtension.class)
@DisplayName("NoteService status")
class NoteServiceTest {
  @Mock private NoteRepository notes;

  @Mock private FolderRepository folders;
  @InjectMocks private NoteService service;
  private NoteEntity active(UUID owner, UUID id) {
    var entity = new NoteEntity();
    entity.setId(id);
    entity.setOwnerId(owner);
    entity.setTitle("Hello");
    entity.setBody("body");
    entity.setStatus(NoteStatus.active);
    return entity;
  }
  @Test
  @DisplayName("update keeps active status when patching content")
  void shouldKeepActive() {
    UUID owner = UUID.randomUUID();
    UUID id = UUID.randomUUID();
    when(notes.findById(id)).thenReturn(Optional.of(active(owner, id)));
    when(notes.save(any(NoteEntity.class))).thenAnswer(inv -> inv.getArgument(0));
    var dto = service.update(owner, id, new UpdateNoteRequest(null, "hello again", null, null, null, null));
    assertThat(dto.status()).isEqualTo("active");
    assertThat(dto.body()).isEqualTo("hello again");
  }
  @Test
  @DisplayName("update keeps trashed status untouched")
  void shouldKeepTrashed() {
    UUID owner = UUID.randomUUID();
    UUID id = UUID.randomUUID();
    var entity = active(owner, id);
    entity.setStatus(NoteStatus.trashed);
    when(notes.findById(id)).thenReturn(Optional.of(entity));
    when(notes.save(any(NoteEntity.class))).thenAnswer(inv -> inv.getArgument(0));

    var dto = service.update(owner, id, new UpdateNoteRequest("Hello", null, null, null, null, null));

    assertThat(dto.status()).isEqualTo("trashed");
  }

  @Test
  @DisplayName("update on missing id creates with client id (upsert)")
  void shouldUpsertCreate() {
    UUID owner = UUID.randomUUID();
    UUID id = UUID.randomUUID();
    when(notes.findById(id)).thenReturn(Optional.empty());
    when(notes.save(any(NoteEntity.class))).thenAnswer(inv -> inv.getArgument(0));

    var dto = service.update(owner, id, new UpdateNoteRequest("Hi", "body", null, null, null, null));

    assertThat(dto.id()).isEqualTo(id);
    assertThat(dto.title()).isEqualTo("Hi");
  }

  @Test
  @DisplayName("update on foreign id is denied")
  void shouldDenyForeignId() {
    UUID owner = UUID.randomUUID();
    UUID id = UUID.randomUUID();
    var foreign = active(UUID.randomUUID(), id);
    when(notes.findById(id)).thenReturn(Optional.of(foreign));

    assertThatThrownBy(() -> service.update(owner, id, new UpdateNoteRequest("Hi", null, null, null, null, null)))
        .isInstanceOf(dev.northstar.notes.shared.exception.NotFoundException.class);
  }

  @Test
  @DisplayName("create applies full payload in one row")
  void shouldCreateFull() {
    UUID owner = UUID.randomUUID();
    UUID folderId = UUID.randomUUID();
    var folder = new FolderEntity();
    folder.setId(folderId);
    folder.setOwnerId(owner);
    folder.setName("Inbox");
    when(folders.findByIdAndOwnerId(folderId, owner)).thenReturn(Optional.of(folder));
    when(notes.save(any(NoteEntity.class))).thenAnswer(inv -> inv.getArgument(0));

    var dto = service.create(
        owner, new CreateNoteRequest(folderId.toString(), "T", "B", List.of("x"), true));

    assertThat(dto.title()).isEqualTo("T");
    assertThat(dto.body()).isEqualTo("B");
    assertThat(dto.isFavorite()).isTrue();
    assertThat(dto.folderId()).isEqualTo(folderId);
  }
}
