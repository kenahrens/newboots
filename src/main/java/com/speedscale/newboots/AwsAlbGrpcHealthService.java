package com.speedscale.newboots;

import com.speedscale.grpc.HealthGrpc;
import com.speedscale.grpc.HealthCheckRequest;
import com.speedscale.grpc.HealthCheckResponse;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;

@GrpcService
public class AwsAlbGrpcHealthService extends HealthGrpc.HealthImplBase {
    @Override
    public void aWSALBHealthCheck(HealthCheckRequest request, StreamObserver<HealthCheckResponse> responseObserver) {
        // AWS ALB expects gRPC status code 12 (UNIMPLEMENTED) for health check
        // But to indicate healthy, we return SERVING status in the response
        HealthCheckResponse response = HealthCheckResponse.newBuilder().setStatus("SERVING").build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    @Override
    public void check(HealthCheckRequest request, StreamObserver<HealthCheckResponse> responseObserver) {
        HealthCheckResponse response = HealthCheckResponse.newBuilder().setStatus("SERVING").build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
} 