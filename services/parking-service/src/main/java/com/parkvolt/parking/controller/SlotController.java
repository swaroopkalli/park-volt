package com.parkvolt.parking.controller;

import com.parkvolt.parking.dto.*;
import com.parkvolt.parking.model.*;
import com.parkvolt.parking.service.ParkingSlotService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/slots")
public class SlotController {
    private final ParkingSlotService service;

    public SlotController(ParkingSlotService service) { this.service = service; }

    @GetMapping
    public List<SlotResponse> list(@RequestParam(required = false) SlotType type, @RequestParam(required = false) SlotStatus status) {
        return service.list(type, status);
    }

    @GetMapping("/available")
    public List<SlotResponse> available() { return service.available(); }

    @GetMapping("/{id}")
    public SlotResponse get(@PathVariable Long id) { return service.get(id); }

    @PostMapping
    public ResponseEntity<SlotResponse> create(@Valid @RequestBody CreateSlotRequest r) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(r));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/status")
    public SlotResponse status(@PathVariable Long id, @Valid @RequestBody StatusRequest r) { return service.changeStatus(id, r.status()); }

    @PostMapping("/{id}/reserve")
    public SlotResponse reserve(@PathVariable Long id, @Valid @RequestBody ReserveRequest r) { return service.reserve(id, r.vehicleNumber()); }

    @PostMapping("/{id}/release")
    public SlotResponse release(@PathVariable Long id) { return service.release(id); }

    @PostMapping("/{id}/entry")
    public SlotResponse entry(@PathVariable Long id) { return service.entry(id); }

    @PostMapping("/{id}/exit")
    public SlotResponse exit(@PathVariable Long id) { return service.exit(id); }
}
