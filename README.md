# ParkVolt

Smart parking and EV charging platform: three Spring Boot microservices behind a Spring Cloud Gateway, PostgreSQL 16, and a Flutter web/mobile app. Demo-grade: no real auth, payments or hardware.

```
Flutter app -> API Gateway :8000 -> parking-service :8001 -> parking_db
                                 -> booking-service :8002 -> booking_db   (calls parking)
                                 -> charging-service :8003 -> charging_db (calls booking)
```

Details: [docs/architecture.md](docs/architecture.md) · demo walkthrough: [docs/demo-script.md](docs/demo-script.md)

## Run with Docker (recommended)

```bash
docker compose up --build -d
docker compose ps            # 5 containers, all healthy
curl localhost:8000/api/health
```

| What | URL |
|---|---|
| Gateway (what the app talks to) | http://localhost:8000/api |
| Parking Swagger | http://localhost:8001/swagger-ui.html |
| Booking Swagger | http://localhost:8002/swagger-ui.html |
| Charging Swagger | http://localhost:8003/swagger-ui.html |
| Postgres (host port) | `localhost:5433`, user `postgres` / `postgres` |

Each service has its own database and DB user (`parking_user`, `booking_user`, `charging_user`); no service reads another's database.

## Run locally (without Docker for the apps)

Needs Java 21+ and Maven. Start Postgres only: `docker compose up -d postgres`, then in each of `services/*-service` and `api-gateway`:

```bash
mvn spring-boot:run
```

Defaults point at `localhost:5433` and `localhost:800x`; override with `DB_URL`, `PARKING_URL`, `BOOKING_URL`, `CHARGING_URL`.

## Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000/api
```

Demo logins (no password): **Student 1**, **Student 2**, **Admin**. The Admin tab is hidden for students and the gateway rejects admin routes without `X-User-Role: ADMIN`.

## Tests

```bash
cd services/parking-service  && mvn test   # 8 concurrent reservations -> exactly one wins
cd services/booking-service  && mvn test   # compensation, 503 saves nothing, fee rounding
cd services/charging-service && mvn test   # energy / cost math
cd frontend && flutter test                # login + all sections at 360/768/1440 px
```

## Pricing and simulation (all in `application.yml`)

Parking ₹20/hr regular and accessible, ₹30/hr EV, billed in whole hours (minimum 1). Electricity ₹8/kWh. `charging.speed-multiplier` defaults to 60, so one real minute counts as one simulated hour.
