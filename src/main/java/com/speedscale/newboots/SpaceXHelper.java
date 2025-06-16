package com.speedscale.newboots;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestFactory;
import com.google.api.client.http.HttpResponse;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;

public class SpaceXHelper {
    
    static Logger logger = LoggerFactory.getLogger(SpaceXHelper.class);
    static final String SPACEX_URI = "https://api.spacexdata.com/v5/launches/latest";
    
    static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();

    public static String invoke() throws Exception {
        
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