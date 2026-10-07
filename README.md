# Northstar Notes

Obsidian-style notes: Flutter app + Spring Boot backend, one repo.

```
northstar/
  app/       # Flutter (Windows + Linux + Web).
  backend/   # Spring Boot 3.3 + Java 21 (JWT auth, notes CRUD, Flyway, Postgres).
```

## Backend (local dev)

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=local   # H2, no Docker needed
```

## Backend (prod, docker)

```bash
cd backend
cp .env.example .env   # fill DB_PASSWORD + JWT_SECRET
SPRING_PROFILES_ACTIVE=prod docker compose up -d --build
```

## App (desktop, against prod)

```bash
cd app
flutter run -d linux --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://31.76.245.93:8080/api/v1
```

Without flags the app runs fully offline on in-memory mocks.

## CI

Tag `v*` (or manual Run) builds Windows + Linux release bundles.
Repo variable required: `API_BASE_URL`.
