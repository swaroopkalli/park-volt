package com.parkvolt.booking.controller;

import com.parkvolt.booking.dto.*;
import com.parkvolt.booking.service.BookingService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/bookings")
public class BookingController {
    private final BookingService service;

    public BookingController(BookingService service) { this.service = service; }

    @PostMapping
    public ResponseEntity<BookingResponse> create(@Valid @RequestBody CreateBookingRequest r) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(r));
    }

    @GetMapping
    public List<BookingResponse> all() { return service.all(); }

    @GetMapping("/{id}")
    public BookingResponse get(@PathVariable Long id) { return service.get(id); }

    @GetMapping("/user/{userId}")
    public List<BookingResponse> forUser(@PathVariable String userId) { return service.forUser(userId); }

    @PatchMapping("/{id}/cancel")
    public BookingResponse cancel(@PathVariable Long id) { return service.cancel(id); }

    @PatchMapping("/{id}/check-in")
    public BookingResponse checkIn(@PathVariable Long id) { return service.checkIn(id); }

    @PatchMapping("/{id}/complete")
    public BookingResponse complete(@PathVariable Long id) { return service.complete(id); }
}
