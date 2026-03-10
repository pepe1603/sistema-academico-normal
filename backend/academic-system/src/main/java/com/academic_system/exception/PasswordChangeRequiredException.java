package com.academic_system.exception;

import org.springframework.security.core.AuthenticationException;

public class PasswordChangeRequiredException extends AuthenticationException {
    public PasswordChangeRequiredException(String message) {
        super(message);
    }
}
