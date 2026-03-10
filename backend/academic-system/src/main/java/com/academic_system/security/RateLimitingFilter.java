package com.academic_system.security;

import io.github.bucket4j.Bucket;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.function.Supplier;

@Component
@RequiredArgsConstructor
public class RateLimitingFilter implements Filter {

    private final Supplier<Bucket> defaultBucketSupplier;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = httpRequest.getRequestURI();

        // Solo aplicar rate limiting a APIs
        if (path.startsWith("/api/")) {
            Bucket bucket = defaultBucketSupplier.get();

            if (bucket.tryConsume(1)) {
                // Agregar headers de rate limiting
                httpResponse.setHeader("X-Rate-Limit-Remaining", String.valueOf(bucket.getAvailableTokens()));
                chain.doFilter(request, response);
            } else {
                httpResponse.setStatus(429);
                httpResponse.setContentType("application/json");
                httpResponse.getWriter().write(
                    "{\"error\": \"Too many requests. Please try again later.\", \"code\": \"RATE_LIMIT_EXCEEDED\"}"
                );
            }
        } else {
            chain.doFilter(request, response);
        }
    }
}
