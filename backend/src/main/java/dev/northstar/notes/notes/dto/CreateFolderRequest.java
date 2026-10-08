package dev.northstar.notes.notes.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CreateFolderRequest(
    @NotBlank(message = "Folder name is required.") @Size(max = 100) String name,
    UUID parentId) {}
