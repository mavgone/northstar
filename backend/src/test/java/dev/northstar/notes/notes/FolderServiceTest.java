package dev.northstar.notes.notes;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import dev.northstar.notes.notes.dto.CreateFolderRequest;
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
@DisplayName("FolderService")
class FolderServiceTest {

  @Mock private FolderRepository folders;
  @Mock private NoteRepository notes;

  @InjectMocks private FolderService service;

  private FolderEntity folder(UUID owner, UUID id, String name, FolderEntity parent) {
    var f = new FolderEntity();
    f.setId(id);
    f.setOwnerId(owner);
    f.setName(name);
    f.setParent(parent);
    return f;
  }

  @Test
  @DisplayName("rejects duplicate name under same parent")
  void shouldRejectDuplicate() {
    UUID owner = UUID.randomUUID();
    var existing = folder(owner, UUID.randomUUID(), "Work", null);
    when(folders.findByOwnerIdOrderByNameAsc(owner)).thenReturn(List.of(existing));

    assertThatThrownBy(() -> service.create(owner, new CreateFolderRequest("work", null)))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  @DisplayName("rejects moving folder into its own child")
  void shouldRejectCycle() {
    UUID owner = UUID.randomUUID();
    var root = folder(owner, UUID.randomUUID(), "A", null);
    var child = folder(owner, UUID.randomUUID(), "B", root);
    when(folders.findByIdAndOwnerId(root.getId(), owner)).thenReturn(Optional.of(root));
    when(folders.findByIdAndOwnerId(child.getId(), owner)).thenReturn(Optional.of(child));

    assertThatThrownBy(() -> service.update(owner, root.getId(),
            new dev.northstar.notes.notes.dto.UpdateFolderRequest(null, child.getId())))
        .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  @DisplayName("delete moves notes to Inbox")
  void shouldMoveNotesOnDelete() {
    UUID owner = UUID.randomUUID();
    var inbox = folder(owner, UUID.randomUUID(), "Inbox", null);
    var doomed = folder(owner, UUID.randomUUID(), "Old", null);
    when(folders.findByIdAndOwnerId(doomed.getId(), owner)).thenReturn(Optional.of(doomed));
    when(folders.findByOwnerIdOrderByNameAsc(owner)).thenReturn(List.of(inbox, doomed));

    service.delete(owner, doomed.getId());

    org.mockito.Mockito.verify(notes).moveNotesToFolder(owner, doomed.getId(), inbox.getId());
    org.mockito.Mockito.verify(folders).delete(doomed);
  }
}
