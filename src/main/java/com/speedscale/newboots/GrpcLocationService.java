package com.speedscale.newboots;

import com.speedscale.grpc.Location;
import com.speedscale.grpc.LocationServiceGrpc;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;

@GrpcService
public class GrpcLocationService extends LocationServiceGrpc.LocationServiceImplBase {
    @Override
    public void echoLocation(Location request, StreamObserver<Location> responseObserver) {
        // Echo the received Location message
        responseObserver.onNext(request);
        responseObserver.onCompleted();
    }
} 