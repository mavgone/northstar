package dev.northstar.notes.notes.dto;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
public record NoteDto(
    UUID id,
    String title,
    String body,
    UUID folderId,
    List<String> tags,
    Instant createdAt,
    Instant updatedAt,
    boolean isFavorite,
    String status) {}
