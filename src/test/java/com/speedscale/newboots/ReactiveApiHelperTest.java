package com.speedscale.newboots;

import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

/**
 * Unit tests for ReactiveApiHelper.
 */
class ReactiveApiHelperTest {

    @Test
    void testGetOpenAiModels() {
        ReactiveApiHelper helper = new ReactiveApiHelper();
        
        Mono<String> result = helper.getOpenAiModels();
        
        StepVerifier.create(result)
            .expectNextMatches(response -> 
                response != null && (response.contains("openai") || response.contains("error")))
            .verifyComplete();
    }
}