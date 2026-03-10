package com.academic_system.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private UUID userId;
    private String username;
    private String email;
    private Set<String> roles;
    private Set<String> permissions;
    private String accessToken;
    private String refreshToken;
    private Long expiresIn;
    
    // 2FA
    private Boolean requiresTwoFactor;
    private String tempToken;
}
