package com.parkvolt.charging.dto;

import com.parkvolt.charging.model.SessionStatus;
import java.math.BigDecimal;
import java.time.Instant;

public record SessionResponse(Long id, String userId, Long bookingId, Long stationId, String stationName, double powerKw,
                              Instant startTime, Instant endTime, double energyKwh, BigDecimal totalCost, BigDecimal ratePerKwh,
                              double targetKwh, double progressPercent, SessionStatus status) {}
