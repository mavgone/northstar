import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import 'auth_repository.dart';
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({required AppUser user, SharedPreferences? prefs})
      : _user = user,
        _prefs = prefs;
  static const lastIdKey = 'auth.last_id';
  static const lastNameKey = 'auth.last_name';
  static const lastEmailKey = 'auth.last_email';
  final SharedPreferences? _prefs;
  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  @override
  Stream<AppUser?> get userChanges => _ctrl.stream;
  @override
  AppUser? get currentUser => _user;
  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    if (_user == null) throw AuthException('No local session. Sign in online first.');
    return _user!;
  }
  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    throw AuthException('Sign up needs connection. Try again when online.');
  }
  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }
  @override
  Future<AppUser> updateProfile({required String name}) async {
    final current = _user;
    if (current == null) throw AuthException('No local session.');
    if (name.trim().length < 2) throw AuthException('Name is too short.');
    _user = AppUser(id: current.id, name: name.trim(), email: current.email);
    try {
      if (current.id != 'guest') {
        await _prefs?.setString(lastNameKey, name.trim());
      }
    } catch (_) {}
    _ctrl.add(_user);
    return _user!;
  }
  static Future<void> remember(AppUser user, SharedPreferences? prefs) async {
    try {
      await prefs?.setString(lastIdKey, user.id);
      await prefs?.setString(lastNameKey, user.name);
      await prefs?.setString(lastEmailKey, user.email);
    } catch (_) {}
  }
  static AppUser? recalled(SharedPreferences? prefs, String email) {
    try {
      final savedEmail = prefs?.getString(lastEmailKey);
      if (savedEmail == null || savedEmail.toLowerCase() != email.trim().toLowerCase()) {
        return null;
      }
      return AppUser(
        id: prefs?.getString(lastIdKey) ?? 'local',
        name: prefs?.getString(lastNameKey) ?? savedEmail,
        email: savedEmail,
      );
    } catch (_) {
      return null;
    }
  }
}
