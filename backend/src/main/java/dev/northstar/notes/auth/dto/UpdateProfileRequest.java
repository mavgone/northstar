package dev.northstar.notes.auth.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
public record UpdateProfileRequest(
    @NotBlank(message = "Name is too short.") @Size(min = 2, message = "Name is too short.") String name) {}
