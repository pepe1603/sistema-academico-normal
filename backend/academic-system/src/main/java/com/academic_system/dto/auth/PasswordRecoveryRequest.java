package com.academic_system.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PasswordRecoveryRequest {

    @NotBlank(message = "El email es requerido")
    @Email(message = "El formato del email no es válido")
    private String email;
}
