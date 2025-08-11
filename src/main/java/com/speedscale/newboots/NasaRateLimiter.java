package com.speedscale.newboots;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Rate limiter for NASA API calls.
 * Ensures we stay under 10 calls per hour (1 call per 10 minutes).
 */
@Component
public class NasaRateLimiter {
    private final Bucket bucket;

    public NasaRateLimiter() {
        Bandwidth limit = Bandwidth.classic(
            1,  // capacity: 1 token
            Refill.intervally(1, Duration.ofMinutes(10))  // refill 1 token every 10 minutes
        );
        this.bucket = Bucket.builder()
            .addLimit(limit)
            .build();
    }

    /**
     * Try to consume a token from the bucket.
     * @return true if a token was consumed, false if rate limit exceeded
     */
    public boolean tryConsume() {
        return bucket.tryConsume(1);
    }

    /**
     * Get the remaining number of tokens.
     * @return the number of available tokens
     */
    public long getAvailableTokens() {
        return bucket.getAvailableTokens();
    }
}