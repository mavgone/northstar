import 'dart:async';
import '../domain/models.dart';

abstract class AuthRepository {
  Stream<AppUser?> get userChanges;
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<AppUser> updateProfile({required String name});
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository();
  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  @override
  Stream<AppUser?> get userChanges => _ctrl.stream;
  @override
  AppUser? get currentUser => _user;
  Future<T> _late<T>(T value, [int ms = 650]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return value;
  }

  void _fail(String message) => throw AuthException(message);
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!email.contains('@')) _fail('Enter a valid email address.');
    if (password.length < 6) _fail('Password must be at least 6 characters.');
    if (email.trim().toLowerCase() == 'error@demo.dev') {
      _fail('No account found for this email (mock error state).');
    }
    _user = AppUser(
      id: 'u_mock',
      name: _prettyName(email),
      email: email.trim(),
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (name.trim().length < 2) _fail('Please enter your name.');
    if (!email.contains('@')) _fail('Enter a valid email address.');
    if (password.length < 6) _fail('Password must be at least 6 characters.');
    _user = AppUser(id: 'u_mock', name: name.trim(), email: email.trim());
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    await _late<void>(null, 250);
    _user = null;
    _ctrl.add(null);
  }

  @override
  Future<AppUser> updateProfile({required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (name.trim().length < 2) _fail('Name is too short.');
    _user = AppUser(
      id: _user?.id ?? 'u_mock',
      name: name.trim(),
      email: _user?.email ?? 'you@demo.dev',
    );
    _ctrl.add(_user);
    return _user!;
  }

  String _prettyName(String email) {
    final handle = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    if (handle.isEmpty) return 'Demo User';
    return handle
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
