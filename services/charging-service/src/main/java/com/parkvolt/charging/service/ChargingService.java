package com.parkvolt.charging.service;

import com.parkvolt.charging.client.BookingClient;
import com.parkvolt.charging.dto.*;
import com.parkvolt.charging.exception.ApiException;
import com.parkvolt.charging.model.*;
import com.parkvolt.charging.repository.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChargingService {
    private static final Logger log = LoggerFactory.getLogger(ChargingService.class);
    private final StationRepository stations;
    private final SessionRepository sessions;
    private final BookingClient bookings;
    private final double multiplier, defaultTarget;
    private final BigDecimal rate;

    public ChargingService(StationRepository stations, SessionRepository sessions, BookingClient bookings,
                           @Value("${charging.speed-multiplier}") double multiplier,
                           @Value("${charging.rate-per-kwh}") BigDecimal rate,
                           @Value("${charging.default-target-kwh}") double defaultTarget) {
        this.stations = stations; this.sessions = sessions; this.bookings = bookings;
        this.multiplier = multiplier; this.rate = rate; this.defaultTarget = defaultTarget;
    }

    // ---- stations
    public List<StationResponse> stations() { return stations.findAllByOrderById().stream().map(StationResponse::from).toList(); }
    public List<StationResponse> availableStations() { return stations.findByStatusOrderById(StationStatus.AVAILABLE).stream().map(StationResponse::from).toList(); }

    @Transactional
    public StationResponse setStationStatus(Long id, StationStatus to) {
        ChargingStation s = station(id);
        if (to == StationStatus.CHARGING) throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_STATUS", "Status must be AVAILABLE or OFFLINE");
        if (s.getStatus() == StationStatus.CHARGING) throw new ApiException(HttpStatus.CONFLICT, "STATION_CHARGING", "Station is currently charging");
        s.setStatus(to);
        return StationResponse.from(stations.save(s));
    }

    // ---- sessions
    public SessionResponse start(StartSessionRequest r) {
        if (sessions.existsByUserIdAndStatus(r.userId(), SessionStatus.ACTIVE))
            throw new ApiException(HttpStatus.CONFLICT, "ACTIVE_SESSION_EXISTS", "User already has an active charging session");
        BookingDto b = bookings.getBooking(r.bookingId());
        if (!r.userId().equals(b.userId())) throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "BOOKING_USER_MISMATCH", "Booking belongs to another user");
        if (!"EV".equals(b.slotType())) throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "NOT_EV_SLOT", "Booking is not for an EV slot");
        if (!"CONFIRMED".equals(b.status()) && !"ACTIVE".equals(b.status()))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "BOOKING_NOT_ACTIVE", "Booking status is " + b.status());
        station(r.stationId());
        if (stations.claim(r.stationId()) == 0)
            throw new ApiException(HttpStatus.CONFLICT, "STATION_NOT_AVAILABLE", "Station is not available");
        try {
            ChargingSession s = new ChargingSession();
            s.setUserId(r.userId());
            s.setBookingId(r.bookingId());
            s.setStationId(r.stationId());
            s.setStartTime(Instant.now());
            s.setTargetKwh(r.targetKwh() != null ? r.targetKwh() : defaultTarget);
            return toResponse(sessions.save(s));
        } catch (RuntimeException e) {
            log.error("Session save failed, freeing station {}", r.stationId(), e);
            stations.free(r.stationId());
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "SESSION_SAVE_FAILED", "Could not start session; station released");
        }
    }

    public List<SessionResponse> sessions(String userId) {
        List<ChargingSession> l = userId == null ? sessions.findAllByOrderByIdDesc() : sessions.findByUserIdOrderByIdDesc(userId);
        return l.stream().map(this::toResponse).toList();
    }

    public SessionResponse get(Long id) { return toResponse(session(id)); }

    @Transactional
    public SessionResponse stop(Long id) {
        ChargingSession s = session(id);
        if (s.getStatus() != SessionStatus.ACTIVE) throw new ApiException(HttpStatus.CONFLICT, "SESSION_NOT_ACTIVE", "Session is already " + s.getStatus());
        Instant end = Instant.now();
        ChargingStation st = station(s.getStationId());
        double kwh = energy(st.getPowerKw(), s.getStartTime(), end);
        s.setEndTime(end);
        s.setEnergyKwh(kwh);
        s.setTotalCost(cost(kwh));
        s.setStatus(SessionStatus.COMPLETED);
        sessions.save(s);
        stations.free(s.getStationId());
        return toResponse(s);
    }

    // ---- math
    double energy(double powerKw, Instant start, Instant end) {
        double minutes = Math.max(0, Duration.between(start, end).toMillis()) / 60000.0;
        return Math.round(powerKw * (minutes / 60.0) * multiplier * 1000.0) / 1000.0;
    }

    BigDecimal cost(double kwh) { return BigDecimal.valueOf(kwh).multiply(rate).setScale(2, RoundingMode.HALF_UP); }

    private SessionResponse toResponse(ChargingSession s) {
        ChargingStation st = station(s.getStationId());
        double kwh = s.getEnergyKwh();
        BigDecimal total = s.getTotalCost();
        if (s.getStatus() == SessionStatus.ACTIVE) {
            kwh = energy(st.getPowerKw(), s.getStartTime(), Instant.now());
            total = cost(kwh);
        }
        double progress = Math.round(Math.min(100.0, kwh / s.getTargetKwh() * 100.0) * 10.0) / 10.0;
        return new SessionResponse(s.getId(), s.getUserId(), s.getBookingId(), s.getStationId(), st.getStationName(), st.getPowerKw(),
                s.getStartTime(), s.getEndTime(), kwh, total, rate, s.getTargetKwh(), progress, s.getStatus());
    }

    private ChargingStation station(Long id) {
        return stations.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "STATION_NOT_FOUND", "Station " + id + " not found"));
    }

    private ChargingSession session(Long id) {
        return sessions.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "SESSION_NOT_FOUND", "Session " + id + " not found"));
    }
}
