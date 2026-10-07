package dev.northstar.notes.notes;
import dev.northstar.notes.notes.dto.CreateNoteRequest;
import dev.northstar.notes.notes.dto.NoteDto;
import dev.northstar.notes.notes.dto.UpdateNoteRequest;
import dev.northstar.notes.shared.exception.NotFoundException;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Slf4j
@Service
@RequiredArgsConstructor
public class NoteService {
  private final NoteRepository notes;
  @Transactional(readOnly = true)
  public List<NoteDto> list(UUID ownerId) {
    return notes.findByOwnerIdOrderByUpdatedAtDesc(ownerId).stream()
        .map(this::toDto)
        .toList();
  }
  @Transactional
  public NoteDto create(UUID ownerId, CreateNoteRequest req) {
    var entity = new NoteEntity();
    entity.setOwnerId(ownerId);
    entity.setFolder(req != null && req.folder() != null ? req.folder() : "Inbox");
    entity.setTitle(req != null && req.title() != null ? req.title() : "Untitled");
    entity.setBody(req != null && req.body() != null ? req.body() : "");
    if (req != null && req.tags() != null) {
      entity.setTags(cleanTags(req.tags()));
    }
    if (req != null && req.isFavorite() != null) {
      entity.setFavorite(req.isFavorite());
    }
    entity.setStatus(NoteStatus.active);
    notes.save(entity);
    log.info("Note created: {} owner={}", entity.getId(), ownerId);
    return toDto(entity);
  }
  @Transactional
  public NoteDto update(UUID ownerId, UUID id, UpdateNoteRequest req) {
    var existing = notes.findById(id);
    if (existing.isPresent()) {
      if (!existing.get().getOwnerId().equals(ownerId)) {
        throw new NotFoundException("Note not found: " + id);
      }
      return updateEntity(existing.get(), req);
    }
    var entity = new NoteEntity();
    entity.setId(id);
    entity.setOwnerId(ownerId);
    entity.setFolder("Inbox");
    entity.setTitle("Untitled");
    entity.setBody("");
    entity.setStatus(NoteStatus.active);
    applyPatch(entity, req);
    entity.setUpdatedAt(Instant.now());
    notes.save(entity);
    log.info("Note upsert-created: {} owner={}", id, ownerId);
    return toDto(entity);
  }
  @Transactional
  public void deleteForever(UUID ownerId, UUID id) {
    NoteEntity entity = requireMine(ownerId, id);
    notes.delete(entity);
    log.info("Note deleted forever: {} owner={}", id, ownerId);
  }
  private NoteEntity requireMine(UUID ownerId, UUID id) {
    return notes
        .findByIdAndOwnerId(id, ownerId)
        .orElseThrow(() -> new NotFoundException("Note not found: " + id));
  }
  private NoteDto updateEntity(NoteEntity entity, UpdateNoteRequest req) {
    applyPatch(entity, req);
    entity.setUpdatedAt(Instant.now());
    notes.save(entity);
    return toDto(entity);
  }
  private static void applyPatch(NoteEntity entity, UpdateNoteRequest req) {
    if (req.title() != null) {
      entity.setTitle(req.title());
    }
    if (req.body() != null) {
      entity.setBody(req.body());
    }
    if (req.folder() != null) {
      entity.setFolder(req.folder());
    }
    if (req.tags() != null) {
      entity.setTags(cleanTags(req.tags()));
    }
    if (req.isFavorite() != null) {
      entity.setFavorite(req.isFavorite());
    }
    if (req.status() != null) {
      entity.setStatus(NoteStatus.valueOf(req.status()));
    }
  }
  static Set<String> cleanTags(List<String> tags) {
    return tags.stream()
        .filter(java.util.Objects::nonNull)
        .map(t -> t.toLowerCase().replace("#", "").trim())
        .filter(t -> !t.isEmpty())
        .collect(Collectors.toSet());
  }
  public NoteDto toDto(NoteEntity entity) {
    return new NoteDto(
        entity.getId(),
        entity.getTitle(),
        entity.getBody(),
        entity.getFolder(),
        List.copyOf(entity.getTags()),
        entity.getCreatedAt(),
        entity.getUpdatedAt(),
        entity.isFavorite(),
        entity.getStatus().name());
  }
}
