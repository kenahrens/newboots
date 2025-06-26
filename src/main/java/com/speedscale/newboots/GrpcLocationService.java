package com.speedscale.newboots;

import com.speedscale.grpc.LocationServiceGrpc;
import com.speedscale.grpc.Location;
import io.grpc.stub.StreamObserver;

/**
 * Provides gRPC services for location handling in the Newboots microservice.
 * This class is not designed for extension.
 */
public final class GrpcLocationService extends
        LocationServiceGrpc.LocationServiceImplBase {
    /**
     * Echoes the provided location.
     *
     * @param request the location request
     * @param responseObserver the response observer
     */
    @Override
    public void echoLocation(final Location request,
            final StreamObserver<Location> responseObserver) {
        // Echo the received Location message
        responseObserver.onNext(request);
        responseObserver.onCompleted();
    }
}
