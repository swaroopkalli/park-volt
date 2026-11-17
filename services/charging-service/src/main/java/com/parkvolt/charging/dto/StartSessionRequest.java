package com.parkvolt.charging.dto;

import jakarta.validation.constraints.*;

public record StartSessionRequest(@NotBlank String userId, @NotNull Long bookingId, @NotNull Long stationId, @Positive Double targetKwh) {}
