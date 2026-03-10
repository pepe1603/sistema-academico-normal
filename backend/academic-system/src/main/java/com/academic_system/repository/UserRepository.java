package com.academic_system.repository;

import com.academic_system.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByUsername(String username);

    Optional<User> findByEmail(String email);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    @Modifying
    @Query("UPDATE User u SET u.failedAttempts = 0 WHERE u.id = :userId")
    void resetFailedAttempts(UUID userId);

    @Modifying
    @Query("UPDATE User u SET u.failedAttempts = u.failedAttempts + 1, u.isLocked = CASE WHEN u.failedAttempts + 1 >= 5 THEN true ELSE u.isLocked END WHERE u.id = :userId")
    void incrementFailedAttempts(UUID userId);
}
