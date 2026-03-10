package com.academic_system.service;

import com.academic_system.dto.auth.RegisterRequest;
import com.academic_system.entity.Role;
import com.academic_system.entity.Student;
import com.academic_system.entity.Teacher;
import com.academic_system.entity.User;
import com.academic_system.repository.RoleRepository;
import com.academic_system.repository.StudentRepository;
import com.academic_system.repository.TeacherRepository;
import com.academic_system.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserRegistrationService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @Transactional
    public User register(RegisterRequest request) {
        // Validar que las contraseñas coincidan
        if (!request.isPasswordMatch()) {
            throw new IllegalArgumentException("Las contraseñas no coinciden");
        }

        // Validar que el username no exista
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("El username ya está en uso");
        }

        // Validar que el email no exista
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("El email ya está en uso");
        }

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .isActive(true)
                .isLocked(false)
                .isDeleted(false)
                .failedAttempts(0)
                .mustChangePassword(false)
                .build();

        // Determinar el rol según el tipo de registro
        Role defaultRole = determineRole(request.getType());
        user.setRoles(Set.of(defaultRole));

        user = userRepository.save(user);

        // Vincular con Student o Teacher según corresponda
        linkWithPerson(request, user);

        // Enviar email de bienvenida
        emailService.sendWelcomeEmail(user.getEmail(), user.getUsername());

        return user;
    }

    @Transactional
    public User createUserByAdmin(String username, String email, String temporaryPassword, 
                                   RegisterRequest.RegisterType type, String identifier) {
        // Validar que el username no exista
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("El username ya está en uso");
        }

        // Validar que el email no existe
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("El email ya está en uso");
        }

        User user = User.builder()
                .username(username)
                .email(email)
                .passwordHash(passwordEncoder.encode(temporaryPassword))
                .isActive(true)
                .isLocked(false)
                .isDeleted(false)
                .failedAttempts(0)
                .mustChangePassword(true) // FORZAR cambio de contraseña
                .build();

        Role role = determineRole(type);
        user.setRoles(Set.of(role));

        user = userRepository.save(user);

        // Enviar email con contraseña temporal
        emailService.sendPasswordRecoveryEmail(email, "Tu contraseña temporal es: " + temporaryPassword + 
                ". Por favor, inicia sesión y cámbiala inmediatamente.");

        return user;
    }

    private Role determineRole(RegisterRequest.RegisterType type) {
        String roleName;
        
        switch (type) {
            case STUDENT:
                roleName = "STUDENT";
                break;
            case TEACHER:
                roleName = "TEACHER";
                break;
            case GENERAL:
            default:
                roleName = "STUDENT"; // Por defecto
                break;
        }

        return roleRepository.findByName(roleName)
                .orElseThrow(() -> new IllegalArgumentException("Rol no encontrado: " + roleName));
    }

    private void linkWithPerson(RegisterRequest request, User user) {
        switch (request.getType()) {
            case STUDENT:
                linkWithStudent(request, user);
                break;
            case TEACHER:
                linkWithTeacher(request, user);
                break;
            case GENERAL:
                // No se vincula con ninguna persona
                break;
        }
    }

    private void linkWithStudent(RegisterRequest request, User user) {
        Student student = null;

        // Buscar por CURP o número de inscripción
        if (request.getCurp() != null && !request.getCurp().isEmpty()) {
            student = studentRepository.findByCurp(request.getCurp()).orElse(null);
        }
        
        if (student == null && request.getEnrollmentNumber() != null && !request.getEnrollmentNumber().isEmpty()) {
            student = studentRepository.findByEnrollmentNumber(request.getEnrollmentNumber()).orElse(null);
        }

        if (student != null) {
            // Verificar que no tenga usuario vinculado
            if (student.getUserId() != null) {
                throw new IllegalArgumentException("Esta información ya está vinculada a otra cuenta");
            }

            student.setUserId(user.getId());
            studentRepository.save(student);
        }
    }

    private void linkWithTeacher(RegisterRequest request, User user) {
        Teacher teacher = null;

        // Buscar por RFC o CURP
        if (request.getRfc() != null && !request.getRfc().isEmpty()) {
            teacher = teacherRepository.findByRfc(request.getRfc()).orElse(null);
        }

        if (teacher == null && request.getCurp() != null && !request.getCurp().isEmpty()) {
            teacher = teacherRepository.findByCurp(request.getCurp()).orElse(null);
        }

        if (teacher != null) {
            // Verificar que no tenga usuario vinculado
            if (teacher.getUserId() != null) {
                throw new IllegalArgumentException("Esta información ya está vinculada a otra cuenta");
            }

            teacher.setUserId(user.getId());
            teacherRepository.save(teacher);
        }
    }
}
