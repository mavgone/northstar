import 'dart:async';
import 'dart:io';

class ConnectionMonitor {
  ConnectionMonitor({required this.healthUrl});
  final String healthUrl;
  final _ctrl = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _online = true;
  bool _started = false;
  Stream<bool> get changes => _ctrl.stream;
  bool get online => _online;
  void start() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => check());
    unawaited(check());
  }

  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> check() async {
    final client = HttpClient()..findProxy = (_) => 'DIRECT';
    try {
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(Uri.parse(healthUrl));
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain();
      _set(res.statusCode < 500);
    } catch (_) {
      _set(false);
    } finally {
      client.close(force: true);
    }
    return _online;
  }

  void _set(bool value) {
    if (_online == value) return;
    _online = value;
    if (!_ctrl.isClosed) _ctrl.add(value);
  }

  void dispose() {
    stop();
    unawaited(_ctrl.close());
  }
}
