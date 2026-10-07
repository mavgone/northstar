import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import 'api_client.dart';
import 'auth_repository.dart';
import 'http_auth_repository.dart';
import 'local_auth_repository.dart';
import 'token_storage.dart';

enum SessionMode { online, offline, guest }

class BootstrapAuthRepository implements AuthRepository {
  BootstrapAuthRepository({
    required String baseUrl,
    required TokenStore tokens,
    required TokenStorage storage,
    SharedPreferences? prefs,
  }) : _baseUrl = baseUrl,
       _tokens = tokens,
       _storage = storage,
       _prefs = prefs;
  final String _baseUrl;
  final TokenStore _tokens;
  final TokenStorage _storage;
  final SharedPreferences? _prefs;
  final _ctrl = StreamController<AppUser?>.broadcast();
  AuthRepository? _delegate;
  SessionMode _mode = SessionMode.online;
  ApiClient? _sharedApi;
  HttpAuthRepository? _sharedRemote;
  SessionMode get mode => _mode;
  bool get isGuest => _mode == SessionMode.guest;
  bool get isOffline => _mode == SessionMode.offline;
  @override
  Stream<AppUser?> get userChanges => _ctrl.stream;
  @override
  AppUser? get currentUser => _delegate?.currentUser;
  void _adopt(AuthRepository delegate, SessionMode mode) {
    _delegate = delegate;
    _mode = mode;
    _ctrl.add(delegate.currentUser);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw AuthException(e.message, statusCode: e.status);
    }
  }

  HttpAuthRepository _remote() {
    final api = _sharedApi ??= ApiClient(baseUrl: _baseUrl, tokens: _tokens);
    return _sharedRemote ??= HttpAuthRepository(
      baseUrl: _baseUrl,
      tokens: _tokens,
      client: api,
      storage: _storage,
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async {
        final remote = _remote();
        try {
          final user = await remote.signIn(email: email, password: password);
          await LocalAuthRepository.remember(user, _prefs);
          _adopt(remote, SessionMode.online);
          return user;
        } on AuthException catch (e) {
          if (e.statusCode != 0) rethrow;
          final cached = LocalAuthRepository.recalled(_prefs, email);
          if (cached == null) {
            throw AuthException(
              'Could not reach server and no saved session for this email.',
            );
          }
          final local = LocalAuthRepository(user: cached, prefs: _prefs);
          _adopt(local, SessionMode.offline);
          return cached;
        }
      });
  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final remote = _remote();
    final user = await remote.signUp(
      name: name,
      email: email,
      password: password,
    );
    await LocalAuthRepository.remember(user, _prefs);
    _adopt(remote, SessionMode.online);
    return user;
  });
  Future<AppUser> continueAsGuest() async {
    const guest = AppUser(id: 'guest', name: 'Guest', email: 'guest@local');
    final local = LocalAuthRepository(user: guest, prefs: _prefs);
    _adopt(local, SessionMode.guest);
    return guest;
  }

  Future<bool> restoreSession() async {
    final remote = _remote();
    try {
      if (await remote.restoreSession()) {
        final user = remote.currentUser!;
        await LocalAuthRepository.remember(user, _prefs);
        _adopt(remote, SessionMode.online);
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<void> signOut() async {
    try {
      await _delegate?.signOut();
    } catch (_) {}
    _delegate = null;
    _mode = SessionMode.online;
    _ctrl.add(null);
  }

  @override
  Future<AppUser> updateProfile({required String name}) => _guard(() async {
    final delegate = _delegate;
    if (delegate == null) throw AuthException('Not signed in.');
    final updated = await delegate.updateProfile(name: name);
    if (_mode == SessionMode.online) {
      await LocalAuthRepository.remember(updated, _prefs);
    }
    _ctrl.add(updated);
    return updated;
  });
}
