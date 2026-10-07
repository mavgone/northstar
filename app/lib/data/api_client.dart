import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
class TokenStore {
  String? accessToken;
  String? refreshToken;
  bool get hasTokens => accessToken != null && refreshToken != null;
  void set(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
  }
  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
class ApiException implements Exception {
  ApiException(this.message, this.status);
  final String message;
  final int status;
  @override
  String toString() => message;
}
Map<String, dynamic> _decode(http.Response res) {
  if (res.body.isEmpty) return const {};
  return jsonDecode(res.body) as Map<String, dynamic>;
}
Never _throw(http.Response res, {String fallback = 'Request failed.'}) {
  final body = _decode(res);
  final detail = body['detail']?.toString() ?? body['message']?.toString();
  throw ApiException(
    (detail == null || detail.isEmpty) ? '$fallback (${res.statusCode})' : detail,
    res.statusCode,
  );
}
class ApiClient {
  ApiClient({required this.baseUrl, required this.tokens, http.Client? httpClient})
      : _http = httpClient ?? _directClient();
  static http.Client _directClient() {
    final inner = HttpClient()..findProxy = (_) => 'DIRECT';
    return IOClient(inner);
  }
  final String baseUrl;
  final TokenStore tokens;
  final http.Client _http;
  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        if (auth && tokens.accessToken != null) 'Authorization': 'Bearer ${tokens.accessToken}',
      };
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    late http.Response res;
    try {
      res = await _http.post(Uri.parse('$baseUrl$path'), headers: _headers(auth: auth), body: jsonEncode(body));
    } on Exception {
      throw ApiException('Could not reach server. Check connection and retry.', 0);
    }
    if (res.statusCode == 401 && auth && await _tryRefresh()) {
      return post(path, body, auth: true);
    }
    if (res.statusCode >= 400) _throw(res);
    return _decode(res);
  }
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    late http.Response res;
    try {
      res = await _http.put(Uri.parse('$baseUrl$path'), headers: _headers(auth: true), body: jsonEncode(body));
    } on Exception {
      throw ApiException('Could not reach server. Check connection and retry.', 0);
    }
    if (res.statusCode == 401 && await _tryRefresh()) {
      return put(path, body);
    }
    if (res.statusCode >= 400) _throw(res);
    return _decode(res);
  }
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    late http.Response res;
    try {
      res = await _http.patch(Uri.parse('$baseUrl$path'), headers: _headers(auth: true), body: jsonEncode(body));
    } on Exception {
      throw ApiException('Could not reach server. Check connection and retry.', 0);
    }
    if (res.statusCode == 401 && await _tryRefresh()) {
      return patch(path, body);
    }
    if (res.statusCode >= 400) _throw(res);
    return _decode(res);
  }
  Future<dynamic> get(String path) async {
    late http.Response res;
    try {
      res = await _http.get(Uri.parse('$baseUrl$path'), headers: _headers(auth: true));
    } on Exception {
      throw ApiException('Could not reach server. Check connection and retry.', 0);
    }
    if (res.statusCode == 401 && await _tryRefresh()) {
      return get(path);
    }
    if (res.statusCode >= 400) _throw(res);
    if (res.body.isEmpty) return const {};
    return jsonDecode(res.body);
  }
  Future<void> delete(String path) async {
    late http.Response res;
    try {
      res = await _http.delete(Uri.parse('$baseUrl$path'), headers: _headers(auth: true));
    } on Exception {
      throw ApiException('Could not reach server. Check connection and retry.', 0);
    }
    if (res.statusCode == 401 && await _tryRefresh()) {
      return delete(path);
    }
    if (res.statusCode >= 400) _throw(res);
  }
  Future<bool> _tryRefresh() async {
    final refresh = tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode >= 400) {
        tokens.clear();
        return false;
      }
      final body = _decode(res);
      tokens.set(body['accessToken'] as String, body['refreshToken'] as String);
      return true;
    } on Exception {
      return false;
    }
  }
  void close() => _http.close();
}
