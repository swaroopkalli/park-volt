package com.parkvolt.charging.dto;

public record BookingDto(Long id, String userId, Long slotId, String slotNumber, String slotType, String vehicleNumber, String status) {}
