package dev.northstar.notes.auth.dto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
public record SignInRequest(
    @NotBlank(message = "Enter a valid email address.") @Email(message = "Enter a valid email address.") String email,
    @NotBlank @Size(min = 6, message = "Password must be at least 6 characters.") String password) {}
