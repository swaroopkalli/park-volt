package com.parkvolt.charging.controller;

import com.parkvolt.charging.dto.*;
import com.parkvolt.charging.service.ChargingService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController
public class ChargingController {
    private final ChargingService service;

    public ChargingController(ChargingService service) { this.service = service; }

    @GetMapping("/stations")
    public List<StationResponse> stations() { return service.stations(); }

    @GetMapping("/stations/available")
    public List<StationResponse> available() { return service.availableStations(); }

    @PatchMapping("/stations/{id}/status")
    public StationResponse stationStatus(@PathVariable Long id, @Valid @RequestBody StationStatusRequest r) { return service.setStationStatus(id, r.status()); }

    @PostMapping("/sessions/start")
    public ResponseEntity<SessionResponse> start(@Valid @RequestBody StartSessionRequest r) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.start(r));
    }

    @GetMapping("/sessions")
    public List<SessionResponse> sessions(@RequestParam(required = false) String userId) { return service.sessions(userId); }

    @GetMapping("/sessions/{id}")
    public SessionResponse get(@PathVariable Long id) { return service.get(id); }

    @PatchMapping("/sessions/{id}/stop")
    public SessionResponse stop(@PathVariable Long id) { return service.stop(id); }
}
