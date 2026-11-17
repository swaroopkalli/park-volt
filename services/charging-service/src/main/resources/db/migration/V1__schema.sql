CREATE TABLE charging_stations(
  id BIGSERIAL PRIMARY KEY, station_name VARCHAR(10) UNIQUE NOT NULL,
  power_kw DOUBLE PRECISION NOT NULL, connector_type VARCHAR(12) NOT NULL,
  status VARCHAR(12) NOT NULL DEFAULT 'AVAILABLE');
CREATE TABLE charging_sessions(
  id BIGSERIAL PRIMARY KEY, user_id VARCHAR(40) NOT NULL, booking_id BIGINT NOT NULL,
  station_id BIGINT NOT NULL REFERENCES charging_stations(id),
  start_time TIMESTAMPTZ NOT NULL, end_time TIMESTAMPTZ,
  target_kwh DOUBLE PRECISION NOT NULL DEFAULT 20,
  energy_kwh DOUBLE PRECISION NOT NULL DEFAULT 0, total_cost NUMERIC(10,2) NOT NULL DEFAULT 0,
  status VARCHAR(12) NOT NULL);
CREATE UNIQUE INDEX uq_sessions_active_station ON charging_sessions(station_id) WHERE status = 'ACTIVE';
