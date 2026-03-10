package com.academic_system.repository;

import com.academic_system.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface StudentRepository extends JpaRepository<Student, UUID> {

    Optional<Student> findByCurp(String curp);

    Optional<Student> findByEnrollmentNumber(String enrollmentNumber);

    Optional<Student> findByUserId(UUID userId);

    boolean existsByCurp(String curp);

    boolean existsByEnrollmentNumber(String enrollmentNumber);
}
