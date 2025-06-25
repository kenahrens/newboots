package com.speedscale.newboots;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import net.devh.boot.grpc.server.autoconfigure.GrpcServerAutoConfiguration;

@SpringBootApplication
@ImportAutoConfiguration(GrpcServerAutoConfiguration.class)
public class NewbootsApplication {

    public static void main(String[] args) {
        SpringApplication.run(NewbootsApplication.class, args);
    }

} 