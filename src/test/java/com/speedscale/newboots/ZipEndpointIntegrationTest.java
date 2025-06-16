package com.speedscale.newboots;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ZipEndpointIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testZipEndpointDefault() {
        String url = "http://localhost:" + port + "/zip";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
        assertEquals(200, response.getStatusCodeValue());
        String body = response.getBody();
        assertNotNull(body);
        assertTrue(body.contains("totalFiles"), "Response should contain 'totalFiles'");
        assertTrue(body.contains("files"), "Response should contain 'files'");
    }

    @Test
    public void testZipEndpointWithFilename() {
        String url = "http://localhost:" + port + "/zip?filename=jquery";
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
        assertEquals(200, response.getStatusCodeValue());
        String body = response.getBody();
        assertNotNull(body);
        assertTrue(body.contains("totalFiles"), "Response should contain 'totalFiles'");
        assertTrue(body.contains("files"), "Response should contain 'files'");
    }
} 