package com.parkvolt.parking.dto;

import com.parkvolt.parking.model.*;

public record SlotResponse(Long id, String slotNumber, SlotType slotType, SlotStatus status, String floor, String vehicleNumber) {
    public static SlotResponse from(ParkingSlot s) {
        return new SlotResponse(s.getId(), s.getSlotNumber(), s.getSlotType(), s.getStatus(), s.getFloor(), s.getVehicleNumber());
    }
}
