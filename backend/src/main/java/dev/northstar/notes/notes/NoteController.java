package dev.northstar.notes.notes;
import dev.northstar.notes.auth.UserEntity;
import dev.northstar.notes.notes.dto.CreateNoteRequest;
import dev.northstar.notes.notes.dto.NoteDto;
import dev.northstar.notes.notes.dto.UpdateNoteRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
@RequestMapping("/api/v1/notes")
@RequiredArgsConstructor
@Tag(name = "notes", description = "Notes CRUD (mirrors NotesRepository)")
public class NoteController {
  private final NoteService noteService;
  @GetMapping
  @Operation(summary = "List my notes (mirrors loadNotes)")
  public ResponseEntity<List<NoteDto>> list(@AuthenticationPrincipal UserEntity current) {
    return ResponseEntity.ok(noteService.list(current.getId()));
  }
  @PostMapping
  @Operation(summary = "Create note (Untitled, active)")
  public ResponseEntity<NoteDto> create(
      @AuthenticationPrincipal UserEntity current,
      @Valid @RequestBody(required = false) CreateNoteRequest req) {
    NoteDto created = noteService.create(current.getId(), req);
    return ResponseEntity.created(URI.create("/api/v1/notes/" + created.id())).body(created);
  }
  @PatchMapping("/{id}")
  @Operation(summary = "Patch note fields (mirrors saveNote/patch/moveTo/toTrash/restore)")
  public ResponseEntity<NoteDto> update(
      @AuthenticationPrincipal UserEntity current,
      @PathVariable UUID id,
      @Valid @RequestBody UpdateNoteRequest req) {
    return ResponseEntity.ok(noteService.update(current.getId(), id, req));
  }
  @DeleteMapping("/{id}")
  @Operation(summary = "Delete forever (mirrors deleteForever)")
  public ResponseEntity<Void> delete(
      @AuthenticationPrincipal UserEntity current, @PathVariable UUID id) {
    noteService.deleteForever(current.getId(), id);
    return ResponseEntity.noContent().build();
  }
}
