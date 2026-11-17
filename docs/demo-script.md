# Demo script

Setup: `docker compose up --build -d`, then `cd frontend && flutter run -d chrome --dart-define=API_BASE=http://localhost:8000/api`.

1. Open the app. The dashboard shows 20 slots.
2. Log in as **Student 1**.
3. Parking tab: tap **P11** (EV), enter a vehicle number, Reserve. Note the booking ID in the confirmation.
4. Switch user (account chip, bottom-left or top-right) to **Admin**: the Admin > Slots tab shows P11 RESERVED.
5. Back as Student 1: Bookings > **Check-in**, then Charging > pick the booking and a free station > **Start**.
6. Watch energy, cost and progress climb live (about 1 kWh per second on a 7 kW charger at the demo multiplier), then **Stop charging**.
7. Bookings > **Complete**: the parking fee is shown (₹30 for the 1-hour minimum on EV) and P11 returns to AVAILABLE.
8. Open Swagger on ports 8001, 8002 and 8003.
9. Show that the app only talks to :8000, and run `docker compose ps` (separate containers, one Postgres with three databases).
10. Fault isolation: `docker compose stop charging-service`. Parking and Bookings still work; the Charging screen shows "Charging service is unavailable"; `curl localhost:8000/api/health` reports DEGRADED. Restore with `docker compose start charging-service`.

## API-only rehearsal (no UI)

```bash
G=localhost:8000/api; H='Content-Type: application/json'
curl -s -X POST $G/bookings -H "$H" -d '{"userId":"student1","slotId":11,"vehicleNumber":"KA03AB1234"}'
curl -s -X PATCH $G/bookings/1/check-in
curl -s -X POST $G/charging/sessions/start -H "$H" -d '{"userId":"student1","bookingId":1,"stationId":1}'
curl -s $G/charging/sessions/1          # run twice, a few seconds apart
curl -s -X PATCH $G/charging/sessions/1/stop
curl -s -X PATCH $G/bookings/1/complete
```
