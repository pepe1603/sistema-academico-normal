package com.academic_system.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Async
    public void sendPasswordRecoveryEmail(String toEmail, String token) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Recuperación de Contraseña - Sistema Académico");
            message.setText(
                "Hola,\n\n" +
                "Has solicitado recuperar tu contraseña.\n\n" +
                "Tu código de recuperación es: " + token + "\n\n" +
                "Este código expira en 24 horas.\n\n" +
                "Si no solicitaste esto, por favor ignora este correo.\n\n" +
                "Saludos,\n" +
                "Sistema Académico"
            );
            
            mailSender.send(message);
            log.info("Email de recuperación enviado a: {}", toEmail);
        } catch (Exception e) {
            log.error("Error al enviar email de recuperación: {}", e.getMessage());
        }
    }

    @Async
    public void sendPasswordChangedNotification(String toEmail) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Contraseña Modificada - Sistema Académico");
            message.setText(
                "Hola,\n\n" +
                "Tu contraseña ha sido modificada exitosamente.\n\n" +
                "Si no realizaste este cambio, contacta al administrador inmediatamente.\n\n" +
                "Saludos,\n" +
                "Sistema Académico"
            );
            
            mailSender.send(message);
            log.info("Notificación de cambio de contraseña enviada a: {}", toEmail);
        } catch (Exception e) {
            log.error("Error al enviar notificación: {}", e.getMessage());
        }
    }

    @Async
    public void sendWelcomeEmail(String toEmail, String username) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Bienvenido al Sistema Académico");
            message.setText(
                "Hola " + username + ",\n\n" +
                "Tu cuenta ha sido creada exitosamente.\n\n" +
                "Por favor, inicia sesión y cambia tu contraseña.\n\n" +
                "Saludos,\n" +
                "Sistema Académico"
            );
            
            mailSender.send(message);
            log.info("Email de bienvenida enviado a: {}", toEmail);
        } catch (Exception e) {
            log.error("Error al enviar email de bienvenida: {}", e.getMessage());
        }
    }

    @Async
    public void sendTwoFactorEnabledNotification(String toEmail) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("2FA Habilitado - Sistema Académico");
            message.setText(
                "Hola,\n\n" +
                "La autenticación de dos factores ha sido habilitada en tu cuenta.\n\n" +
                "Guarda tus códigos de respaldo en un lugar seguro.\n\n" +
                "Si no realizaste este cambio, contacta al administrador inmediatamente.\n\n" +
                "Saludos,\n" +
                "Sistema Académico"
            );
            
            mailSender.send(message);
        } catch (Exception e) {
            log.error("Error al enviar notificación 2FA: {}", e.getMessage());
        }
    }

    @Async
    public void sendAccountLockedNotification(String toEmail) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Cuenta Bloqueada - Sistema Académico");
            message.setText(
                "Hola,\n\n" +
                "Tu cuenta ha sido bloqueada debido a múltiples intentos de inicio de sesión fallidos.\n\n" +
                "Por favor, contacta al administrador para desbloquear tu cuenta.\n\n" +
                "Saludos,\n" +
                "Sistema Académico"
            );
            
            mailSender.send(message);
        } catch (Exception e) {
            log.error("Error al enviar notificación de bloqueo: {}", e.getMessage());
        }
    }
}
