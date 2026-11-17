package com.parkvolt.booking.dto;

import jakarta.validation.constraints.*;

public record CreateBookingRequest(@NotBlank String userId, @NotNull Long slotId, @NotBlank @Size(max = 20) String vehicleNumber) {}
