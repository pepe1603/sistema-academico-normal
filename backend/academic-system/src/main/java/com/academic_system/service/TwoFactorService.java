package com.academic_system.service;

import dev.samstevens.totp.code.*;
import dev.samstevens.totp.secret.DefaultSecretGenerator;
import dev.samstevens.totp.secret.SecretGenerator;
import dev.samstevens.totp.time.SystemTimeProvider;
import dev.samstevens.totp.time.TimeProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TwoFactorService {

    private static final int BACKUP_CODES_COUNT = 8;
    private static final int BACKUP_CODE_LENGTH = 8;

    private final CodeVerifier codeVerifier;
    private final SecretGenerator secretGenerator = new DefaultSecretGenerator();

    public String generateSecret() {
        return secretGenerator.generate();
    }

    public String generateBackupCodes() {
        SecureRandom random = new SecureRandom();
        List<String> codes = new ArrayList<>();
        
        for (int i = 0; i < BACKUP_CODES_COUNT; i++) {
            StringBuilder code = new StringBuilder();
            for (int j = 0; j < BACKUP_CODE_LENGTH; j++) {
                code.append(random.nextInt(10));
            }
            codes.add(code.toString());
        }
        
        return String.join(",", codes);
    }

    public boolean verifyCode(String secret, String code) {
        try {
            return codeVerifier.isValidCode(secret, code);
        } catch (CodeGenerationException | TimeProviderException e) {
            return false;
        }
    }

    public boolean verifyBackupCode(String storedCodes, String inputCode) {
        if (storedCodes == null || inputCode == null) {
            return false;
        }
        
        List<String> codes = List.of(storedCodes.split(","));
        
        for (int i = 0; i < codes.size(); i++) {
            if (codes.get(i).equals(inputCode)) {
                List<String> updatedCodes = new ArrayList<>(codes);
                updatedCodes.remove(i);
                return true;
            }
        }
        
        return false;
    }

    public String removeUsedBackupCode(String storedCodes, String usedCode) {
        List<String> codes = new ArrayList<>(List.of(storedCodes.split(",")));
        codes.remove(usedCode);
        return String.join(",", codes);
    }

    public int getRemainingBackupCodes(String storedCodes) {
        if (storedCodes == null || storedCodes.isEmpty()) {
            return 0;
        }
        return (int) List.of(storedCodes.split(",")).stream()
                .filter(code -> !code.isEmpty())
                .count();
    }
}
