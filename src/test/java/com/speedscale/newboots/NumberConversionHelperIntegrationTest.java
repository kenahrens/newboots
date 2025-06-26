package com.speedscale.newboots;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class NumberConversionHelperIntegrationTest {
    @Test
    public void testNumberToWords() throws Exception {
        int number = 123;
        String result = NumberConversionHelper.convertNumberToWords(number);
        assertNotNull(result, "Result should not be null");
        assertTrue(result.toLowerCase().contains("one hundred"), "Result should contain 'one hundred'");
        assertTrue(result.toLowerCase().contains("twenty three"), "Result should contain 'twenty three'");
    }
} 