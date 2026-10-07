import 'package:flutter/foundation.dart';
import '../../data/auth_repository.dart';
import '../../data/bootstrap_auth_repository.dart';
import '../../domain/models.dart';
enum AuthScreen { login, register }
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo);
  final AuthRepository _repo;
  AppUser? user;
  bool busy = false;
  String? error;
  String? info;
  AuthScreen screen = AuthScreen.login;
  bool get isAuthed => user != null;
  void show(AuthScreen s) {
    screen = s;
    error = null;
    info = null;
    notifyListeners();
  }
  Future<bool> signIn(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repo.signIn(email: email.trim(), password: password);
      return true;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Unexpected error. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
  Future<bool> signUp(String name, String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repo.signUp(name: name, email: email.trim(), password: password);
      return true;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Unexpected error. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
  Future<void> signOut() async {
    await _repo.signOut();
    user = null;
    screen = AuthScreen.login;
    notifyListeners();
  }
  Future<void> continueAsGuest() async {
    final repo = _repo;
    if (repo is! BootstrapAuthRepository) {
      error = 'Guest mode needs the backend build.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await repo.continueAsGuest();
    } on AuthException catch (e) {
      error = e.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
  void syncFromRepository() {
    final current = _repo.currentUser;
    if (current != null && user?.id != current.id) {
      user = current;
      notifyListeners();
    }
  }
  Future<bool> rename(String name) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repo.updateProfile(name: name);
      return true;
    } on AuthException catch (e) {
      error = e.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
