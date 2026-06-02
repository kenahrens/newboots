package com.speedscale.newboots;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ContextConfiguration;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ContextConfiguration(classes = NewbootsApplication.class)
public class ZipEndpointIntegrationTest {

  @LocalServerPort private int port;

  @Autowired private TestRestTemplate restTemplate;

  @Test
  public void testZipEndpointDefault() {
    String url = "http://localhost:" + port + "/zip";
    ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
    assertEquals(200, response.getStatusCode().value());
    String body = response.getBody();
    assertNotNull(body);
    assertTrue(body.contains("totalFiles"), "Response should contain 'totalFiles'");
    assertTrue(body.contains("files"), "Response should contain 'files'");
  }

  @Test
  public void testZipEndpointWithFilename() {
    String url = "http://localhost:" + port + "/zip?filename=jquery";
    ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
    assertEquals(200, response.getStatusCode().value());
    String body = response.getBody();
    assertNotNull(body);
    assertTrue(body.contains("totalFiles"), "Response should contain 'totalFiles'");
    assertTrue(body.contains("files"), "Response should contain 'files'");
  }

  @Test
  public void testServeZipDefaultSize() {
    String url = "http://localhost:" + port + "/zip/serve";
    ResponseEntity<byte[]> response = restTemplate.getForEntity(url, byte[].class);
    assertEquals(200, response.getStatusCode().value());
    byte[] body = response.getBody();
    assertNotNull(body);
    // ZIP magic bytes PK\x03\x04
    assertEquals((byte) 0x50, body[0]);
    assertEquals((byte) 0x4B, body[1]);
    assertEquals((byte) 0x03, body[2]);
    assertEquals((byte) 0x04, body[3]);
    // Default is 3 MB payload — ZIP overhead is small so total should be 3MB+
    assertTrue(body.length >= 3 * 1024 * 1024, "ZIP should be at least 3 MB");
  }

  @Test
  public void testServeZipCustomSize() {
    String url = "http://localhost:" + port + "/zip/serve?size=5";
    ResponseEntity<byte[]> response = restTemplate.getForEntity(url, byte[].class);
    assertEquals(200, response.getStatusCode().value());
    byte[] body = response.getBody();
    assertNotNull(body);
    assertTrue(body.length >= 5 * 1024 * 1024, "ZIP should be at least 5 MB");
  }

  @Test
  public void testServeZipContentTypeHeader() {
    String url = "http://localhost:" + port + "/zip/serve";
    ResponseEntity<byte[]> response = restTemplate.getForEntity(url, byte[].class);
    assertEquals(200, response.getStatusCode().value());
    String contentType = response.getHeaders().getFirst("Content-Type");
    assertNotNull(contentType);
    assertTrue(contentType.contains("application/zip"), "Content-Type should be application/zip");
  }
}
