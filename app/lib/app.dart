import 'dart:async';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/design/theme.dart';
import 'core/design/tokens.dart';
import 'data/auth_repository.dart';
import 'data/notes_repository.dart';
import 'data/synced_notes_repository.dart';
import 'domain/models.dart';
import 'features/auth/auth_screens.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/notes/home_shell.dart';
import 'features/notes/notes_viewmodel.dart' as nv;

bool shouldSeedWelcome({
  required bool done,
  required bool force,
  required bool hasNotes,
  required bool hasWelcome,
}) {
  if (force) return true;
  return !done && !hasWelcome && !hasNotes;
}

class NoteApp extends StatefulWidget {
  const NoteApp({
    super.key,
    this.authRepository,
    this.notesRepository,
    this.initialTheme = AppThemeId.dark,
    this.initialZoom = 1.0,
    this.prefs,
  });
  final AuthRepository? authRepository;
  final NotesRepository? notesRepository;
  final AppThemeId initialTheme;
  final double initialZoom;
  final SharedPreferences? prefs;
  @override
  State<NoteApp> createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  late final AuthRepository _authRepo =
      widget.authRepository ?? MockAuthRepository();
  late final NotesRepository _notesRepo =
      widget.notesRepository ?? MockNotesRepository();
  late final AuthViewModel _auth = AuthViewModel(_authRepo);
  late final nv.NotesViewModel _notes = nv.NotesViewModel(_notesRepo);
  late final nv.AppState _appState = nv.AppState(
    initial: widget.initialTheme,
    initialZoom: widget.initialZoom,
    prefs: widget.prefs,
  );
  StreamSubscription<AppUser?>? _userSub;
  int _sessionGen = 0;
  bool _seeding = false;
  @override
  void initState() {
    super.initState();
    _auth.syncFromRepository();
    final synced = _notesRepo;
    if (synced is SyncedNotesRepository) {
      synced.onRemap = _notes.reselect;
      final user = _authRepo.currentUser;
      if (user != null) {
        final gen = ++_sessionGen;
        synced
            .openUser(user.id, enableRemote: user.id != 'guest')
            .then((_) => _notes.load())
            .then((_) {
              if (gen == _sessionGen && mounted) _seedWelcome(user.id);
            });
      }
      _userSub = _authRepo.userChanges.listen((u) async {
        final gen = ++_sessionGen;
        if (u == null) {
          await synced.closeUser();
        } else {
          await synced.openUser(u.id, enableRemote: u.id != 'guest');
          if (gen != _sessionGen || !mounted) return;
          await _notes.load();
          if (gen != _sessionGen || !mounted) return;
          await _seedWelcome(u.id);
        }
      });
    }
  }

  Future<void> reseedWelcome() async {
    try {
      final user = _authRepo.currentUser;
      if (user == null) return;
      await _seedWelcome(user.id, force: true);
    } catch (_) {}
  }

  Future<void> _seedWelcome(String userId, {bool force = false}) async {
    if (_seeding) return;
    _seeding = true;
    try {
      final key = 'welcomed_$userId';
      bool done = false;
      try {
        done = widget.prefs?.getBool(key) ?? false;
      } catch (_) {}
      final hasWelcome = _notes.allNotes.any(
        (n) => n.title == 'Добро пожаловать',
      );
      if (!shouldSeedWelcome(
        done: done,
        force: force,
        hasNotes: _notes.allNotes.isNotEmpty,
        hasWelcome: hasWelcome,
      )) {
        try {
          await widget.prefs?.setBool(key, true);
        } catch (_) {}
        return;
      }
      await _notes.create(inFolder: 'Inbox');
      final note = _notes.selected;
      if (note != null) {
        await _notes.patch(note, title: 'Добро пожаловать', body: _welcomeBody);
      }
      try {
        await widget.prefs?.setBool(key, true);
      } catch (_) {}
    } finally {
      _seeding = false;
    }
  }

  static const _welcomeBody =
      '''Это живое демо Northstar - всё ниже можно трогать.
# Задачи
[ ] Нажми на этот чекбокс в режиме просмотра (глаз вверху)
[ ] Создай свою заметку через Ctrl+N
# Связи
Напиши [[Добро пожаловать]] - получишь ссылку. Клик открывает заметку, а если её нет - создает. Печатай [[ и выбирай из списка.
# Заголовки
# H1 - большой
## H2 - средний
### H3 - маленький
# Горячие клавиши
Новая заметка - Ctrl+N, поиск - Ctrl+F, палитра - Ctrl+K, сайдбар - Ctrl+B, зум - Ctrl+плюс/минус/0. Удалить - Delete или перетащи на Trash.
# Синхронизация
Вошел в аккаунт - заметки на сервере. Нет сети - работаешь локально, всё догонит само. Гость живет только на этом устройстве.''';
  @override
  void dispose() {
    _userSub?.cancel();
    _auth.dispose();
    _notes.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final themeId = _appState.theme;
        final materialTheme = switch (themeId) {
          AppThemeId.light => AppTheme.light(),
          AppThemeId.dark => AppTheme.dark(),
          AppThemeId.lain => AppTheme.lain(),
        };
        return ShadApp(
          title: 'Northstar Notes',
          debugShowCheckedModeBanner: false,
          themeMode: themeId == AppThemeId.light
              ? ThemeMode.light
              : ThemeMode.dark,
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadSlateColorScheme.light(),
          ),
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadSlateColorScheme.dark(),
          ),
          materialThemeBuilder: (context, theme) => materialTheme,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: const [
              Breakpoint(start: 0, end: 760, name: 'MOBILE'),
              Breakpoint(start: 761, end: 1100, name: 'TABLET'),
              Breakpoint(start: 1101, end: double.infinity, name: 'DESKTOP'),
            ],
            child: child!,
          ),
          home: AuthGate(
            vm: _auth,
            child: HomeShell(
              notes: _notes,
              auth: _auth,
              themeId: themeId,
              onTheme: _appState.setTheme,
              zoom: _appState.zoom,
              onZoom: _appState.setZoom,
              onWelcome: reseedWelcome,
            ),
          ),
        );
      },
    );
  }
}
