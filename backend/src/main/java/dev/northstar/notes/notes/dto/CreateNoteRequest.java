package dev.northstar.notes.notes.dto;
import jakarta.validation.constraints.Size;
public record CreateNoteRequest(@Size(max = 80) String folder) {}
