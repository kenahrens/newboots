// src/main/java/com/speedscale/newboots/NewbootsApplication.java
package com.speedscale.newboots;

import net.devh.boot.grpc.server.autoconfigure.GrpcServerAutoConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan; // Import ComponentScan

/** Main application entry point for Newboots. */
@SpringBootApplication
@ImportAutoConfiguration(GrpcServerAutoConfiguration.class)
// Add the package where your generated gRPC classes reside
// This tells Spring to scan both your main application package
// AND the generated gRPC package
@ComponentScan(basePackages = {"com.speedscale.newboots", "com.speedscale.grpc"})
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
