package com.parkvolt.parking.service;

import com.parkvolt.parking.dto.*;
import com.parkvolt.parking.exception.ApiException;
import com.parkvolt.parking.model.*;
import com.parkvolt.parking.repository.ParkingSlotRepository;
import java.util.*;
import java.util.stream.Stream;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import static com.parkvolt.parking.model.SlotStatus.*;

@Service
public class ParkingSlotService {
    private static final Map<SlotStatus, Set<SlotStatus>> ALLOWED = Map.of(
        AVAILABLE, Set.of(RESERVED, UNAVAILABLE),
        RESERVED, Set.of(OCCUPIED, AVAILABLE),
        OCCUPIED, Set.of(AVAILABLE),
        UNAVAILABLE, Set.of(AVAILABLE));

    private final ParkingSlotRepository repo;

    public ParkingSlotService(ParkingSlotRepository repo) { this.repo = repo; }

    public List<SlotResponse> list(SlotType type, SlotStatus status) {
        Stream<ParkingSlot> s = repo.findAll().stream().sorted(Comparator.comparing(ParkingSlot::getSlotNumber));
        if (type != null) s = s.filter(x -> x.getSlotType() == type);
        if (status != null) s = s.filter(x -> x.getStatus() == status);
        return s.map(SlotResponse::from).toList();
    }

    public List<SlotResponse> available() {
        return repo.findByStatusOrderBySlotNumber(AVAILABLE).stream().map(SlotResponse::from).toList();
    }

    public SlotResponse get(Long id) { return SlotResponse.from(find(id)); }

    @Transactional
    public SlotResponse create(CreateSlotRequest r) {
        if (repo.existsBySlotNumber(r.slotNumber()))
            throw new ApiException(HttpStatus.CONFLICT, "SLOT_EXISTS", "Slot " + r.slotNumber() + " already exists");
        ParkingSlot s = new ParkingSlot();
        s.setSlotNumber(r.slotNumber());
        s.setSlotType(r.slotType());
        s.setFloor(r.floor());
        return SlotResponse.from(repo.save(s));
    }

    @Transactional
    public void delete(Long id) {
        ParkingSlot s = find(id);
        if (s.getStatus() != AVAILABLE && s.getStatus() != UNAVAILABLE)
            throw new ApiException(HttpStatus.CONFLICT, "SLOT_IN_USE", "Only AVAILABLE or UNAVAILABLE slots can be removed");
        repo.delete(s);
    }

    @Transactional
    public SlotResponse changeStatus(Long id, SlotStatus to) {
        ParkingSlot s = find(id);
        move(s, to);
        return SlotResponse.from(repo.save(s));
    }

    @Transactional
    public SlotResponse reserve(Long id, String vehicle) {
        find(id);
        if (repo.reserve(id, vehicle) == 0)
            throw new ApiException(HttpStatus.CONFLICT, "SLOT_NOT_AVAILABLE", "Slot " + id + " is not available");
        return SlotResponse.from(find(id));
    }

    @Transactional
    public SlotResponse release(Long id) {
        ParkingSlot s = find(id);
        if (s.getStatus() != RESERVED && s.getStatus() != OCCUPIED) throw invalid(s, AVAILABLE);
        s.setStatus(AVAILABLE);
        s.setVehicleNumber(null);
        return SlotResponse.from(repo.save(s));
    }

    @Transactional
    public SlotResponse entry(Long id) {
        ParkingSlot s = find(id);
        if (s.getStatus() != RESERVED) throw invalid(s, OCCUPIED);
        s.setStatus(OCCUPIED);
        return SlotResponse.from(repo.save(s));
    }

    @Transactional
    public SlotResponse exit(Long id) {
        ParkingSlot s = find(id);
        if (s.getStatus() != OCCUPIED) throw invalid(s, AVAILABLE);
        s.setStatus(AVAILABLE);
        s.setVehicleNumber(null);
        return SlotResponse.from(repo.save(s));
    }

    private void move(ParkingSlot s, SlotStatus to) {
        if (!ALLOWED.get(s.getStatus()).contains(to)) throw invalid(s, to);
        if (to == AVAILABLE) s.setVehicleNumber(null);
        s.setStatus(to);
    }

    private ApiException invalid(ParkingSlot s, SlotStatus to) {
        return new ApiException(HttpStatus.CONFLICT, "INVALID_TRANSITION", "Cannot move slot from " + s.getStatus() + " to " + to);
    }

    private ParkingSlot find(Long id) {
        return repo.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "SLOT_NOT_FOUND", "Slot " + id + " not found"));
    }
}
