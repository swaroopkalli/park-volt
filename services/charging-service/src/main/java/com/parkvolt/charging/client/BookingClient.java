package com.parkvolt.charging.client;

import com.parkvolt.charging.dto.BookingDto;
import com.parkvolt.charging.exception.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Component
public class BookingClient {
    private static final String SVC = "booking-service";
    private final RestClient client;

    public BookingClient(RestClient bookingRestClient) { this.client = bookingRestClient; }

    public BookingDto getBooking(Long id) {
        try {
            return client.get().uri("/bookings/{id}", id).retrieve().body(BookingDto.class);
        } catch (ResourceAccessException e) {
            throw ApiException.unavailable(SVC);
        } catch (RestClientResponseException e) {
            if (e.getStatusCode().value() == 404) throw new ApiException(HttpStatus.NOT_FOUND, "BOOKING_NOT_FOUND", "Booking " + id + " not found");
            if (e.getStatusCode().is5xxServerError()) throw ApiException.unavailable(SVC);
            throw new ApiException(HttpStatus.BAD_GATEWAY, "BOOKING_ERROR", "Unexpected response from booking-service");
        }
    }
}
