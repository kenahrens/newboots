package com.speedscale.newboots;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class NasaRateLimiterTest {

  @Test
  void testRateLimiter() {
    NasaRateLimiter rateLimiter = new NasaRateLimiter();

    // First call should succeed
    assertTrue(rateLimiter.tryConsume(), "First call should succeed");
    assertEquals(
        0, rateLimiter.getAvailableTokens(), "No tokens should be available after first call");

    // Second immediate call should fail
    assertFalse(rateLimiter.tryConsume(), "Second immediate call should fail due to rate limit");
    assertEquals(0, rateLimiter.getAvailableTokens(), "Still no tokens should be available");
  }
}
