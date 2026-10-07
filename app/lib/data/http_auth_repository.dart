import 'dart:async';
import '../domain/models.dart';
import 'api_client.dart';
import 'auth_repository.dart';
import 'token_storage.dart';
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({required String baseUrl, required TokenStore tokens, ApiClient? client, TokenStorage? storage})
      : _api = client ?? ApiClient(baseUrl: baseUrl, tokens: tokens),
        _tokens = tokens,
        _storage = storage;
  final ApiClient _api;
  final TokenStore _tokens;
  final TokenStorage? _storage;
  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  @override
  Stream<AppUser?> get userChanges => _ctrl.stream;
  @override
  AppUser? get currentUser => _user;
  AppUser _adopt(Map<String, dynamic> body) {
    final access = body['accessToken'] as String;
    final refresh = body['refreshToken'] as String;
    _tokens.set(access, refresh);
    _storage?.write(access, refresh);
    _user = _toUser(body['user'] as Map<String, dynamic>);
    _ctrl.add(_user);
    return _user!;
  }
  static AppUser _toUser(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
      );
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw AuthException(e.message, statusCode: e.status);
    }
  }
  @override
  Future<AppUser> signIn({required String email, required String password}) => _guard(() async {
        final body = await _api.post('/auth/signin', {'email': email.trim(), 'password': password});
        return _adopt(body);
      });
  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) => _guard(() async {
        final body = await _api.post('/auth/signup', {'name': name.trim(), 'email': email.trim(), 'password': password});
        return _adopt(body);
      });
  @override
  Future<void> signOut() async {
    _tokens.clear();
    await _storage?.clear();
    _user = null;
    _ctrl.add(null);
  }
  @override
  Future<AppUser> updateProfile({required String name}) => _guard(() async {
        final body = await _api.patch('/users/me', {'name': name.trim()});
        _user = _toUser(body);
        _ctrl.add(_user);
        return _user!;
      });
  Future<bool> restoreSession() async {
    final storage = _storage;
    if (storage == null) return false;
    final pair = await storage.read();
    if (pair == null) return false;
    _tokens.set(pair.access, pair.refresh);
    try {
      final body = await _api.get('/users/me') as Map<String, dynamic>;
      _user = _toUser(body);
      _ctrl.add(_user);
      return true;
    } on ApiException catch (e) {
      if (e.status != 0) {
        _tokens.clear();
        await storage.clear();
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
