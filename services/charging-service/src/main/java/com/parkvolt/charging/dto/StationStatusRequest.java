package com.parkvolt.charging.dto;

import com.parkvolt.charging.model.StationStatus;
import jakarta.validation.constraints.NotNull;

public record StationStatusRequest(@NotNull StationStatus status) {}
