package com.speedscale.newboots;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.zip.ZipFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;
import reactor.netty.resources.ConnectionProvider;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import io.netty.handler.ssl.util.InsecureTrustManagerFactory;
import javax.net.ssl.TrustManagerFactory;
import java.security.KeyStore;
import java.io.FileInputStream;

/**
 * Utility class for handling ZIP file operations. This class provides methods to download and
 * analyze ZIP files.
 */
public final class ZipHelper {

  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(ZipHelper.class);

  /** Lazy-initialized WebClient for ZIP downloads. */
  private static volatile WebClient webClient;

  /** Predefined ZIP file URLs for reliable access. */
  private static final Map<String, String> ZIP_URLS = new HashMap<>();

  static {
    ZIP_URLS.put(
        "speedscale", "https://github.com/speedscale/speedscale/archive/refs/heads/main.zip");
    ZIP_URLS.put("jquery", "https://github.com/jquery/jquery/archive/refs/heads/main.zip");
    ZIP_URLS.put("bootstrap", "https://github.com/twbs/bootstrap/archive/refs/heads/main.zip");
    // Add more predefined ZIP files as needed
  }

  /** Private constructor to prevent instantiation of utility class. */
  private ZipHelper() {
    // Utility class - prevent instantiation
  }

  /**
   * Gets or creates a WebClient with custom connection settings for ZIP downloads.
   *
   * @return configured WebClient instance
   */
  private static WebClient getWebClient() {
    if (webClient == null) {
      synchronized (ZipHelper.class) {
        if (webClient == null) {
          webClient = createWebClient();
        }
      }
    }
    return webClient;
  }

  /**
   * Creates a WebClient with custom connection settings for ZIP downloads.
   *
   * @return configured WebClient instance
   */
  private static WebClient createWebClient() {
    // Create connection provider with larger buffer for ZIP files
    ConnectionProvider connectionProvider = ConnectionProvider.builder("zip-http")
        .maxConnections(10)
        .pendingAcquireTimeout(Duration.ofSeconds(60))
        .build();

    // Create HttpClient with custom settings and SSL configuration
    HttpClient httpClient = HttpClient.create(connectionProvider)
        .responseTimeout(Duration.ofSeconds(120)) // 2 minutes for large ZIP files
        .followRedirect(true) // Follow GitHub redirects
        .secure(sslSpec -> sslSpec.sslContext(createSslContext()));

    return WebClient.builder()
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .codecs(configurer -> configurer
            .defaultCodecs()
            .maxInMemorySize(50 * 1024 * 1024)) // 50MB buffer for ZIP files
        .build();
  }

  /**
   * Creates an SSL context that uses the JVM trust store or proxymock certificates.
   *
   * @return configured SSL context
   */
  private static SslContext createSslContext() {
    try {
      // Check if custom trust store is configured via system properties
      String trustStorePath = System.getProperty("javax.net.ssl.trustStore");
      String trustStorePassword = System.getProperty("javax.net.ssl.trustStorePassword");
      
      LOGGER.info("SSL context creation - trustStorePath: {}, trustStorePassword: {}", 
          trustStorePath, trustStorePassword != null ? "[REDACTED]" : null);
      
      if (trustStorePath != null && !trustStorePath.isEmpty()) {
        // Use custom trust store (proxymock certificates)
        LOGGER.info("Using custom trust store: {}", trustStorePath);
        
        KeyStore trustStore = KeyStore.getInstance("JKS");
        try (FileInputStream fis = new FileInputStream(trustStorePath)) {
          trustStore.load(fis, trustStorePassword != null ? trustStorePassword.toCharArray() : null);
        }
        
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(trustStore);
        
        return SslContextBuilder.forClient()
            .trustManager(tmf)
            .build();
      } else {
        // Use default system trust store
        LOGGER.info("Using default system trust store");
        return SslContextBuilder.forClient().build();
      }
      
    } catch (Exception e) {
      LOGGER.warn("Failed to configure custom SSL context, falling back to insecure trust manager: {}", e.getMessage());
      // Fallback to insecure trust manager for development/testing
      try {
        return SslContextBuilder.forClient()
            .trustManager(InsecureTrustManagerFactory.INSTANCE)
            .build();
      } catch (Exception fallbackException) {
        throw new RuntimeException("Failed to create SSL context", fallbackException);
      }
    }
  }

  /**
   * Backward compatibility method that invokes with null filename.
   *
   * @return JSON string containing ZIP file information
   * @throws Exception if an error occurs during processing
   */
  public static String invoke() throws Exception {
    return invoke(null);
  }

  /**
   * Downloads and processes a ZIP file, returning its contents as JSON.
   *
   * @param filename the filename to process, or null for default
   * @return JSON string containing ZIP file information
   * @throws Exception if an error occurs during processing
   */
  public static String invoke(final String filename) throws Exception {

    String body = "{}";
    String requestId = String.valueOf(System.currentTimeMillis());

    try {
      // Build the zip URL based on the provided filename or use default
      String zipUrl;
      if (filename != null && !filename.trim().isEmpty()) {
        // Check if it's a predefined filename
        if (ZIP_URLS.containsKey(filename.toLowerCase())) {
          zipUrl = resolveZipUrl(ZIP_URLS.get(filename.toLowerCase()));
          LOGGER.info("[{}] Processing predefined ZIP file: {}", requestId, filename);
        } else {
          // Fallback to learningcontainer pattern for backward compatibility
          String learningBase =
              getEnvOrDefault(
                  "ZIP_LEARNING_BASE", "https://www.learningcontainer.com/wp-content/uploads/2020/05/");
          zipUrl = buildUrlFromBase(learningBase, filename);
          LOGGER.info("[{}] Processing custom ZIP file (may not exist): {}", requestId, filename);
        }
      } else {
        // Use default speedscale zip file
        zipUrl = resolveZipUrl(ZIP_URLS.get("speedscale"));
        LOGGER.info("[{}] Processing default ZIP file (speedscale)", requestId);
      }

      LOGGER.info("[{}] REQ zip download: {}", requestId, zipUrl);

      // Download ZIP file using WebClient
      byte[] zipBytes = downloadZipFile(zipUrl, requestId);
      
      if (zipBytes != null) {
        // Parse the zip file and get the index
        List<ZipFileInfo> zipIndex = getZipIndex(zipBytes);
        
        // Convert to JSON
        body = convertToJson(zipIndex);
      } else {
        body = String.format(
            "{\"error\": \"Failed to download ZIP file\", \"url\": \"%s\"}", 
            zipUrl);
      }

    } catch (Exception e) {
      LOGGER.error("[{}] Unable to download and process zip file", requestId, e);
      throw e;
    }

    return body;
  }

  /**
   * Downloads a ZIP file from the given URL using WebClient.
   *
   * @param url the URL to download from
   * @param requestId the request ID for logging
   * @return byte array of the ZIP file content, or null if download failed
   */
  private static byte[] downloadZipFile(final String url, final String requestId) {
    try {
      Mono<byte[]> response = getWebClient()
          .get()
          .uri(url)
          .accept(MediaType.APPLICATION_OCTET_STREAM)
          .retrieve()
          .bodyToMono(byte[].class)
          .doOnSuccess(data -> LOGGER.info("[{}] RES zip download: SUCCESS, size: {} bytes", 
              requestId, data != null ? data.length : 0))
          .doOnError(error -> LOGGER.error("[{}] RES zip download: FAILED - {}", 
              requestId, error.getMessage()));

      // Block and wait for the response (up to 2 minutes)
      return response.block(Duration.ofMinutes(2));
    } catch (Exception e) {
      LOGGER.error("[{}] Error downloading ZIP file from URL: {}", requestId, url, e);
      return null;
    }
  }

  private static String resolveZipUrl(final String rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty()) {
      return rawUrl;
    }

    try {
      URI original = new URI(rawUrl);
      if (original.getHost() == null) {
        return rawUrl;
      }

      String base =
          getOverrideBase(original.getHost(), original.getScheme() + "://" + original.getHost());
      if (base.equals(original.getScheme() + "://" + original.getHost())) {
        return rawUrl;
      }

      URI baseUri = new URI(base);
      String combinedPath = combinePaths(baseUri.getPath(), original.getPath());

      return new URI(
              baseUri.getScheme(),
              baseUri.getUserInfo(),
              baseUri.getHost(),
              baseUri.getPort(),
              combinedPath,
              original.getQuery(),
              original.getFragment())
          .toString();

    } catch (URISyntaxException e) {
      throw new IllegalArgumentException("Invalid ZIP URL: " + rawUrl, e);
    }
  }

  private static String buildUrlFromBase(final String base, final String suffix) {
    if (base == null || base.isEmpty()) {
      return suffix;
    }

    try {
      URI baseUri = new URI(base);
      String combinedPath = combinePaths(baseUri.getPath(), suffix);
      return new URI(
              baseUri.getScheme(),
              baseUri.getUserInfo(),
              baseUri.getHost(),
              baseUri.getPort(),
              combinedPath,
              null,
              null)
          .toString();
    } catch (URISyntaxException e) {
      throw new IllegalArgumentException("Invalid ZIP base URL: " + base, e);
    }
  }

  private static String combinePaths(final String basePath, final String resourcePath) {
    String normalizedBase = Optional.ofNullable(basePath).orElse("");
    String normalizedResource = Optional.ofNullable(resourcePath).orElse("");

    if (!normalizedBase.isEmpty() && !normalizedBase.endsWith("/")) {
      normalizedBase = normalizedBase + "/";
    }

    if (normalizedResource.startsWith("/")) {
      normalizedResource = normalizedResource.substring(1);
    }

    String combined = normalizedBase + normalizedResource;
    if (combined.isEmpty()) {
      return "/";
    }

    return combined.startsWith("/") ? combined : "/" + combined;
  }

  private static String getOverrideBase(final String host, final String defaultBase) {
    String envKey;
    switch (host) {
      case "github.com":
        envKey = "ZIP_GITHUB_BASE";
        break;
      case "codeload.github.com":
        envKey = "ZIP_CODELOAD_BASE";
        break;
      case "www.learningcontainer.com":
      case "learningcontainer.com":
        envKey = "ZIP_LEARNING_BASE";
        break;
      default:
        return defaultBase;
    }

    return getEnvOrDefault(envKey, defaultBase);
  }

  private static String getEnvOrDefault(final String key, final String defaultValue) {
    String value = System.getenv(key);
    return value == null || value.trim().isEmpty() ? defaultValue : value.trim();
  }

  /**
   * Extracts file information from a ZIP file.
   *
   * @param zipBytes the ZIP file as byte array
   * @return list of ZIP file information
   * @throws IOException if an I/O error occurs
   */
  private static List<ZipFileInfo> getZipIndex(final byte[] zipBytes) throws IOException {

    List<ZipFileInfo> index = new ArrayList<>();

    // Create a temporary file to work with ZipFile
    File tempFile = File.createTempFile("ziphelper", ".zip");
    try {
      // Write bytes to temporary file
      try (FileOutputStream fos = new FileOutputStream(tempFile)) {
        fos.write(zipBytes);
      }

      // Use ZipFile to read central directory which has accurate size
      try (ZipFile zipFile = new ZipFile(tempFile)) {
        zipFile.stream()
            .forEach(
                entry -> {
                  ZipFileInfo fileInfo = new ZipFileInfo();
                  fileInfo.setName(entry.getName());
                  fileInfo.setSize(entry.getSize());
                  fileInfo.setCompressedSize(entry.getCompressedSize());
                  fileInfo.setDirectory(entry.isDirectory());
                  fileInfo.setLastModified(entry.getTime());
                  index.add(fileInfo);
                });
      }
    } finally {
      // Clean up temporary file
      Files.deleteIfExists(tempFile.toPath());
    }

    return index;
  }

  /**
   * Converts ZIP file information to JSON format.
   *
   * @param zipIndex list of ZIP file information
   * @return JSON string representation
   * @throws Exception if JSON conversion fails
   */
  private static String convertToJson(final List<ZipFileInfo> zipIndex) throws Exception {

    ObjectMapper mapper = new ObjectMapper();
    ObjectNode rootNode = mapper.createObjectNode();
    ArrayNode filesArray = mapper.createArrayNode();

    for (ZipFileInfo fileInfo : zipIndex) {
      ObjectNode fileNode = mapper.createObjectNode();
      fileNode.put("name", fileInfo.getName());
      fileNode.put("size", fileInfo.getSize());
      fileNode.put("compressedSize", fileInfo.getCompressedSize());
      fileNode.put("isDirectory", fileInfo.isDirectory());
      fileNode.put("lastModified", fileInfo.getLastModified());
      filesArray.add(fileNode);
    }

    rootNode.put("totalFiles", zipIndex.size());
    rootNode.set("files", filesArray);

    return mapper.writeValueAsString(rootNode);
  }

  /** Inner class to hold ZIP file information. */
  private static class ZipFileInfo {
    /** The name of the file in the ZIP. */
    private String name;

    /** The uncompressed size of the file. */
    private long size;

    /** The compressed size of the file. */
    private long compressedSize;

    /** Whether the entry is a directory. */
    private boolean isDirectory;

    /** The last modified time of the file. */
    private long lastModified;

    /**
     * Gets the file name.
     *
     * @return the file name
     */
    public String getName() {
      return name;
    }

    /**
     * Sets the file name.
     *
     * @param fileName the file name to set
     */
    public void setName(final String fileName) {
      this.name = fileName;
    }

    /**
     * Gets the file size.
     *
     * @return the file size
     */
    public long getSize() {
      return size;
    }

    /**
     * Sets the file size.
     *
     * @param fileSize the file size to set
     */
    public void setSize(final long fileSize) {
      this.size = fileSize;
    }

    /**
     * Gets the compressed size.
     *
     * @return the compressed size
     */
    public long getCompressedSize() {
      return compressedSize;
    }

    /**
     * Sets the compressed size.
     *
     * @param compressed the compressed size to set
     */
    public void setCompressedSize(final long compressed) {
      this.compressedSize = compressed;
    }

    /**
     * Checks if the entry is a directory.
     *
     * @return true if directory, false otherwise
     */
    public boolean isDirectory() {
      return isDirectory;
    }

    /**
     * Sets whether the entry is a directory.
     *
     * @param directory true if directory, false otherwise
     */
    public void setDirectory(final boolean directory) {
      isDirectory = directory;
    }

    /**
     * Gets the last modified time.
     *
     * @return the last modified time
     */
    public long getLastModified() {
      return lastModified;
    }

    /**
     * Sets the last modified time.
     *
     * @param modified the last modified time to set
     */
    public void setLastModified(final long modified) {
      this.lastModified = modified;
    }
  }
}