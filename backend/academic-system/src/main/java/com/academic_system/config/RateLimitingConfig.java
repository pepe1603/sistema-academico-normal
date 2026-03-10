package com.academic_system.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;
import java.util.function.Supplier;

@Configuration
public class RateLimitingConfig {

    // Límite de intentos de login por IP
    @Bean
    public Supplier<Bucket> loginBucketSupplier() {
        return () -> Bucket.builder()
                .addLimit(Bandwidth.classic(10, Refill.greedy(10, Duration.ofMinutes(1))))
                .build();
    }

    // Límite de intentos de recuperación de contraseña
    @Bean
    public Supplier<Bucket> recoveryBucketSupplier() {
        return () -> Bucket.builder()
                .addLimit(Bandwidth.classic(3, Refill.greedy(3, Duration.ofMinutes(15))))
                .build();
    }

    // Límite general de requests
    @Bean
    public Supplier<Bucket> defaultBucketSupplier() {
        return () -> Bucket.builder()
                .addLimit(Bandwidth.classic(100, Refill.greedy(100, Duration.ofMinutes(1))))
                .addLimit(Bandwidth.classic(500, Refill.greedy(500, Duration.ofHours(1))))
                .build();
    }
}
