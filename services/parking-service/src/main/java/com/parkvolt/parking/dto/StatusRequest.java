package com.parkvolt.parking.dto;

import com.parkvolt.parking.model.SlotStatus;
import jakarta.validation.constraints.NotNull;

public record StatusRequest(@NotNull SlotStatus status) {}
