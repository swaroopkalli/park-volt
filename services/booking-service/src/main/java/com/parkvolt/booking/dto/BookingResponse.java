package com.parkvolt.booking.dto;

import com.parkvolt.booking.model.*;
import java.math.BigDecimal;
import java.time.Instant;

public record BookingResponse(Long id, String userId, Long slotId, String slotNumber, String slotType, String vehicleNumber,
                              Instant bookingDate, BookingStatus status, BigDecimal parkingFee) {
    public static BookingResponse from(Booking b) {
        return new BookingResponse(b.getId(), b.getUserId(), b.getSlotId(), b.getSlotNumber(), b.getSlotType(),
                b.getVehicleNumber(), b.getBookingDate(), b.getStatus(), b.getParkingFee());
    }
}
