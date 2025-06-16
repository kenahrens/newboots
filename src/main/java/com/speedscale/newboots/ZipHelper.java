package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.commons.io.IOUtils;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.HttpEntity;

import java.io.IOException;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipFile;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.util.HashMap;
import java.util.Map;

public class ZipHelper {

    static Logger logger = LoggerFactory.getLogger(ZipHelper.class);
    
    // Reuse HTTP client to avoid multiple connections
    private static final CloseableHttpClient HTTP_CLIENT = HttpClients.custom()
            .build();
    
    // Predefined ZIP file URLs for reliable access
    private static final Map<String, String> ZIP_URLS = new HashMap<>();
    static {
        ZIP_URLS.put("speedscale", "https://github.com/speedscale/speedscale/archive/refs/heads/main.zip");
        ZIP_URLS.put("jquery", "https://github.com/jquery/jquery/archive/refs/heads/main.zip");
        ZIP_URLS.put("bootstrap", "https://github.com/twbs/bootstrap/archive/refs/heads/main.zip");
        // Add more predefined ZIP files as needed
    }

    // Backward compatibility method
    public static String invoke() throws Exception {
        return invoke(null);
    }

    public static String invoke(String filename) throws Exception {
        
        String body = "{}";
        String requestId = String.valueOf(System.currentTimeMillis());
        
        try {
            // Build the zip URL based on the provided filename or use default
            String zipUrl;
            if (filename != null && !filename.trim().isEmpty()) {
                // Check if it's a predefined filename
                if (ZIP_URLS.containsKey(filename.toLowerCase())) {
                    zipUrl = ZIP_URLS.get(filename.toLowerCase());
                    logger.info("[{}] Processing predefined ZIP file: {}", requestId, filename);
                } else {
                    // Fallback to learningcontainer pattern for backward compatibility
                    zipUrl = "https://www.learningcontainer.com/wp-content/uploads/2020/05/" + filename;
                    logger.info("[{}] Processing custom ZIP file (may not exist): {}", requestId, filename);
                }
            } else {
                // Use default speedscale zip file
                zipUrl = ZIP_URLS.get("speedscale");
                logger.info("[{}] Processing default ZIP file (speedscale)", requestId);
            }
            
            // Use the shared HTTP client (single connection)
            HttpGet httpget = new HttpGet(zipUrl);

            logger.info("[{}] REQ zip download: {}", requestId, httpget.getRequestUri());

            String result = HTTP_CLIENT.execute(httpget, response -> {
                HttpEntity entity = response.getEntity();
                logger.info("[{}] RES zip download: {}", requestId, response.getCode());
                
                if (response.getCode() == 200) {
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
                    String errorMsg = String.format("Failed to download zip file from URL: %s", zipUrl);
                    logger.error("[{}] ZIP download failed - Status: {}, URL: {}", requestId, response.getCode(), zipUrl);
                    return "{\"error\": \"" + errorMsg + "\", \"status\": " + response.getCode() + ", \"url\": \"" + zipUrl + "\"}";
                }
            });
            
            body = result;
            
        } catch (Exception e) {
            logger.error("[{}] Unable to download and process zip file", requestId, e);
            throw e;
        }
        
        return body;
    }
    
    private static List<ZipFileInfo> getZipIndex(byte[] zipBytes) throws IOException {
        List<ZipFileInfo> index = new ArrayList<>();
        
        // Create a temporary file to work with ZipFile
        File tempFile = File.createTempFile("ziphelper", ".zip");
        try {
            // Write bytes to temporary file
            try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                fos.write(zipBytes);
            }
            
            // Use ZipFile to read central directory which has accurate size info
            try (ZipFile zipFile = new ZipFile(tempFile)) {
                zipFile.stream().forEach(entry -> {
                    ZipFileInfo fileInfo = new ZipFileInfo();
                    fileInfo.name = entry.getName();
                    fileInfo.size = entry.getSize();
                    fileInfo.compressedSize = entry.getCompressedSize();
                    fileInfo.isDirectory = entry.isDirectory();
                    fileInfo.lastModified = entry.getTime();
                    
                    index.add(fileInfo);
                });
            }
        } finally {
            // Clean up temporary file
            Files.deleteIfExists(tempFile.toPath());
        }
        
        return index;
    }
    
    private static String convertToJson(List<ZipFileInfo> zipIndex) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        ObjectNode rootNode = mapper.createObjectNode();
        ArrayNode filesArray = mapper.createArrayNode();
        
        for (ZipFileInfo fileInfo : zipIndex) {
            ObjectNode fileNode = mapper.createObjectNode();
            fileNode.put("name", fileInfo.name);
            fileNode.put("size", fileInfo.size);
            fileNode.put("compressedSize", fileInfo.compressedSize);
            fileNode.put("isDirectory", fileInfo.isDirectory);
            fileNode.put("lastModified", fileInfo.lastModified);
            filesArray.add(fileNode);
        }
        
        rootNode.put("totalFiles", zipIndex.size());
        rootNode.set("files", filesArray);
        
        return mapper.writeValueAsString(rootNode);
    }
    
    private static class ZipFileInfo {
        String name;
        long size;
        long compressedSize;
        boolean isDirectory;
        long lastModified;
    }
} 