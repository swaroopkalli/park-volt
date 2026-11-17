package com.parkvolt.booking.service;

import com.parkvolt.booking.client.ParkingClient;
import com.parkvolt.booking.dto.*;
import com.parkvolt.booking.exception.ApiException;
import com.parkvolt.booking.model.*;
import com.parkvolt.booking.repository.BookingRepository;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class BookingService {
    private static final Logger log = LoggerFactory.getLogger(BookingService.class);
    private final BookingRepository repo;
    private final ParkingClient parking;
    private final BigDecimal regular, ev, accessible;

    public BookingService(BookingRepository repo, ParkingClient parking,
                          @Value("${parking.rates.regular}") BigDecimal regular,
                          @Value("${parking.rates.ev}") BigDecimal ev,
                          @Value("${parking.rates.accessible}") BigDecimal accessible) {
        this.repo = repo; this.parking = parking;
        this.regular = regular; this.ev = ev; this.accessible = accessible;
    }

    public BookingResponse create(CreateBookingRequest r) {
        SlotDto slot = parking.getSlot(r.slotId());          // 404 / 503 here, nothing saved
        parking.reserve(r.slotId(), r.vehicleNumber());       // 409 if taken, 503 if down
        try {
            Booking b = new Booking();
            b.setUserId(r.userId());
            b.setSlotId(slot.id());
            b.setSlotNumber(slot.slotNumber());
            b.setSlotType(slot.slotType());
            b.setVehicleNumber(r.vehicleNumber());
            return BookingResponse.from(repo.save(b));
        } catch (RuntimeException e) {
            log.error("Booking save failed, compensating by releasing slot {}", r.slotId(), e);
            try { parking.release(r.slotId()); } catch (RuntimeException ex) { log.error("Compensation release failed", ex); }
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "BOOKING_SAVE_FAILED", "Could not save booking; slot released");
        }
    }

    public List<BookingResponse> all() { return repo.findAllByOrderByIdDesc().stream().map(BookingResponse::from).toList(); }
    public List<BookingResponse> forUser(String userId) { return repo.findByUserIdOrderByIdDesc(userId).stream().map(BookingResponse::from).toList(); }
    public BookingResponse get(Long id) { return BookingResponse.from(find(id)); }

    public BookingResponse cancel(Long id) {
        Booking b = require(id, BookingStatus.CONFIRMED, BookingStatus.CANCELLED);
        parking.release(b.getSlotId());
        b.setStatus(BookingStatus.CANCELLED);
        return BookingResponse.from(repo.save(b));
    }

    public BookingResponse checkIn(Long id) {
        Booking b = require(id, BookingStatus.CONFIRMED, BookingStatus.ACTIVE);
        parking.entry(b.getSlotId());
        b.setStatus(BookingStatus.ACTIVE);
        b.setCheckInTime(Instant.now());
        return BookingResponse.from(repo.save(b));
    }

    public BookingResponse complete(Long id) {
        Booking b = require(id, BookingStatus.ACTIVE, BookingStatus.COMPLETED);
        parking.exit(b.getSlotId());
        Instant out = Instant.now();
        b.setCheckOutTime(out);
        b.setParkingFee(fee(b.getSlotType(), b.getCheckInTime(), out));
        b.setStatus(BookingStatus.COMPLETED);
        return BookingResponse.from(repo.save(b));
    }

    BigDecimal fee(String slotType, Instant in, Instant out) {
        long secs = Math.max(0, Duration.between(in, out).getSeconds());
        long hours = Math.max(1, (secs + 3599) / 3600);
        BigDecimal rate = switch (slotType) { case "EV" -> ev; case "ACCESSIBLE" -> accessible; default -> regular; };
        return rate.multiply(BigDecimal.valueOf(hours)).setScale(2);
    }

    private Booking require(Long id, BookingStatus expected, BookingStatus target) {
        Booking b = find(id);
        if (b.getStatus() != expected)
            throw new ApiException(HttpStatus.CONFLICT, "INVALID_TRANSITION", "Cannot move booking from " + b.getStatus() + " to " + target);
        return b;
    }

    private Booking find(Long id) {
        return repo.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "BOOKING_NOT_FOUND", "Booking " + id + " not found"));
    }
}
