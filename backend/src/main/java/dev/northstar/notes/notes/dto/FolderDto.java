package dev.northstar.notes.notes.dto;

import java.time.Instant;
import java.util.UUID;

public record FolderDto(UUID id, String name, UUID parentId, Instant createdAt) {}
