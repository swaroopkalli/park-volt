package com.parkvolt.booking.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "bookings")
public class Booking {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "user_id", nullable = false) private String userId;
    @Column(name = "slot_id", nullable = false) private Long slotId;
    @Column(name = "slot_number", nullable = false) private String slotNumber;
    @Column(name = "slot_type", nullable = false) private String slotType;
    @Column(name = "vehicle_number", nullable = false) private String vehicleNumber;
    @Column(name = "booking_date", nullable = false) private Instant bookingDate = Instant.now();
    @Column(name = "check_in_time") private Instant checkInTime;
    @Column(name = "check_out_time") private Instant checkOutTime;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private BookingStatus status = BookingStatus.CONFIRMED;
    @Column(name = "parking_fee") private BigDecimal parkingFee;

    public Long getId() { return id; }
    public String getUserId() { return userId; }
    public void setUserId(String v) { userId = v; }
    public Long getSlotId() { return slotId; }
    public void setSlotId(Long v) { slotId = v; }
    public String getSlotNumber() { return slotNumber; }
    public void setSlotNumber(String v) { slotNumber = v; }
    public String getSlotType() { return slotType; }
    public void setSlotType(String v) { slotType = v; }
    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String v) { vehicleNumber = v; }
    public Instant getBookingDate() { return bookingDate; }
    public Instant getCheckInTime() { return checkInTime; }
    public void setCheckInTime(Instant v) { checkInTime = v; }
    public Instant getCheckOutTime() { return checkOutTime; }
    public void setCheckOutTime(Instant v) { checkOutTime = v; }
    public BookingStatus getStatus() { return status; }
    public void setStatus(BookingStatus v) { status = v; }
    public BigDecimal getParkingFee() { return parkingFee; }
    public void setParkingFee(BigDecimal v) { parkingFee = v; }
}
