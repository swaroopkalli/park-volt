package com.parkvolt.charging.repository;

import com.parkvolt.charging.model.*;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SessionRepository extends JpaRepository<ChargingSession, Long> {
    List<ChargingSession> findAllByOrderByIdDesc();
    List<ChargingSession> findByUserIdOrderByIdDesc(String userId);
    boolean existsByUserIdAndStatus(String userId, SessionStatus status);
}
