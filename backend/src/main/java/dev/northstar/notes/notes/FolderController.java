package dev.northstar.notes.notes;

import dev.northstar.notes.auth.UserEntity;
import dev.northstar.notes.notes.dto.CreateFolderRequest;
import dev.northstar.notes.notes.dto.FolderDto;
import dev.northstar.notes.notes.dto.UpdateFolderRequest;
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
@RequestMapping("/api/v1/folders")
@RequiredArgsConstructor
@Tag(name = "folders", description = "Folder tree CRUD")
public class FolderController {

  private final FolderService folderService;

  @GetMapping
  @Operation(summary = "List my folders (flat, client builds the tree)")
  public ResponseEntity<List<FolderDto>> list(@AuthenticationPrincipal UserEntity current) {
    return ResponseEntity.ok(folderService.list(current.getId()));
  }

  @PostMapping
  @Operation(summary = "Create folder, optionally nested")
  public ResponseEntity<FolderDto> create(
      @AuthenticationPrincipal UserEntity current, @Valid @RequestBody CreateFolderRequest req) {
    FolderDto created = folderService.create(current.getId(), req);
    return ResponseEntity.created(URI.create("/api/v1/folders/" + created.id())).body(created);
  }

  @PatchMapping("/{id}")
  @Operation(summary = "Rename or move folder")
  public ResponseEntity<FolderDto> update(
      @AuthenticationPrincipal UserEntity current,
      @PathVariable UUID id,
      @Valid @RequestBody UpdateFolderRequest req) {
    return ResponseEntity.ok(folderService.update(current.getId(), id, req));
  }

  @PatchMapping("/{id}/move-to-root")
  @Operation(summary = "Move folder to root")
  public ResponseEntity<Void> moveToRoot(
      @AuthenticationPrincipal UserEntity current, @PathVariable UUID id) {
    folderService.moveToRoot(current.getId(), id);
    return ResponseEntity.ok().build();
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete folder, notes go to Inbox")
  public ResponseEntity<Void> delete(
      @AuthenticationPrincipal UserEntity current, @PathVariable UUID id) {
    folderService.delete(current.getId(), id);
    return ResponseEntity.noContent().build();
  }
}
