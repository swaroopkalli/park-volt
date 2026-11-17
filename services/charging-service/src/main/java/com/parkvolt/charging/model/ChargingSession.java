package com.parkvolt.charging.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "charging_sessions")
public class ChargingSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false) private String userId;
    @Column(name = "booking_id", nullable = false) private Long bookingId;
    @Column(name = "station_id", nullable = false) private Long stationId;
    @Column(name = "start_time", nullable = false) private Instant startTime;
    @Column(name = "end_time") private Instant endTime;
    @Column(name = "target_kwh", nullable = false) private double targetKwh;
    @Column(name = "energy_kwh", nullable = false) private double energyKwh;
    @Column(name = "total_cost", nullable = false) private BigDecimal totalCost = BigDecimal.ZERO;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private SessionStatus status = SessionStatus.ACTIVE;

    public Long getId() { return id; }
    public String getUserId() { return userId; }
    public void setUserId(String v) { userId = v; }
    public Long getBookingId() { return bookingId; }
    public void setBookingId(Long v) { bookingId = v; }
    public Long getStationId() { return stationId; }
    public void setStationId(Long v) { stationId = v; }
    public Instant getStartTime() { return startTime; }
    public void setStartTime(Instant v) { startTime = v; }
    public Instant getEndTime() { return endTime; }
    public void setEndTime(Instant v) { endTime = v; }
    public double getTargetKwh() { return targetKwh; }
    public void setTargetKwh(double v) { targetKwh = v; }
    public double getEnergyKwh() { return energyKwh; }
    public void setEnergyKwh(double v) { energyKwh = v; }
    public BigDecimal getTotalCost() { return totalCost; }
    public void setTotalCost(BigDecimal v) { totalCost = v; }
    public SessionStatus getStatus() { return status; }
    public void setStatus(SessionStatus v) { status = v; }
}
