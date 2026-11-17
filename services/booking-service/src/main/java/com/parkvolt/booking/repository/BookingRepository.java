package com.parkvolt.booking.repository;

import com.parkvolt.booking.model.Booking;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookingRepository extends JpaRepository<Booking, Long> {
    List<Booking> findByUserIdOrderByIdDesc(String userId);
    List<Booking> findAllByOrderByIdDesc();
}
