import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({SharedPreferences? prefs}) : _prefs = prefs;
  static const _accessKey = 'northstar.access';
  static const _refreshKey = 'northstar.refresh';
  final SharedPreferences? _prefs;
  Future<TokenPair?> read() async {
    try {
      final access = _prefs?.getString(_accessKey);
      final refresh = _prefs?.getString(_refreshKey);
      if (access != null && refresh != null) {
        return TokenPair(access: access, refresh: refresh);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String access, String refresh) async {
    try {
      await _prefs?.setString(_accessKey, access);
      await _prefs?.setString(_refreshKey, refresh);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _prefs?.remove(_accessKey);
      await _prefs?.remove(_refreshKey);
    } catch (_) {}
  }
}

class TokenPair {
  const TokenPair({required this.access, required this.refresh});
  final String access;
  final String refresh;
}
