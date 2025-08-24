package com.speedscale.newboots;

import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestFactory;
import com.google.api.client.http.HttpResponse;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Utility class for interacting with SpaceX APIs. */
public final class SpaceXHelper {
  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(SpaceXHelper.class);

  /** SpaceX API URI. */
  static final String SPACEX_URI = "https://api.spacexdata.com/v5/launches/latest";

  /** HTTP transport for API calls. */
  static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();

  /** Private constructor to prevent instantiation. */
  private SpaceXHelper() {
    // Utility class
  }

  /**
   * Calls the SpaceX API and returns the latest launch data as a string.
   *
   * @return the latest SpaceX launch data
   * @throws Exception if the API call fails
   */
  public static String invoke() throws Exception {
    // Example: LOGGER.info("Calling SpaceX API at {}", SPACEX_URI);
    HttpRequestFactory factory = HTTP_TRANSPORT.createRequestFactory(null);
    GenericUrl url = new GenericUrl(SPACEX_URI);
    HttpRequest req = factory.buildGetRequest(url);
    HttpResponse res = req.execute();
    InputStream is = res.getContent();
    BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
    String text = br.lines().collect(Collectors.joining("\n"));
    br.close();
    return text;
  }
}
