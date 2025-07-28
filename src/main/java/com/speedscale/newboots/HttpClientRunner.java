package com.speedscale.newboots;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class for running HTTP client operations.
 */
public final class HttpClientRunner {
    /** Logger for this class. */
    private static final Logger LOGGER =
        LoggerFactory.getLogger(HttpClientRunner.class);
    /** Delay in milliseconds. */
    private static final int DELAY_MS = 2000;
    /** Default base URL. */
    private static final String DEFAULT_BASE_URL = "http://localhost:8080";
    /** Timeout in seconds for HTTP requests. */
    private static final int TIMEOUT_SECONDS = 10;

    /**
     * Private constructor to prevent instantiation.
     */
    private HttpClientRunner() {
        // Utility class
    }

    private static String getBaseUrl() {
        String envUrl = System.getenv("BASE_URL");
        return (envUrl != null && !envUrl.isEmpty())
            ? envUrl : DEFAULT_BASE_URL;
    }

    /**
     * Runs the HTTP client with the given arguments.
     *
     * @param args the arguments
     */
    public static void run(final String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        String baseUrl = getBaseUrl();
        String[] endpoints = {
            "/", // Home
            "/healthz",
            "/greeting?name=TestUser",
            "/nasa",
            "/spacex",
            "/zip",
            "/zip?filename=jquery",
            "/number-to-words?number=123",
            "/inventory/search?key=item&value=journal",
            "/inventory/search?key=qty&value=25",
            "/pets/types",
            "/pets/types?type=dog",
            "/pets/types?type=cat"
        };
        int cycle = 1;
        while (true) {
            System.out.println("\n--- Starting cycle " + cycle + " ---");
            for (String endpoint : endpoints) {
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(baseUrl + endpoint))
                        .timeout(Duration.ofSeconds(TIMEOUT_SECONDS))
                        .header("Accept", "application/json")
                        .GET()
                        .build();
                System.out.println("Calling: " + endpoint);
                try {
                    HttpResponse<String> response = client.send(
                        request, HttpResponse.BodyHandlers.ofString());
                    System.out.println("Response: " + response.statusCode()
                        + "\n" + response.body());
                } catch (Exception e) {
                    System.out.println("Error calling " + endpoint + ": " + e);
                    e.printStackTrace();
                }
                Thread.sleep(DELAY_MS);
            }
            // POST /location
            String locationJson = "{"
                + "\"locationID\": \"loc-001\","
                + "\"latitude\": 37.7749,"
                + "\"longitude\": -122.4194,"
                + "\"macAddress\": \"00:1A:2B:3C:4D:5E\","
                + "\"ipv4\": \"192.168.1.1\"}";
            HttpRequest postRequest = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/location"))
                    .timeout(Duration.ofSeconds(TIMEOUT_SECONDS))
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(locationJson))
                    .build();
            System.out.println("Calling: POST /location");
            try {
                HttpResponse<String> response = client.send(
                    postRequest, HttpResponse.BodyHandlers.ofString());
                System.out.println("Response: " + response.statusCode()
                    + "\n" + response.body());
            } catch (Exception e) {
                System.out.println("Error calling POST /location: " + e);
                e.printStackTrace();
            }
            Thread.sleep(DELAY_MS);
            cycle++;
        }
    }

    /**
     * Main entry point for Java application.
     * @param args the arguments
     */
    public static void main(String[] args) throws Exception {
        run(args);
    }
}
