package com.speedscale.newboots;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class HttpClientRunner {
    private static final String BASE_URL = "http://newboots:8080";
    private static final int DELAY_MS = 2000;

    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        String[] endpoints = {
            "/", // Home
            "/healthz",
            "/greeting?name=TestUser",
            "/nasa",
            "/spacex",
            "/zip",
            "/zip?filename=jquery",
            "/number-to-words?number=123"
        };
        int cycle = 1;
        while (true) {
            System.out.println("\n--- Starting cycle " + cycle + " ---");
            for (String endpoint : endpoints) {
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(BASE_URL + endpoint))
                        .timeout(Duration.ofSeconds(10))
                        .header("Accept", "application/json")
                        .GET()
                        .build();
                System.out.println("Calling: " + endpoint);
                try {
                    HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                    System.out.println("Response: " + response.statusCode() + "\n" + response.body());
                } catch (Exception e) {
                    System.out.println("Error calling " + endpoint + ": " + e.getMessage());
                }
                Thread.sleep(DELAY_MS);
            }
            // POST /location
            String locationJson = "{" +
                    "\"locationID\": \"loc-001\"," +
                    "\"latitude\": 37.7749," +
                    "\"longitude\": -122.4194," +
                    "\"macAddress\": \"00:1A:2B:3C:4D:5E\"," +
                    "\"ipv4\": \"192.168.1.1\"}";
            HttpRequest postRequest = HttpRequest.newBuilder()
                    .uri(URI.create(BASE_URL + "/location"))
                    .timeout(Duration.ofSeconds(10))
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(locationJson))
                    .build();
            System.out.println("Calling: POST /location");
            try {
                HttpResponse<String> response = client.send(postRequest, HttpResponse.BodyHandlers.ofString());
                System.out.println("Response: " + response.statusCode() + "\n" + response.body());
            } catch (Exception e) {
                System.out.println("Error calling POST /location: " + e.getMessage());
            }
            Thread.sleep(DELAY_MS);
            cycle++;
        }
    }
} 