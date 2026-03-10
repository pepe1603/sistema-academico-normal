package com.academic_system.service;

import com.academic_system.dto.auth.*;
import com.academic_system.entity.PasswordRecovery;
import com.academic_system.entity.User;
import com.academic_system.repository.PasswordRecoveryRepository;
import com.academic_system.repository.UserRepository;
import com.academic_system.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordRecoveryRepository passwordRecoveryRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TwoFactorService twoFactorService;
    private final AuthenticationManager authenticationManager;

    @Value("${security.password.expiry-days:90}")
    private int passwordExpiryDays;

    @Value("${security.max-login-attempts:5}")
    private int maxLoginAttempts;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new BadCredentialsException("Credenciales inválidas"));

        // Verificar si la cuenta está bloqueada
        if (user.getIsLocked()) {
            throw new LockedException("Cuenta bloqueada por intentos fallidos. Contacte al administrador.");
        }

        // Verificar si debe cambiar contraseña
        if (Boolean.TRUE.equals(user.getMustChangePassword())) {
            throw new PasswordChangeRequiredException("Debe cambiar su contraseña antes de continuar");
        }

        // Verificar si la contraseña está expirada
        if (user.isPasswordExpired(passwordExpiryDays)) {
            user.setMustChangePassword(true);
            userRepository.save(user);
            throw new PasswordChangeRequiredException("Su contraseña ha expirado. Debe cambiarla.");
        }

        // Autenticar
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()
                )
        );

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();

        // Si tiene 2FA habilitado, devolver token parcial
        if (Boolean.TRUE.equals(user.getTwoFactorEnabled())) {
            // Generar token temporal para completar 2FA
            String tempToken = jwtService.generateToken(
                    java.util.Map.of("userId", user.getId().toString(), "requires2fa", "true"),
                    userDetails,
                    300000 // 5 minutos para completar 2FA
            );

            return LoginResponse.builder()
                    .userId(user.getId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .requiresTwoFactor(true)
                    .tempToken(tempToken)
                    .build();
        }

        // Login exitoso sin 2FA
        return completeLogin(user);
    }

    @Transactional
    public LoginResponse verifyTwoFactor(TwoFactorRequest request) {
        String username = jwtService.extractUsername(request.getTempToken());
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new BadCredentialsException("Usuario no encontrado"));

        boolean isValid = false;

        // Verificar código TOTP
        if (request.getCode() != null && !request.getCode().isEmpty()) {
            isValid = twoFactorService.verifyCode(user.getTwoFactorSecret(), request.getCode());
        }
        // Verificar código de respaldo
        else if (request.getBackupCode() != null && !request.getBackupCode().isEmpty()) {
            isValid = twoFactorService.verifyBackupCode(user.getTwoFactorBackupCodes(), request.getBackupCode());
            
            if (isValid) {
                // Remover código de respaldo usado
                String updatedCodes = twoFactorService.removeUsedBackupCode(
                        user.getTwoFactorBackupCodes(), request.getBackupCode());
                user.setTwoFactorBackupCodes(updatedCodes);
            }
        }

        if (!isValid) {
            user.incrementFailedAttempts();
            userRepository.save(user);
            throw new BadCredentialsException("Código inválido");
        }

        return completeLogin(user);
    }

    private LoginResponse completeLogin(User user) {
        user.resetFailedAttempts();
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        CustomUserDetails userDetails = new CustomUserDetails(user);

        String accessToken = jwtService.generateAccessToken(userDetails);
        String refreshToken = jwtService.generateRefreshToken(userDetails);

        return LoginResponse.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .roles(user.getRoles().stream()
                        .map(r -> r.getName())
                        .collect(Collectors.toSet()))
                .permissions(user.getRoles().stream()
                        .flatMap(r -> r.getPermissions().stream())
                        .map(p -> p.getCode())
                        .collect(Collectors.toSet()))
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtService.getAccessTokenExpiration())
                .build();
    }

    @Transactional
    public ApiResponse<String> refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();
        String username = jwtService.extractUsername(refreshToken);

        CustomUserDetails userDetails = (CustomUserDetails) 
                SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        if (!jwtService.isTokenValid(refreshToken, userDetails)) {
            return ApiResponse.error("Refresh token inválido");
        }

        String newAccessToken = jwtService.generateAccessToken(userDetails);

        return ApiResponse.success("Token refrescado", newAccessToken);
    }

    @Transactional
    public ApiResponse<Void> logout() {
        SecurityContextHolder.clearContext();
        return ApiResponse.success("Sesión cerrada exitosamente", null);
    }

    // === RECUPERACIÓN DE CONTRASEÑA ===

    @Transactional
    public ApiResponse<Void> requestPasswordRecovery(PasswordRecoveryRequest request) {
        userRepository.findByEmail(request.getEmail())
                .ifPresent(user -> {
                    String token = UUID.randomUUID().toString();
                    
                    passwordRecoveryRepository.markAllTokensAsUsedForUser(user.getId());

                    PasswordRecovery recovery = PasswordRecovery.builder()
                            .user(user)
                            .recoveryToken(token)
                            .expiresAt(LocalDateTime.now().plusHours(24))
                            .isUsed(false)
                            .build();

                    passwordRecoveryRepository.save(recovery);

                    // TODO: Enviar email con el token
                    // emailService.sendPasswordRecoveryEmail(user.getEmail(), token);
                });

        return ApiResponse.success("Si el email existe, se enviará un enlace de recuperación", null);
    }

    @Transactional
    public ApiResponse<Void> resetPassword(ResetPasswordRequest request) {
        PasswordRecovery recovery = passwordRecoveryRepository
                .findByRecoveryToken(request.getToken())
                .orElse(null);

        if (recovery == null) {
            return ApiResponse.error("Token inválido");
        }

        if (recovery.getIsUsed()) {
            return ApiResponse.error("Token ya utilizado");
        }

        if (recovery.isExpired()) {
            return ApiResponse.error("Token expirado");
        }

        User user = recovery.getUser();
        
        // Validar que la nueva contraseña sea diferente
        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            return ApiResponse.error("La nueva contraseña debe ser diferente a la anterior");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setPasswordChangedAt(LocalDateTime.now());
        user.setMustChangePassword(false);
        userRepository.save(user);

        recovery.setIsUsed(true);
        passwordRecoveryRepository.save(recovery);

        passwordRecoveryRepository.markAllTokensAsUsedForUser(user.getId());

        return ApiResponse.success("Contraseña restablecida exitosamente", null);
    }

    // === 2FA ===

    @Transactional
    public TwoFactorSetupResponse setupTwoFactor(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        String secret = twoFactorService.generateSecret();
        String backupCodes = twoFactorService.generateBackupCodes();

        user.setTwoFactorSecret(secret);
        user.setTwoFactorBackupCodes(backupCodes);
        user.setTwoFactorEnabled(false); // No habilitar hasta verificar
        userRepository.save(user);

        return TwoFactorSetupResponse.builder()
                .secret(secret)
                .backupCodes(backupCodes.split(","))
                .qrCodeUrl("otpauth://totp/AcademicSystem:" + user.getUsername() + "?secret=" + secret + "&issuer=AcademicSystem")
                .build();
    }

    @Transactional
    public ApiResponse<Void> enableTwoFactor(UUID userId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        if (!twoFactorService.verifyCode(user.getTwoFactorSecret(), code)) {
            return ApiResponse.error("Código inválido");
        }

        user.setTwoFactorEnabled(true);
        userRepository.save(user);

        return ApiResponse.success("Autenticación de dos factores habilitada", null);
    }

    @Transactional
    public ApiResponse<Void> disableTwoFactor(UUID userId, String password) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            return ApiResponse.error("Contraseña incorrecta");
        }

        user.setTwoFactorEnabled(false);
        user.setTwoFactorSecret(null);
        user.setTwoFactorBackupCodes(null);
        userRepository.save(user);

        return ApiResponse.success("Autenticación de dos factores deshabilitada", null);
    }

    // === CAMBIO DE CONTRASEÑA FORZADO ===

    @Transactional
    public ApiResponse<Void> changePassword(ChangePasswordRequest request) {
        CustomUserDetails userDetails = (CustomUserDetails) 
                SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        User user = userRepository.findById(userDetails.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            return ApiResponse.error("Contraseña actual incorrecta");
        }

        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            return ApiResponse.error("La nueva contraseña debe ser diferente a la anterior");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setPasswordChangedAt(LocalDateTime.now());
        user.setMustChangePassword(false);
        userRepository.save(user);

        return ApiResponse.success("Contraseña cambiada exitosamente", null);
    }
}
