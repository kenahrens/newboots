package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import com.speedscale.model.Location;

@RestController
public class NewController {

    static Logger logger = LoggerFactory.getLogger(NewController.class);
    
    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    @GetMapping("/")
    public String home() {
        String rspBody = "{\"spring\": \"is here\"}";
        return rspBody;
    }

    @GetMapping("/healthz")
    public String health() {
        String rspBody = "{\"health\": \"health\"}";
        return rspBody;
    }

    @GetMapping("/greeting")
    public Greeting greeting(@RequestParam(value = "name", defaultValue = "World") String name) {
        return new Greeting(counter.incrementAndGet(), String.format(template, name));
    }

    @GetMapping("/nasa")
    String nasa() {
        String rspBody = "{}";
        try {
            rspBody = NasaHelper.invoke();
        } catch (Exception e) {
            logger.error("Exception calling nasa", e);
            rspBody = "{\"exception\": \"" + e.getMessage() + "\"}";
        }
        return rspBody;
    }

    @GetMapping("/spacex")
    String spacex() {
        String rspBody = "{}";
        try {
            rspBody = SpaceXHelper.invoke();
        } catch (Exception e) {
            logger.error("Exception calling SpaceX", e);
            rspBody = "{\"exception\": \"" + e.getMessage() + "\"}";
        }
        return rspBody;
    }

    @PostMapping("/location")
    @ResponseBody
    Location location(@RequestBody Location loc) {
        return loc;
    }

    @GetMapping("/zip")
    String zip(@RequestParam(value = "filename", required = false) String filename) {
        String rspBody = "{}";
        try {
            rspBody = ZipHelper.invoke(filename);
        } catch (Exception e) {
            logger.error("Exception processing zip file", e);
            rspBody = "{\"exception\": \"" + e.getMessage() + "\"}";
        }
        return rspBody;
    }

    @GetMapping("/number-to-words")
    public String numberToWords(@RequestParam(value = "number") int number) {
        String rspBody;
        try {
            String words = NumberConversionHelper.numberToWords(number);
            rspBody = String.format("{\"number\": %d, \"words\": \"%s\"}", number, words.replaceAll("\"", "\\\""));
        } catch (Exception e) {
            logger.error("Exception calling numberToWords", e);
            rspBody = String.format("{\"exception\": \"%s\"}", e.getMessage());
        }
        return rspBody;
    }
} 