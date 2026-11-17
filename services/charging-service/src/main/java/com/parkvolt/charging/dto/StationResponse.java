package com.parkvolt.charging.dto;

import com.parkvolt.charging.model.*;

public record StationResponse(Long id, String stationName, double powerKw, String connectorType, StationStatus status) {
    public static StationResponse from(ChargingStation s) {
        return new StationResponse(s.getId(), s.getStationName(), s.getPowerKw(), s.getConnectorType(), s.getStatus());
    }
}
