package com.parkvolt.parking.dto;

import com.parkvolt.parking.model.SlotType;
import jakarta.validation.constraints.*;

public record CreateSlotRequest(@NotBlank @Size(max = 10) String slotNumber, @NotNull SlotType slotType, @NotBlank @Size(max = 10) String floor) {}
