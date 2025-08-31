package com.speedscale.newboots;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.client.reactive.ClientHttpConnector;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

/** Reactive API helper using WebClient (Reactor Netty) to call external APIs. */
@Component
public class ReactiveApiHelper {
  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(ReactiveApiHelper.class);

  /**
   * Base URL for Hugging Face API, overrideable via env var HF_API_BASE. Defaults to
   * https://huggingface.co
   */
  private static final String HF_API_BASE =
      System.getenv("HF_API_BASE") != null
          ? System.getenv("HF_API_BASE")
          : "https://huggingface.co";

  /** Host header to use for Hugging Face requests (for reverse proxy scenarios). */
  private static final String HF_HOST =
      System.getenv("HF_API_HOST") != null ? System.getenv("HF_API_HOST") : "huggingface.co";

  /** Hugging Face Models API URI for OpenAI models. */
  private static final String HUGGINGFACE_API_URI =
      HF_API_BASE + "/api/models?author=openai&limit=10";

  /**
   * Base URL for Numbers API, overrideable via env var NUMBERS_API_BASE. Defaults to
   * http://numbersapi.com
   */
  private static final String NUMBERS_API_BASE =
      System.getenv("NUMBERS_API_BASE") != null
          ? System.getenv("NUMBERS_API_BASE")
          : "http://numbersapi.com";

  /**
   * Base URL for JSONPlaceholder API (HTTPS test), can be overridden by environment variable.
   * https://jsonplaceholder.typicode.com
   */
  private static final String JSON_API_BASE =
      System.getenv("JSON_API_BASE") != null
          ? System.getenv("JSON_API_BASE")
          : "https://jsonplaceholder.typicode.com";


  /** WebClient instance using Reactor Netty. */
  private final WebClient webClient;

  /** Constructor that creates WebClient instance. */
  public ReactiveApiHelper() {
    // Configure Reactor Netty HttpClient based on target
    // For localhost connections (reverse proxy), bypass proxy settings
    // For other connections, honor system proxy properties
    HttpClient httpClient;
    if (HF_API_BASE.contains("localhost") || NUMBERS_API_BASE.contains("localhost") || JSON_API_BASE.contains("localhost")) {
      // Bypass proxy for localhost connections (reverse proxy scenario)
      httpClient = HttpClient.create();
    } else {
      // Use system proxy properties for external connections
      httpClient = HttpClient.create().proxyWithSystemProperties();
    }

    ClientHttpConnector connector = new ReactorClientHttpConnector(httpClient);

    this.webClient =
        WebClient.builder()
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
    LOGGER.info(
        "Making reactive API call to Hugging Face for OpenAI models (base: {})", HF_API_BASE);

    return webClient
        .get()
        .uri(HUGGINGFACE_API_URI)
        .header("Host", HF_HOST)
        .retrieve()
        .bodyToMono(String.class)
        .timeout(Duration.ofSeconds(10))
        .doOnSuccess(
            response -> LOGGER.info("Successfully retrieved OpenAI models from Hugging Face"))
        .doOnError(error -> LOGGER.error("Error calling Hugging Face API", error));
  }

  /**
   * Makes a reactive API call to Numbers API to get a random number fact.
   *
   * @return Mono containing the API response as String
   */
  public Mono<String> getRandomNumberFact() {
    String url = NUMBERS_API_BASE + "/random/trivia";
    LOGGER.info(
        "Making reactive API call to Numbers API for random fact (base: {})", NUMBERS_API_BASE);

    return webClient
        .get()
        .uri(url)
        .retrieve()
        .bodyToMono(String.class)
        .timeout(Duration.ofSeconds(10))
        .doOnSuccess(response -> LOGGER.info("Successfully retrieved number fact from Numbers API"))
        .doOnError(error -> LOGGER.error("Error calling Numbers API", error));
  }

  /**
   * Makes a reactive API call to JSONPlaceholder to get a test post (HTTPS test).
   *
   * @return Mono containing the API response as String
   */
  public Mono<String> getJsonPlaceholderPost() {
    String url = JSON_API_BASE + "/posts/1";
    LOGGER.info(
        "Making reactive API call to JSONPlaceholder for test post (base: {})", JSON_API_BASE);

    return webClient
        .get()
        .uri(url)
        .retrieve()
        .bodyToMono(String.class)
        .timeout(Duration.ofSeconds(10))
        .doOnSuccess(response -> LOGGER.info("Successfully retrieved post from JSONPlaceholder"))
        .doOnError(error -> LOGGER.error("Error calling JSONPlaceholder API", error));
  }
}
