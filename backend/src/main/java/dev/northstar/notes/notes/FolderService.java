package dev.northstar.notes.notes;

import dev.northstar.notes.notes.dto.CreateFolderRequest;
import dev.northstar.notes.notes.dto.FolderDto;
import dev.northstar.notes.notes.dto.UpdateFolderRequest;
import dev.northstar.notes.shared.exception.NotFoundException;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class FolderService {

  private final FolderRepository folders;
  private final NoteRepository notes;

  @Transactional(readOnly = true)
  public List<FolderDto> list(UUID ownerId) {
    return folders.findByOwnerIdOrderByNameAsc(ownerId).stream().map(this::toDto).toList();
  }

  @Transactional
  public FolderDto create(UUID ownerId, CreateFolderRequest req) {
    FolderEntity parent = resolveParent(ownerId, req.parentId());
    assertUniqueName(ownerId, parent, req.name().trim(), null);
    var entity = new FolderEntity();
    entity.setOwnerId(ownerId);
    entity.setName(req.name().trim());
    entity.setParent(parent);
    folders.save(entity);
    log.info("Folder created: {} owner={}", entity.getId(), ownerId);
    return toDto(entity);
  }

  @Transactional
  public FolderDto update(UUID ownerId, UUID id, UpdateFolderRequest req) {
    var entity = requireMine(ownerId, id);
    if (req.name() != null) {
      assertUniqueName(ownerId, entity.getParent(), req.name().trim(), id);
      entity.setName(req.name().trim());
    }
    if (req.parentId() != null) {
      FolderEntity parent = resolveParent(ownerId, req.parentId());
      assertNoCycle(entity, parent);
      assertUniqueName(ownerId, parent, entity.getName(), id);
      entity.setParent(parent);
    }
    folders.save(entity);
    return toDto(entity);
  }

  @Transactional
  public void moveToRoot(UUID ownerId, UUID id) {
    var entity = requireMine(ownerId, id);
    assertUniqueName(ownerId, null, entity.getName(), id);
    entity.setParent(null);
    folders.save(entity);
  }

  @Transactional
  public void delete(UUID ownerId, UUID id) {
    var entity = requireMine(ownerId, id);
    if (entity.getParent() == null && entity.getName().equals("Inbox")) {
      throw new IllegalArgumentException("Cannot delete Inbox.");
    }
    var inbox = folders.findByOwnerIdOrderByNameAsc(ownerId).stream()
        .filter(f -> f.getParent() == null && f.getName().equals("Inbox") && !f.getId().equals(id))
        .findFirst()
        .orElseGet(() -> {
          var created = new FolderEntity();
          created.setOwnerId(ownerId);
          created.setName("Inbox");
          return folders.save(created);
        });
    notes.moveNotesToFolder(ownerId, id, inbox.getId());
    folders.delete(entity);
    log.info("Folder deleted: {} owner={}", id, ownerId);
  }

  private FolderEntity requireMine(UUID ownerId, UUID id) {
    return folders
        .findByIdAndOwnerId(id, ownerId)
        .orElseThrow(() -> new NotFoundException("Folder not found: " + id));
  }

  private FolderEntity resolveParent(UUID ownerId, UUID parentId) {
    if (parentId == null) return null;
    return requireMine(ownerId, parentId);
  }

  private void assertUniqueName(UUID ownerId, FolderEntity parent, String name, UUID selfId) {
    UUID parentId = parent == null ? null : parent.getId();
    boolean clash = folders.findByOwnerIdOrderByNameAsc(ownerId).stream()
        .anyMatch(f -> !f.getId().equals(selfId)
            && sameParent(f, parentId)
            && f.getName().equalsIgnoreCase(name));
    if (clash) {
      throw new IllegalArgumentException("A folder with this name already exists here.");
    }
  }

  private static boolean sameParent(FolderEntity f, UUID parentId) {
    UUID actual = f.getParent() == null ? null : f.getParent().getId();
    if (actual == null) return parentId == null;
    return actual.equals(parentId);
  }

  private void assertNoCycle(FolderEntity entity, FolderEntity parent) {
    FolderEntity p = parent;
    while (p != null) {
      if (p.getId().equals(entity.getId())) {
        throw new IllegalArgumentException("Cannot move a folder into itself or its child.");
      }
      p = p.getParent();
    }
  }

  private FolderDto toDto(FolderEntity entity) {
    UUID parentId = entity.getParent() == null ? null : entity.getParent().getId();
    return new FolderDto(entity.getId(), entity.getName(), parentId, entity.getCreatedAt());
  }
}
