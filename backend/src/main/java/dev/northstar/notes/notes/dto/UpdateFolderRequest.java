package dev.northstar.notes.notes.dto;

import jakarta.validation.constraints.Size;
import java.util.UUID;

public record UpdateFolderRequest(@Size(max = 100) String name, UUID parentId) {}
