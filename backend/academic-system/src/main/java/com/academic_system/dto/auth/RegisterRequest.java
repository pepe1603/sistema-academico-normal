package com.academic_system.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "El username es requerido")
    @Size(min = 3, max = 50, message = "El username debe tener entre 3 y 50 caracteres")
    private String username;

    @NotBlank(message = "El email es requerido")
    @Email(message = "El formato del email no es válido")
    private String email;

    @NotBlank(message = "La contraseña es requerida")
    @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres")
    private String password;

    private String confirmPassword;

    private RegisterType type;

    // Datos para estudiante
    private String curp;
    private String enrollmentNumber;

    // Datos para profesor
    private String rfc;
    private String employeeNumber;

    public enum RegisterType {
        STUDENT,    // Registro como estudiante (verifica CURP)
        TEACHER,    // Registro como profesor (verifica RFC)
        GENERAL     // Registro general (sin verificación)
    }

    public boolean isPasswordMatch() {
        return password != null && password.equals(confirmPassword);
    }
}
