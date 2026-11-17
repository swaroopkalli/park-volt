package com.parkvolt.charging.repository;

import com.parkvolt.charging.model.*;
import java.util.List;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface StationRepository extends JpaRepository<ChargingStation, Long> {
    List<ChargingStation> findAllByOrderById();
    List<ChargingStation> findByStatusOrderById(StationStatus status);

    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE ChargingStation s SET s.status = com.parkvolt.charging.model.StationStatus.CHARGING "
         + "WHERE s.id = :id AND s.status = com.parkvolt.charging.model.StationStatus.AVAILABLE")
    int claim(@Param("id") Long id);

    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE ChargingStation s SET s.status = com.parkvolt.charging.model.StationStatus.AVAILABLE "
         + "WHERE s.id = :id AND s.status = com.parkvolt.charging.model.StationStatus.CHARGING")
    int free(@Param("id") Long id);
}
