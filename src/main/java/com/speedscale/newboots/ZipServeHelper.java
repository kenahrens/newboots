package com.speedscale.newboots;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Generates deterministic ZIP files for serving as binary HTTP responses.
 * Used to reproduce large-payload capture behavior (e.g. eBPF vs sidecar).
 */
public final class ZipServeHelper {

  private static final int MIN_SIZE_MB = 1;
  private static final int MAX_SIZE_MB = 50;

  // Cache generated ZIPs by size so repeated requests are cheap
  private static final ConcurrentHashMap<Integer, byte[]> CACHE = new ConcurrentHashMap<>();

  private ZipServeHelper() {}

  /**
   * Returns a ZIP file of approximately {@code sizeMB} megabytes.
   * The content is deterministic (repeating byte pattern, STORED/uncompressed)
   * so the on-wire size equals the requested size.
   */
  public static byte[] generateZip(final int sizeMB) throws IOException {
    int clamped = Math.max(MIN_SIZE_MB, Math.min(MAX_SIZE_MB, sizeMB));
    return CACHE.computeIfAbsent(clamped, size -> {
      try {
        return buildZip(size);
      } catch (IOException e) {
        throw new RuntimeException("Failed to generate ZIP", e);
      }
    });
  }

  private static byte[] buildZip(final int sizeMB) throws IOException {
    int payloadLen = sizeMB * 1024 * 1024;

    byte[] payload = new byte[payloadLen];
    for (int i = 0; i < payloadLen; i++) {
      payload[i] = (byte) (i & 0xFF);
    }

    CRC32 crc32 = new CRC32();
    crc32.update(payload);

    ByteArrayOutputStream baos = new ByteArrayOutputStream(payloadLen + 8192);
    try (ZipOutputStream zos = new ZipOutputStream(baos)) {
      ZipEntry entry = new ZipEntry("testdata.bin");
      entry.setMethod(ZipEntry.STORED);
      entry.setSize(payloadLen);
      entry.setCompressedSize(payloadLen);
      entry.setCrc(crc32.getValue());
      zos.putNextEntry(entry);
      zos.write(payload);
      zos.closeEntry();
    }

    return baos.toByteArray();
  }
}
