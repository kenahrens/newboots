package com.speedscale.model;

/**
 * Represents a location with ID, latitude, longitude, MAC address, and IPv4.
 * This class is not designed for extension.
 */
public final class Location {
    /** Location ID. */
    private String locationID;
    /** Latitude. */
    private double latitude;
    /** Longitude. */
    private double longitude;
    /** MAC address. */
    private String macAddress;
    /** IPv4 address. */
    private String ipv4;

    /**
     * Constructs a new Location.
     *
     * @param id the location ID
     * @param lat the latitude
     * @param lon the longitude
     * @param mac the MAC address
     * @param ip the IPv4 address
     */
    public Location(final String id, final double lat,
            final double lon, final String mac, final String ip) {
        this.locationID = id;
        this.latitude = lat;
        this.longitude = lon;
        this.macAddress = mac;
        this.ipv4 = ip;
    }

    /**
     * Sets the location ID.
     *
     * @param id the location ID
     */
    public void setLocationID(final String id) {
        this.locationID = id;
    }

    /**
     * Sets the latitude.
     *
     * @param lat the latitude
     */
    public void setLatitude(final double lat) {
        this.latitude = lat;
    }

    /**
     * Sets the longitude.
     *
     * @param lon the longitude
     */
    public void setLongitude(final double lon) {
        this.longitude = lon;
    }

    /**
     * Sets the MAC address.
     *
     * @param mac the MAC address
     */
    public void setMacAddress(final String mac) {
        this.macAddress = mac;
    }

    /**
     * Sets the IPv4 address.
     *
     * @param ip the IPv4 address
     */
    public void setIpv4(final String ip) {
        this.ipv4 = ip;
    }

    /**
     * Gets the location ID.
     *
     * @return the location ID
     */
    public String getLocationID() {
        return locationID;
    }

    /**
     * Gets the latitude.
     *
     * @return the latitude
     */
    public double getLatitude() {
        return latitude;
    }

    /**
     * Gets the longitude.
     *
     * @return the longitude
     */
    public double getLongitude() {
        return longitude;
    }

    /**
     * Gets the MAC address.
     *
     * @return the MAC address
     */
    public String getMacAddress() {
        return macAddress;
    }

    /**
     * Gets the IPv4 address.
     *
     * @return the IPv4 address
     */
    public String getIpv4() {
        return ipv4;
    }
}

