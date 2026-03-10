package com.academic_system.controller;

import com.academic_system.dto.auth.*;
import com.academic_system.entity.User;
import com.academic_system.service.AuthService;
import com.academic_system.service.UserRegistrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final UserRegistrationService userRegistrationService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Login exitoso", response));
    }

    @PostMapping("/verify-2fa")
    public ResponseEntity<ApiResponse<LoginResponse>> verifyTwoFactor(@Valid @RequestBody TwoFactorRequest request) {
        LoginResponse response = authService.verifyTwoFactor(request);
        return ResponseEntity.ok(ApiResponse.success("Verificación exitosa", response));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<String>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refreshToken(request));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        return ResponseEntity.ok(authService.logout());
    }

    @PostMapping("/recovery")
    public ResponseEntity<ApiResponse<Void>> requestRecovery(@Valid @RequestBody PasswordRecoveryRequest request) {
        return ResponseEntity.ok(authService.requestPasswordRecovery(request));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return ResponseEntity.ok(authService.resetPassword(request));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        
        if (!request.isPasswordMatch()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Las contraseñas no coinciden"));
        }
        
        return ResponseEntity.ok(authService.changePassword(request));
    }

    // === REGISTRATION ENDPOINTS ===

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Void>> register(@Valid @RequestBody RegisterRequest request) {
        // Validar tipo de registro
        if (request.getType() == RegisterRequest.RegisterType.GENERAL) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Tipo de registro no válido para auto-registro"));
        }
        
        userRegistrationService.register(request);
        return ResponseEntity.ok(ApiResponse.success("Usuario registrado exitosamente. Puede iniciar sesión.", null));
    }

    // === ADMIN REGISTRATION (requires ADMIN role) ===

    @PostMapping("/admin/register")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> registerByAdmin(
            @RequestParam String username,
            @RequestParam String email,
            @RequestParam String temporaryPassword,
            @RequestParam RegisterRequest.RegisterType type,
            @RequestParam(required = false) String identifier) {
        
        userRegistrationService.createUserByAdmin(username, email, temporaryPassword, type, identifier);
        return ResponseEntity.ok(ApiResponse.success("Usuario creado exitosamente. Debe cambiar su contraseña.", null));
    }

    // === 2FA ENDPOINTS ===

    @PostMapping("/2fa/setup")
    public ResponseEntity<ApiResponse<TwoFactorSetupResponse>> setupTwoFactor(
            @AuthenticationPrincipal UserDetails userDetails) {
        
        UUID userId = ((com.academic_system.security.CustomUserDetails) userDetails).getUserId();
        TwoFactorSetupResponse response = authService.setupTwoFactor(userId);
        
        return ResponseEntity.ok(ApiResponse.success("Escanee el código QR con su app", response));
    }

    @PostMapping("/2fa/enable")
    public ResponseEntity<ApiResponse<Void>> enableTwoFactor(
            @RequestParam String code,
            @AuthenticationPrincipal UserDetails userDetails) {
        
        UUID userId = ((com.academic_system.security.CustomUserDetails) userDetails).getUserId();
        return ResponseEntity.ok(authService.enableTwoFactor(userId, code));
    }

    @PostMapping("/2fa/disable")
    public ResponseEntity<ApiResponse<Void>> disableTwoFactor(
            @RequestParam String password,
            @AuthenticationPrincipal UserDetails userDetails) {
        
        UUID userId = ((com.academic_system.security.CustomUserDetails) userDetails).getUserId();
        return ResponseEntity.ok(authService.disableTwoFactor(userId, password));
    }
}
