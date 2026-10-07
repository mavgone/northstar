# Northstar Notes Backend (MVP)

Spring Boot 3.3 + Java 21. Auth (JWT) + notes CRUD под Flutter-фронт `../app`.

## Запуск (dev, локально)

```bash
cp .env.example .env        # задать DB_PASSWORD и JWT_SECRET (мин 32 символа)
docker compose up -d        # postgres:15 + сборка app
# или без docker:
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/northstar
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Swagger: http://localhost:8080/swagger-ui.html

## Проверка

```bash
mvn test                                   # AuthService, NoteController (@WebMvcTest), NoteRepository (@DataJpaTest), JwtService
curl -X POST localhost:8080/api/v1/auth/signup -H 'Content-Type: application/json' \
  -d '{"name":"Demo","email":"demo@obsidian.dev","password":"demo1234"}'
```

## Стык с фронтом

Фронт (`../app/lib/data/`) зависит только от `AuthRepository`/`NotesRepository`.
Реализовать `HttpAuthRepository`/`HttpNotesRepository` на `package:http`:
`signIn/signUp -> POST /api/v1/auth/*`, `loadNotes -> GET /api/v1/notes`,
`createNote -> POST /api/v1/notes, saveNote -> PATCH /api/v1/notes/{id}`. Ошибки бек отдает как
`problem+json {detail}` — кидать как `AuthException(detail)` / `Exception(detail)`.

## Прод (сервер)

```bash
SPRING_PROFILES_ACTIVE=prod SPRING_DATASOURCE_URL=jdbc:postgresql://... \
SPRING_DATASOURCE_USERNAME=... SPRING_DATASOURCE_PASSWORD=... JWT_SECRET=... \
docker compose up -d --build
```
