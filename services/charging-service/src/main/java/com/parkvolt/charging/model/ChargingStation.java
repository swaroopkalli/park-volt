package com.parkvolt.charging.model;

import jakarta.persistence.*;

@Entity
@Table(name = "charging_stations")
public class ChargingStation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "station_name", nullable = false, unique = true) private String stationName;
    @Column(name = "power_kw", nullable = false) private double powerKw;
    @Column(name = "connector_type", nullable = false) private String connectorType;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private StationStatus status = StationStatus.AVAILABLE;

    public Long getId() { return id; }
    public String getStationName() { return stationName; }
    public double getPowerKw() { return powerKw; }
    public String getConnectorType() { return connectorType; }
    public StationStatus getStatus() { return status; }
    public void setStatus(StationStatus s) { status = s; }
}
