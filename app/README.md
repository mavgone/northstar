# Northstar Notes App

Obsidian-style notes for desktop (Windows + Linux). Flutter frontend for the
Spring Boot backend in `../backend` — JWT auth, notes CRUD with offline-first
sync, Markdown preview, task lists, `[[links]]`, guest mode.

## Запуск

```bash
flutter pub get
flutter run -d linux --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://31.76.245.93:8080/api/v1
```

Без флагов — полностью офлайн на in-memory моках (для верстки и тестов).

## Релиз

```bash
flutter build linux --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://31.76.245.93:8080/api/v1
```

Windows собирается только на Windows; CI (`.github/workflows/build.yml`) строит обе платформы по тегу `v*`.
