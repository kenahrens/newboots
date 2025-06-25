// src/main/java/com/speedscale/newboots/NewbootsApplication.java
package com.speedscale.newboots;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.context.annotation.ComponentScan; // Import ComponentScan
import net.devh.boot.grpc.server.autoconfigure.GrpcServerAutoConfiguration;

@SpringBootApplication
@ImportAutoConfiguration(GrpcServerAutoConfiguration.class)
// Add the package where your generated gRPC classes reside
// This tells Spring to scan both your main application package AND the generated gRPC package
@ComponentScan(basePackages = {"com.speedscale.newboots", "com.speedscale.grpc"})
public class NewbootsApplication {

    public static void main(String[] args) {
        SpringApplication.run(NewbootsApplication.class, args);
    }

}
