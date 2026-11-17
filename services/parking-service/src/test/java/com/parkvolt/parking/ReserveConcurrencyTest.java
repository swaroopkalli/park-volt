package com.parkvolt.parking;

import static org.assertj.core.api.Assertions.assertThat;

import com.parkvolt.parking.dto.CreateSlotRequest;
import com.parkvolt.parking.dto.SlotResponse;
import com.parkvolt.parking.exception.ApiException;
import com.parkvolt.parking.model.SlotStatus;
import com.parkvolt.parking.model.SlotType;
import com.parkvolt.parking.service.ParkingSlotService;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class ReserveConcurrencyTest {
    @Autowired ParkingSlotService service;

    @Test
    void onlyOneOfManyConcurrentReservationsWins() throws Exception {
        SlotResponse slot = service.create(new CreateSlotRequest("T01", SlotType.EV, "G"));
        int threads = 8;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CountDownLatch ready = new CountDownLatch(threads);
        CountDownLatch go = new CountDownLatch(1);
        AtomicInteger ok = new AtomicInteger();
        AtomicInteger conflict = new AtomicInteger();
        List<Future<?>> fs = new ArrayList<>();
        for (int i = 0; i < threads; i++) {
            final int n = i;
            fs.add(pool.submit(() -> {
                ready.countDown();
                try {
                    go.await();
                    service.reserve(slot.id(), "KA00AA000" + n);
                    ok.incrementAndGet();
                } catch (ApiException e) {
                    if (e.getStatus().value() == 409 && e.getCode().equals("SLOT_NOT_AVAILABLE")) conflict.incrementAndGet();
                } catch (InterruptedException ignored) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        ready.await();
        go.countDown();
        for (Future<?> f : fs) f.get(10, TimeUnit.SECONDS);
        pool.shutdown();

        assertThat(ok.get()).isEqualTo(1);
        assertThat(conflict.get()).isEqualTo(threads - 1);
        assertThat(service.get(slot.id()).status()).isEqualTo(SlotStatus.RESERVED);
    }
}
