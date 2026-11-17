package com.parkvolt.parking.dto;

import jakarta.validation.constraints.*;

public record ReserveRequest(@NotBlank @Size(max = 20) String vehicleNumber) {}
