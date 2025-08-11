package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.http.client.reactive.ClientHttpConnector;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import reactor.netty.http.client.HttpClient;
import reactor.core.publisher.Mono;

import java.time.Duration;

/**
 * Reactive API helper using WebClient (Reactor Netty) to call external APIs.
 */
@Component
public class ReactiveApiHelper {
    /** Logger for this class. */
    private static final Logger LOGGER = LoggerFactory.getLogger(ReactiveApiHelper.class);

    /**
     * Base URL for Hugging Face API, overrideable via env var HF_API_BASE.
     * Defaults to https://huggingface.co
     */
    private static final String HF_API_BASE =
        System.getenv("HF_API_BASE") != null
            ? System.getenv("HF_API_BASE")
            : "https://huggingface.co";

    /** Host header to use for Hugging Face requests (for reverse proxy scenarios). */
    private static final String HF_HOST =
        System.getenv("HF_API_HOST") != null
            ? System.getenv("HF_API_HOST")
            : "huggingface.co";

    /** Hugging Face Models API URI for OpenAI models. */
    private static final String HUGGINGFACE_API_URI =
        HF_API_BASE + "/api/models?author=openai&limit=10";

    /** WebClient instance using Reactor Netty. */
    private final WebClient webClient;

    /**
     * Constructor that creates WebClient instance.
     */
    public ReactiveApiHelper() {
        // Configure Reactor Netty HttpClient to honor JVM/system proxy properties when set
        HttpClient httpClient = HttpClient.create().proxyWithSystemProperties();
        ClientHttpConnector connector = new ReactorClientHttpConnector(httpClient);

        this.webClient = WebClient.builder()
            .clientConnector(connector)
            .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(1024 * 1024))
            .build();
    }

    /**
     * Makes a reactive API call to Hugging Face to get OpenAI models.
     *
     * @return Mono containing the API response as String
     */
    public Mono<String> getOpenAiModels() {
        LOGGER.info("Making reactive API call to Hugging Face for OpenAI models (base: {})", HF_API_BASE);
        
        return webClient.get()
            .uri(HUGGINGFACE_API_URI)
            .header("Host", HF_HOST)
            .retrieve()
            .bodyToMono(String.class)
            .timeout(Duration.ofSeconds(10))
            .doOnSuccess(response -> LOGGER.info("Successfully retrieved OpenAI models from Hugging Face"))
            .doOnError(error -> LOGGER.error("Error calling Hugging Face API", error));
    }
}
