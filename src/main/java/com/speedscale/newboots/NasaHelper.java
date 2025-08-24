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

/** Utility class for interacting with NASA APIs. */
public final class NasaHelper {
  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(NasaHelper.class);

  /** NASA API URI. */
  static final String NASA_URI = "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY";

  /** HTTP transport for API calls. */
  static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();

  /** Private constructor to prevent instantiation. */
  private NasaHelper() {
    // Utility class
  }

  /**
   * Calls the NASA API and returns data as a string.
   *
   * @return NASA API data
   * @throws Exception if the API call fails
   */
  public static String invoke() throws Exception {
    // Example for breaking up a long string:
    // String longString = "part1" +
    //     "part2";
    HttpRequestFactory factory = HTTP_TRANSPORT.createRequestFactory(null);
    GenericUrl url = new GenericUrl(NASA_URI);
    HttpRequest req = factory.buildGetRequest(url);
    HttpResponse res = req.execute();
    InputStream is = res.getContent();
    BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
    String text = br.lines().collect(Collectors.joining("\n"));
    br.close();
    return text;
  }
}
