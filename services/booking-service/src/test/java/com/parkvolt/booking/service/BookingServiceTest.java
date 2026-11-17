package com.parkvolt.booking.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.parkvolt.booking.client.ParkingClient;
import com.parkvolt.booking.dto.CreateBookingRequest;
import com.parkvolt.booking.dto.SlotDto;
import com.parkvolt.booking.exception.ApiException;
import com.parkvolt.booking.model.Booking;
import com.parkvolt.booking.repository.BookingRepository;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class BookingServiceTest {
    private final BookingRepository repo = mock(BookingRepository.class);
    private final ParkingClient parking = mock(ParkingClient.class);
    private final BookingService service = new BookingService(repo, parking, new BigDecimal("20"), new BigDecimal("30"), new BigDecimal("20"));
    private final CreateBookingRequest req = new CreateBookingRequest("student1", 11L, "KA03AB1234");

    @Test
    void releasesSlotAndReturns500WhenSaveFails() {
        when(parking.getSlot(11L)).thenReturn(new SlotDto(11L, "P11", "EV", "AVAILABLE", "1", null));
        when(repo.save(any(Booking.class))).thenThrow(new RuntimeException("db down"));

        assertThatThrownBy(() -> service.create(req))
                .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getStatus().value()).isEqualTo(500));
        verify(parking).reserve(11L, "KA03AB1234");
        verify(parking).release(11L);
    }

    @Test
    void savesNothingWhenParkingIsDown() {
        when(parking.getSlot(11L)).thenThrow(ApiException.unavailable("parking-service"));

        assertThatThrownBy(() -> service.create(req))
                .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.getStatus().value()).isEqualTo(503));
        verify(repo, never()).save(any());
        verify(parking, never()).release(any());
    }

    @Test
    void feeRoundsUpToWholeHoursWithOneHourMinimum() {
        Instant in = Instant.parse("2026-01-01T10:00:00Z");
        assertThat(service.fee("REGULAR", in, in.plusSeconds(60))).isEqualByComparingTo("20");
        assertThat(service.fee("REGULAR", in, in.plusSeconds(3600))).isEqualByComparingTo("20");
        assertThat(service.fee("REGULAR", in, in.plusSeconds(3601))).isEqualByComparingTo("40");
        assertThat(service.fee("EV", in, in.plusSeconds(2 * 3600 + 1))).isEqualByComparingTo("90");
    }
}
