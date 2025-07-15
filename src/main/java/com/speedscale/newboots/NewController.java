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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.http.ResponseEntity;
import java.util.List;

/**
 * Main controller for HTTP endpoints.
 */
@RestController
public final class NewController {
    /** Logger for this class. */
    private static final Logger LOGGER =
        LoggerFactory.getLogger(NewController.class);
    /** Template for greeting messages. */
    private static final String TEMPLATE = "Hello, %s!";
    /** Counter for greetings. */
    private final AtomicLong counter = new AtomicLong();

    @Autowired
    private InventoryRepository inventoryRepository;
    @Autowired
    private MongoTemplate mongoTemplate;

    /**
     * Home endpoint.
     *
     * @return a simple spring message
     */
    @GetMapping("/")
    public String home() {
        return "{ \"spring\": \"is here\" }";
    }

    /**
     * Health check endpoint.
     *
     * @return a health message
     */
    @GetMapping("/healthz")
    public String health() {
        return "{ \"health\": \"health\" }";
    }

    /**
     * Greeting endpoint.
     *
     * @param name the name to greet
     * @return a greeting message
     */
    @GetMapping("/greeting")
    public String greeting(@RequestParam(value = "name", defaultValue = "World")
            final String name) {
        return String.format(TEMPLATE, name);
    }

    @GetMapping("/nasa")
    String nasa() {
        String rspBody = "{}";
        try {
            rspBody = NasaHelper.invoke();
        } catch (Exception e) {
            LOGGER.error("Exception calling nasa", e);
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
            LOGGER.error("Exception calling SpaceX", e);
            rspBody = "{\"exception\": \"" + e.getMessage() + "\"}";
        }
        return rspBody;
    }

    @PostMapping("/location")
    @ResponseBody
    Location location(@RequestBody final Location loc) {
        return loc;
    }

    @GetMapping("/zip")
    String zip(@RequestParam(value = "filename", required = false)
            final String filename) {
        String rspBody = "{}";
        try {
            rspBody = ZipHelper.invoke(filename);
        } catch (Exception e) {
            LOGGER.error("Exception processing zip file", e);
            rspBody = "{\"exception\": \"" + e.getMessage() + "\"}";
        }
        return rspBody;
    }

    @GetMapping("/inventory/search")
    public ResponseEntity<?> searchInventory(@RequestParam String key, @RequestParam String value) {
        try {
            Query query = new Query();
            query.addCriteria(Criteria.where(key).is(convertValue(key, value)));
            List<Inventory> results = mongoTemplate.find(query, Inventory.class);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            LOGGER.error("Error searching inventory", e);
            return ResponseEntity.badRequest().body("Invalid key or value");
        }
    }

    private Object convertValue(String key, String value) {
        // Try to convert value to number if key is qty or size.h/size.w
        if ("qty".equals(key)) {
            try { return Integer.parseInt(value); } catch (Exception ignored) {}
        }
        if (key.startsWith("size.")) {
            try { return Double.parseDouble(value); } catch (Exception ignored) {}
        }
        return value;
    }

    /**
     * Converts a number to words and returns a JSON response.
     *
     * @param number the number to convert
     * @return a JSON string with the number and its word representation
     */
    @GetMapping("/number-to-words")
    public String numberToWords(
            @RequestParam(value = "number") final int number) {
        String rspBody;
        try {
            String words = NumberConversionHelper.convertNumberToWords(number);
            rspBody = String.format(
                "{\"number\": %d, \"words\": \"%s\"}",
                number, words.replaceAll("\"", "\\\""));
        } catch (Exception e) {
            LOGGER.error("Exception calling numberToWords", e);
            rspBody = String.format("{\"exception\": \"%s\"}", e.getMessage());
        }
        return rspBody;
    }
}
