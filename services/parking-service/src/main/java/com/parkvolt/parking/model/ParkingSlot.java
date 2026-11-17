package com.parkvolt.parking.model;

import jakarta.persistence.*;

@Entity
@Table(name = "parking_slots")
public class ParkingSlot {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "slot_number", nullable = false, unique = true)
    private String slotNumber;
    @Enumerated(EnumType.STRING) @Column(name = "slot_type", nullable = false)
    private SlotType slotType;
    @Enumerated(EnumType.STRING) @Column(nullable = false)
    private SlotStatus status = SlotStatus.AVAILABLE;
    @Column(nullable = false)
    private String floor;
    @Column(name = "vehicle_number")
    private String vehicleNumber;

    public Long getId() { return id; }
    public String getSlotNumber() { return slotNumber; }
    public void setSlotNumber(String v) { this.slotNumber = v; }
    public SlotType getSlotType() { return slotType; }
    public void setSlotType(SlotType v) { this.slotType = v; }
    public SlotStatus getStatus() { return status; }
    public void setStatus(SlotStatus v) { this.status = v; }
    public String getFloor() { return floor; }
    public void setFloor(String v) { this.floor = v; }
    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String v) { this.vehicleNumber = v; }
}
