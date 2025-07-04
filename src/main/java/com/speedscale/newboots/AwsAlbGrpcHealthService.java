package com.speedscale.newboots;

import com.speedscale.grpc.HealthGrpc;
import com.speedscale.grpc.HealthCheckRequest;
import com.speedscale.grpc.HealthCheckResponse;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;

/**
 * gRPC service for AWS ALB health checks.
 * This class is not designed for extension.
 */
@GrpcService
public final class AwsAlbGrpcHealthService extends HealthGrpc.HealthImplBase {
    /**
     * Logger for this class.
     */
    private static final org.slf4j.Logger LOGGER =
        org.slf4j.LoggerFactory.getLogger(AwsAlbGrpcHealthService.class);

    /**
     * Handles AWS ALB health check requests.
     *
     * @param request the health check request
     * @param responseObserver the response observer
     */
    @Override
    public void aWSALBHealthCheck(final HealthCheckRequest request,
            final StreamObserver<HealthCheckResponse> responseObserver) {
        LOGGER.info("Received health check request");
        // AWS ALB expects gRPC status code 12 (UNIMPLEMENTED) for health check
        // to indicate that the target is healthy.
        responseObserver.onError(io.grpc.Status.UNIMPLEMENTED
            .withDescription("Health check successful")
            .asRuntimeException());
    }

    /**
     * Handles general health check requests.
     *
     * @param request the health check request
     * @param responseObserver the response observer
     */
    @Override
    public void check(final HealthCheckRequest request,
            final StreamObserver<HealthCheckResponse> responseObserver) {
        LOGGER.info("Received standard health check request");
        HealthCheckResponse response = HealthCheckResponse.newBuilder()
            .setStatus("SERVING").build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
}
