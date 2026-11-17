package com.parkvolt.charging.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import com.parkvolt.charging.client.BookingClient;
import com.parkvolt.charging.repository.SessionRepository;
import com.parkvolt.charging.repository.StationRepository;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class ChargingMathTest {
    private ChargingService with(double multiplier) {
        return new ChargingService(mock(StationRepository.class), mock(SessionRepository.class), mock(BookingClient.class),
                multiplier, new BigDecimal("8"), 20);
    }

    @Test
    void energyFollowsPowerTimeAndMultiplier() {
        Instant s = Instant.parse("2026-01-01T10:00:00Z");
        // 7 kW for 30 real minutes at 1x = 3.5 kWh
        assertThat(with(1).energy(7, s, s.plusSeconds(1800))).isEqualTo(3.5);
        // demo speed: 1 real minute = 1 simulated hour, so 22 kW for 30 s = 11 kWh
        assertThat(with(60).energy(22, s, s.plusSeconds(30))).isEqualTo(11.0);
    }

    @Test
    void costIsEnergyTimesRateRoundedToTwoDecimals() {
        assertThat(with(1).cost(3.5)).isEqualByComparingTo("28.00");
        assertThat(with(1).cost(1.273)).isEqualByComparingTo("10.18");
    }

    @Test
    void negativeElapsedTimeNeverProducesNegativeEnergy() {
        Instant s = Instant.parse("2026-01-01T10:00:00Z");
        assertThat(with(60).energy(7, s, s.minusSeconds(10))).isZero();
    }
}
