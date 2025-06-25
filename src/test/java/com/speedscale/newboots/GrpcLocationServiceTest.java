package com.speedscale.newboots;

import com.speedscale.grpc.*;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.ManagedChannel;
import io.grpc.Server;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;
import io.grpc.stub.StreamObserver;

public class GrpcLocationServiceTest {
    private static Server server;
    private static ManagedChannel channel;

    @BeforeAll
    public static void setup() throws Exception {
        String serverName = InProcessServerBuilder.generateName();
        server = InProcessServerBuilder.forName(serverName)
                .directExecutor()
                .addService(new GrpcLocationService())
                .addService(new CustomGrpcHealthService())
                .build()
                .start();
        channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
    }

    @AfterAll
    public static void teardown() {
        if (channel != null) channel.shutdownNow();
        if (server != null) server.shutdownNow();
    }

    @Test
    public void testEchoLocation() {
        LocationServiceGrpc.LocationServiceBlockingStub stub = LocationServiceGrpc.newBlockingStub(channel);
        Location req = Location.newBuilder()
                .setLocationID("loc-001")
                .setLatitude(37.7749f)
                .setLongitude(-122.4194f)
                .setMacAddress("00:1A:2B:3C:4D:5E")
                .setIpv4("192.168.1.1")
                .build();
        Location resp = stub.echoLocation(req);
        assertEquals(req, resp);
    }

    @Test
    public void testHealthCheck() {
        HealthGrpc.HealthBlockingStub stub = HealthGrpc.newBlockingStub(channel);
        HealthCheckResponse resp = stub.check(HealthCheckRequest.newBuilder().build());
        assertEquals("SERVING", resp.getStatus());
    }

    private static class CustomGrpcHealthService extends HealthGrpc.HealthImplBase {
        @Override
        public void check(HealthCheckRequest request, StreamObserver<HealthCheckResponse> responseObserver) {
            HealthCheckResponse response = HealthCheckResponse.newBuilder().setStatus("SERVING").build();
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        }
    }
} 