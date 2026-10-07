package dev.northstar.notes.auth.dto;
import java.time.Instant;
import java.util.UUID;
public record UserDto(UUID id, String name, String email, Instant createdAt) {}
