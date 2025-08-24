package com.speedscale.newboots;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipFile;
import org.apache.commons.io.IOUtils;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.HttpEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class for handling ZIP file operations. This class provides methods to download and
 * analyze ZIP files.
 */
public final class ZipHelper {

  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(ZipHelper.class);

  /** HTTP status code for successful response. */
  private static final int HTTP_OK = 200;

  /** Shared HTTP client to avoid multiple connections. */
  private static final CloseableHttpClient HTTP_CLIENT = HttpClients.custom().build();

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
          zipUrl = ZIP_URLS.get(filename.toLowerCase());
          LOGGER.info("[{}] Processing predefined ZIP file: {}", requestId, filename);
        } else {
          // Fallback to learningcontainer pattern for backward compatibility
          zipUrl = "https://www.learningcontainer.com/wp-content/uploads/2020/05/" + filename;
          LOGGER.info("[{}] Processing custom ZIP file (may not exist): {}", requestId, filename);
        }
      } else {
        // Use default speedscale zip file
        zipUrl = ZIP_URLS.get("speedscale");
        LOGGER.info("[{}] Processing default ZIP file (speedscale)", requestId);
      }

      // Use the shared HTTP client (single connection)
      HttpGet httpget = new HttpGet(zipUrl);

      LOGGER.info("[{}] REQ zip download: {}", requestId, httpget.getRequestUri());

      String result =
          HTTP_CLIENT.execute(
              httpget,
              response -> {
                HttpEntity entity = response.getEntity();
                LOGGER.info("[{}] RES zip download: {}", requestId, response.getCode());

                if (response.getCode() == HTTP_OK) {
                  // Read the zip file content as bytes
                  byte[] zipBytes = IOUtils.toByteArray(entity.getContent());

                  // Parse the zip file and get the index
                  List<ZipFileInfo> zipIndex = getZipIndex(zipBytes);

                  // Convert to JSON
                  try {
                    return convertToJson(zipIndex);
                  } catch (Exception ex) {
                    throw new RuntimeException(ex);
                  }
                } else {
                  String errorMsg =
                      String.format("Failed to download zip file from URL: %s", zipUrl);
                  LOGGER.error(
                      "[{}] ZIP download failed - Status: {}, URL: {}",
                      requestId,
                      response.getCode(),
                      zipUrl);
                  return "{\"error\": \""
                      + errorMsg
                      + "\", \"status\": "
                      + response.getCode()
                      + ", \"url\": \""
                      + zipUrl
                      + "\"}";
                }
              });

      body = result;

    } catch (Exception e) {
      LOGGER.error("[{}] Unable to download and process zip file", requestId, e);
      throw e;
    }

    return body;
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
