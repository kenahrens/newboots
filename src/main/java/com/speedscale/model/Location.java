package com.speedscale.model;

public class Location {

    private String locationID;
    private Float latitude;
    private Float longitude;
    private String macAddress;
    private String ipv4;

    public Location() {
        // Default constructor for JSON deserialization
    }

    public Location(String locationID, Float latitude, Float longitude, String macAddress, String ipv4) {
        this.locationID = locationID;
        this.latitude = latitude;
        this.longitude = longitude;
        this.macAddress = macAddress;
        this.ipv4 = ipv4;
    }

    public void setLocationID(String locationID) {
        this.locationID = locationID;
    }

    public void setLatitude(Float latitude) {
        this.latitude = latitude;
    }

    public void setLongitude(Float longitude) {
        this.longitude = longitude;
    }

    public void setMacAddress(String macAddress) {
        this.macAddress = macAddress;
    }

    public void setIpv4(String ipv4) {
        this.ipv4 = ipv4;
    }

    public String getLocationID() {
        return locationID;
    }

    public Float getLatitude() {
        return latitude;
    }

    public Float getLongitude() {
        return longitude;
    }

    public String getMacAddress() {
        return macAddress;
    }

    public String getIpv4() {
        return ipv4;
    }
} 