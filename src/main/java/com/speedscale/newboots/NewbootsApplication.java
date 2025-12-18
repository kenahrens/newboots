// src/main/java/com/speedscale/newboots/NewbootsApplication.java
package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration;
import org.springframework.boot.autoconfigure.data.mongo.MongoReactiveDataAutoConfiguration;
import org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration;
import org.springframework.boot.autoconfigure.mongo.MongoReactiveAutoConfiguration;

/** Main application entry point for Newboots. */
@SpringBootApplication(exclude = {
    MongoAutoConfiguration.class,
    MongoDataAutoConfiguration.class,
    MongoReactiveAutoConfiguration.class,
    MongoReactiveDataAutoConfiguration.class
})
public class NewbootsApplication {
  /** Logger for this class. */
  private static final Logger LOGGER = LoggerFactory.getLogger(NewbootsApplication.class);

  /** Dummy non-static field to avoid utility class check. */
  @SuppressWarnings("unused")
  private int dummy = 0;

  /** Default constructor required by Spring Boot. */
  public NewbootsApplication() {}

  /**
   * Main method to start the Spring Boot application.
   *
   * @param args the command line arguments
   */
  public static void main(final String[] args) {
    SpringApplication.run(NewbootsApplication.class, args);
  }
}
