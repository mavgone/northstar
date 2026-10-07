package dev.northstar.notes.notes;
import dev.northstar.notes.notes.dto.CreateNoteRequest;
import dev.northstar.notes.notes.dto.NoteDto;
import dev.northstar.notes.notes.dto.UpdateNoteRequest;
import dev.northstar.notes.shared.exception.NotFoundException;
import java.time.Instant;
import java.util.List;
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
    entity.setTitle("Untitled");
    entity.setBody("");
    entity.setStatus(NoteStatus.active);
    notes.save(entity);
    log.info("Note created: {} owner={}", entity.getId(), ownerId);
    return toDto(entity);
  }
  @Transactional
  public NoteDto update(UUID ownerId, UUID id, UpdateNoteRequest req) {
    NoteEntity entity = requireMine(ownerId, id);
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
      entity.setTags(
          req.tags().stream()
              .filter(java.util.Objects::nonNull)
              .map(t -> t.toLowerCase().replace("#", "").trim())
              .filter(t -> !t.isEmpty())
              .collect(Collectors.toSet()));
    }
    if (req.isFavorite() != null) {
      entity.setFavorite(req.isFavorite());
    }
    if (req.status() != null) {
      entity.setStatus(NoteStatus.valueOf(req.status()));
    }
    entity.setUpdatedAt(Instant.now());
    notes.save(entity);
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
