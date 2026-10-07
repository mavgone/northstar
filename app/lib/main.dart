import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/design/tokens.dart';
import 'data/api_client.dart';
import 'data/bootstrap_auth_repository.dart';
import 'data/synced_notes_repository.dart';
import 'data/token_storage.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      const opts = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(980, 640),
        center: true,
        title: 'Northstar Notes',
      );
      await windowManager.waitUntilReadyToShow(opts, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }
  const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api/v1');
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  BootstrapAuthRepository? bootstrapAuth;
  SyncedNotesRepository? syncedNotes;
  if (!useMock) {
    final tokens = TokenStore();
    final storage = TokenStorage(prefs: prefs);
    final healthUrl = apiBaseUrl.replaceFirst('/api/v1', '/actuator/health');
    bootstrapAuth = BootstrapAuthRepository(baseUrl: apiBaseUrl, tokens: tokens, storage: storage, prefs: prefs);
    syncedNotes = SyncedNotesRepository(tokens: tokens, baseUrl: apiBaseUrl, healthUrl: healthUrl);
    try {
      await bootstrapAuth.restoreSession();
    } catch (_) {}
  }
  AppThemeId initialTheme = AppThemeId.dark;
  double initialZoom = 1.0;
  try {
    final saved = prefs?.getString('app.theme');
    if (saved != null) initialTheme = AppThemeId.values.asNameMap()[saved] ?? AppThemeId.dark;
    final savedZoom = prefs?.getDouble('app.zoom');
    if (savedZoom != null) initialZoom = savedZoom.clamp(0.8, 1.5);
  } catch (_) {}
  runApp(NoteApp(
    authRepository: bootstrapAuth,
    notesRepository: syncedNotes,
    initialTheme: initialTheme,
    initialZoom: initialZoom,
    prefs: prefs,
  ));
}
