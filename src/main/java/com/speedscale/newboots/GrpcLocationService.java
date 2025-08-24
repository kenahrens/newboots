package com.speedscale.newboots;

import com.speedscale.grpc.Location;
import com.speedscale.grpc.LocationServiceGrpc;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;

/**
 * Provides gRPC services for location handling in the Newboots microservice. This class is not
 * designed for extension.
 */
@GrpcService
public final class GrpcLocationService extends LocationServiceGrpc.LocationServiceImplBase {
  /**
   * Echoes the provided location.
   *
   * @param request the location request
   * @param responseObserver the response observer
   */
  @Override
  public void echoLocation(
      final Location request, final StreamObserver<Location> responseObserver) {
    // Echo the received Location message
    responseObserver.onNext(request);
    responseObserver.onCompleted();
  }
}
