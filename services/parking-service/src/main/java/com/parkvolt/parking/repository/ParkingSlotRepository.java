package com.parkvolt.parking.repository;

import com.parkvolt.parking.model.*;
import java.util.List;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ParkingSlotRepository extends JpaRepository<ParkingSlot, Long> {
    List<ParkingSlot> findByStatusOrderBySlotNumber(SlotStatus status);

    boolean existsBySlotNumber(String slotNumber);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE ParkingSlot s SET s.status = com.parkvolt.parking.model.SlotStatus.RESERVED, s.vehicleNumber = :v "
         + "WHERE s.id = :id AND s.status = com.parkvolt.parking.model.SlotStatus.AVAILABLE")
    int reserve(@Param("id") Long id, @Param("v") String vehicleNumber);
}
