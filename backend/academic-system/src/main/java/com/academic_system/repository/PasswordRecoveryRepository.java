package com.academic_system.repository;

import com.academic_system.entity.PasswordRecovery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordRecoveryRepository extends JpaRepository<PasswordRecovery, UUID> {

    Optional<PasswordRecovery> findByRecoveryToken(String token);

    @Modifying
    @Query("UPDATE PasswordRecovery pr SET pr.isUsed = true WHERE pr.user.id = :userId AND pr.isUsed = false")
    void markAllTokensAsUsedForUser(UUID userId);

    @Modifying
    @Query("DELETE FROM PasswordRecovery pr WHERE pr.expiresAt < :now OR pr.isUsed = true")
    void deleteExpiredOrUsedTokens(LocalDateTime now);
}
