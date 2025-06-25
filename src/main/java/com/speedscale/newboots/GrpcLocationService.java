package com.speedscale.newboots;

import com.speedscale.grpc.Location;
import com.speedscale.grpc.LocationServiceGrpc;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;
import com.speedscale.grpc.HealthGrpc;
import com.speedscale.grpc.HealthCheckRequest;
import com.speedscale.grpc.HealthCheckResponse;

@GrpcService
public class GrpcLocationService extends LocationServiceGrpc.LocationServiceImplBase {
    @Override
    public void echoLocation(Location request, StreamObserver<Location> responseObserver) {
        // Echo the received Location message
        responseObserver.onNext(request);
        responseObserver.onCompleted();
    }
}

@GrpcService
class AwsAlbGrpcHealthService extends HealthGrpc.HealthImplBase {
    @Override
    public void aWSALBHealthCheck(HealthCheckRequest request, StreamObserver<HealthCheckResponse> responseObserver) {
        // AWS ALB expects gRPC status code 12 (UNIMPLEMENTED) for health check
        // But to indicate healthy, we return SERVING status in the response
        HealthCheckResponse response = HealthCheckResponse.newBuilder().setStatus("SERVING").build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
} 