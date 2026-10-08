package dev.northstar.notes.notes.dto;
import jakarta.validation.constraints.Size;
import java.util.List;
public record CreateNoteRequest(
    @Size(max = 100) String folderId,
    @Size(max = 200) String title,
    @Size(max = 100000) String body,
    @Size(max = 200) List<@Size(max = 50) String> tags,
    Boolean isFavorite) {}
