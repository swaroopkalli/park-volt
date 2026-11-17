CREATE TABLE bookings(
  id BIGSERIAL PRIMARY KEY, user_id VARCHAR(40) NOT NULL, slot_id BIGINT NOT NULL,
  slot_number VARCHAR(10) NOT NULL, slot_type VARCHAR(12) NOT NULL,
  vehicle_number VARCHAR(20) NOT NULL, booking_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  check_in_time TIMESTAMPTZ, check_out_time TIMESTAMPTZ,
  status VARCHAR(12) NOT NULL, parking_fee NUMERIC(10,2));
CREATE UNIQUE INDEX uq_bookings_active_slot ON bookings(slot_id) WHERE status IN ('CONFIRMED','ACTIVE');
