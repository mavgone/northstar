package dev.northstar.notes.auth.dto;
public record AuthResponse(String accessToken, String refreshToken, UserDto user) {}
