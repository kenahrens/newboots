package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;

/**
 * Reactive API helper using WebClient (Reactor Netty) to call external APIs.
 */
@Component
public class ReactiveApiHelper {
    /** Logger for this class. */
    private static final Logger LOGGER = LoggerFactory.getLogger(ReactiveApiHelper.class);

    /** Hugging Face Models API URI for OpenAI models. */
    private static final String HUGGINGFACE_API_URI = 
        "https://huggingface.co/api/models?author=openai&limit=10";

    /** WebClient instance using Reactor Netty. */
    private final WebClient webClient;

    /**
     * Constructor that creates WebClient instance.
     */
    public ReactiveApiHelper() {
        this.webClient = WebClient.builder()
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1024))
            .build();
    }

    /**
     * Makes a reactive API call to Hugging Face to get OpenAI models.
     *
     * @return Mono containing the API response as String
     */
    public Mono<String> getOpenAiModels() {
        LOGGER.info("Making reactive API call to Hugging Face for OpenAI models");
        
        return webClient.get()
            .uri(HUGGINGFACE_API_URI)
            .retrieve()
            .bodyToMono(String.class)
            .timeout(Duration.ofSeconds(10))
            .doOnSuccess(response -> LOGGER.info("Successfully retrieved OpenAI models from Hugging Face"))
            .doOnError(error -> LOGGER.error("Error calling Hugging Face API", error));
    }
}