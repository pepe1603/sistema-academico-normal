package com.academic_system.repository;

import com.academic_system.entity.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeacherRepository extends JpaRepository<Teacher, UUID> {

    Optional<Teacher> findByRfc(String rfc);

    Optional<Teacher> findByCurp(String curp);

    Optional<Teacher> findByEmployeeNumber(String employeeNumber);

    Optional<Teacher> findByUserId(UUID userId);

    boolean existsByRfc(String rfc);

    boolean existsByCurp(String curp);
}
