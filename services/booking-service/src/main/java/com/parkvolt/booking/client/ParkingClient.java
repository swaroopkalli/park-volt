package com.parkvolt.booking.client;

import com.parkvolt.booking.dto.SlotDto;
import com.parkvolt.booking.exception.ApiException;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Component
public class ParkingClient {
    private static final String SVC = "parking-service";
    private final RestClient client;

    public ParkingClient(RestClient parkingRestClient) { this.client = parkingRestClient; }

    public SlotDto getSlot(Long id) {
        return call(() -> client.get().uri("/slots/{id}", id).retrieve().body(SlotDto.class));
    }

    public SlotDto reserve(Long id, String vehicle) {
        return call(() -> client.post().uri("/slots/{id}/reserve", id).body(Map.of("vehicleNumber", vehicle)).retrieve().body(SlotDto.class));
    }

    public void release(Long id) { call(() -> client.post().uri("/slots/{id}/release", id).retrieve().body(SlotDto.class)); }
    public void entry(Long id) { call(() -> client.post().uri("/slots/{id}/entry", id).retrieve().body(SlotDto.class)); }
    public void exit(Long id) { call(() -> client.post().uri("/slots/{id}/exit", id).retrieve().body(SlotDto.class)); }

    private <T> T call(java.util.function.Supplier<T> s) {
        try {
            return s.get();
        } catch (ResourceAccessException e) {
            throw ApiException.unavailable(SVC);
        } catch (RestClientResponseException e) {
            HttpStatusCode st = e.getStatusCode();
            if (st.value() == 404) throw new ApiException(HttpStatus.NOT_FOUND, "SLOT_NOT_FOUND", "Slot not found");
            if (st.value() == 409) throw new ApiException(HttpStatus.CONFLICT, "SLOT_NOT_AVAILABLE", "Slot is not available for this operation");
            if (st.is5xxServerError()) throw ApiException.unavailable(SVC);
            throw new ApiException(HttpStatus.BAD_GATEWAY, "PARKING_ERROR", "Unexpected response from parking-service");
        }
    }
}
