import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/models.dart';
import 'api_client.dart';
import 'connection_monitor.dart';
import 'http_notes_repository.dart';
import 'local_store.dart';
import 'notes_repository.dart';
import 'sync_merge.dart';

class SyncedNotesRepository extends ChangeNotifier implements NotesRepository {
  SyncedNotesRepository({
    required TokenStore tokens,
    required String baseUrl,
    required String healthUrl,
  }) : _tokens = tokens,
       _api = ApiClient(baseUrl: baseUrl, tokens: tokens),
       _monitor = ConnectionMonitor(healthUrl: healthUrl);
  final TokenStore _tokens;
  final ApiClient _api;
  final ConnectionMonitor _monitor;
  LocalNotesStore? _store;
  HttpNotesRepository? _remote;
  List<Note> _mem = [];
  Set<String> _tombstones = {};
  bool _syncing = false;
  bool _loadedOk = false;
  int _pending = 0;
  StreamSubscription<bool>? _monitorSub;
  void Function(String oldId, String newId)? onRemap;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  bool get online => _remote != null && _monitor.online;
  int get pendingCount => _pending;
  int _sessionGen = 0;
  Future<void> openUser(String userId, {bool enableRemote = true}) async {
    await closeUser();
    final gen = ++_sessionGen;
    if (gen != _sessionGen) return;
    _store = await LocalNotesStore.open(userId);
    if (gen != _sessionGen) return;
    final snap = await _store!.load();
    if (gen != _sessionGen) return;
    _mem = List<Note>.of(snap.notes);
    _tombstones = Set<String>.of(snap.tombstones);
    _loadedOk = true;
    if (enableRemote && _tokens.hasTokens) {
      _remote = HttpNotesRepository(client: _api);
      await _monitorSub?.cancel();
      _monitorSub = _monitor.changes.listen((_) {
        if (_monitor.online) unawaited(fullSync());
        notifyListeners();
      });
      _monitor.start();
      unawaited(fullSync());
    }
    notifyListeners();
  }

  Future<void> closeUser() async {
    _sessionGen++;
    await _monitorSub?.cancel();
    _monitorSub = null;
    _monitor.stop();
    _store = null;
    _remote = null;
    _mem = [];
    _tombstones = {};
    _pending = 0;
    _syncing = false;
    _loadedOk = false;
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null || !_loadedOk) return;
    await store.save(_mem, _tombstones);
  }

  Future<void> fullSync() async {
    final remote = _remote;
    if (remote == null || _syncing) return;
    _syncing = true;
    try {
      final pulled = await remote.loadNotes();
      _mem = mergeNotes(local: _mem, remote: pulled, tombstones: _tombstones);
      final deleted = <String>[];
      for (final id in _tombstones) {
        try {
          await remote.deleteForever(id);
          deleted.add(id);
        } catch (_) {}
      }
      _tombstones.removeAll(deleted);
      for (var i = 0; i < _mem.length; i++) {
        final pushed = await _pushOne(remote, _mem[i]);
        if (pushed.id != _mem[i].id) {
          final oldId = _mem[i].id;
          _mem[i] = pushed;
          onRemap?.call(oldId, pushed.id);
        } else {
          _mem[i] = pushed;
        }
      }
      _pending = 0;
      await _persist();
    } catch (_) {
      _pending++;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  static Note _withId(Note n, String id) => Note(
    id: id,
    title: n.title,
    body: n.body,
    folderId: n.folderId,
    tags: List<String>.from(n.tags),
    createdAt: n.createdAt,
    updatedAt: n.updatedAt,
    isFavorite: n.isFavorite,
    status: n.status,
  );
  Future<Note> _pushOne(HttpNotesRepository remote, Note note) async {
    try {
      if (note.id.startsWith('local_')) {
        final created = await remote.createNote(folderId: note.folderId);
        return await remote.saveNote(_withId(note, created.id));
      }
      return await remote.saveNote(note);
    } on ApiException catch (e) {
      if (e.status == 404) {
        final created = await remote.createNote(folderId: note.folderId);
        return await remote.saveNote(_withId(note, created.id));
      }
      rethrow;
    }
  }

  Future<void> _pushBestEffort(
    Future<void> Function(HttpNotesRepository) op,
  ) async {
    final remote = _remote;
    if (remote == null || !_monitor.online) {
      _pending++;
      notifyListeners();
      return;
    }
    try {
      await op(remote);
      if (_pending > 0) {
        _pending--;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _pending++;
      if (e.status == 0) {
        unawaited(_monitor.check());
      }
      notifyListeners();
    } catch (_) {
      _pending++;
      notifyListeners();
    }
  }

  @override
  Future<List<Note>> loadNotes() async {
    return List<Note>.unmodifiable(_mem);
  }

  @override
  Future<List<NoteFolder>> loadFolders() async {
    final names = _mem.map((n) => n.folderId).toSet().toList()..sort();
    if (!names.contains('Inbox')) names.insert(0, 'Inbox');
    return names.map((n) => NoteFolder(id: n, name: n)).toList();
  }

  @override
  Future<Note> saveNote(Note note) async {
    final i = _mem.indexWhere((n) => n.id == note.id);
    if (i == -1) {
      _mem.insert(0, note);
    } else {
      _mem[i] = note;
    }
    await _persist();
    notifyListeners();
    await _pushBestEffort((remote) async {
      final pushed = await _pushOne(remote, note);
      if (pushed.id != note.id) {
        final j = _mem.indexWhere((n) => n.id == note.id);
        if (j != -1) _mem[j] = pushed;
        onRemap?.call(note.id, pushed.id);
        await _persist();
      } else {
        final j = _mem.indexWhere((n) => n.id == note.id);
        if (j != -1) _mem[j] = pushed;
        await _persist();
      }
      notifyListeners();
    });
    final j = _mem.indexWhere((n) => n.id == note.id);
    return j == -1 ? note : _mem[j];
  }

  @override
  Future<void> deleteForever(String id) async {
    _mem.removeWhere((n) => n.id == id);
    _tombstones.add(id);
    await _persist();
    notifyListeners();
    await _pushBestEffort((remote) async {
      try {
        await remote.deleteForever(id);
      } on ApiException catch (e) {
        if (e.status == 404) return;
        rethrow;
      }
      _tombstones.remove(id);
      await _persist();
      notifyListeners();
    });
  }

  Future<int> guestNotesCount() async {
    try {
      final guest = await LocalNotesStore.open('guest');
      final snap = await guest.load();
      return snap.notes.where(_importable).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> importGuestNotes() async {
    if (_store == null) return 0;
    final guest = await LocalNotesStore.open('guest');
    final snap = await guest.load();
    final existing = _mem.map((n) => '${n.title}\n${n.body}').toSet();
    var count = 0;
    final now = DateTime.now();
    for (final g in selectGuestImports(snap.notes, existing)) {
      _mem.insert(
        0,
        Note(
          id: 'local_${const Uuid().v4()}',
          title: g.title,
          body: g.body,
          folderId: g.folderId,
          tags: List<String>.from(g.tags),
          createdAt: now,
          updatedAt: now,
          isFavorite: g.isFavorite,
          status: NoteStatus.active,
        ),
      );
      count++;
    }
    await _persist();
    notifyListeners();
    await guest.save([], {});
    if (count > 0) unawaited(fullSync());
    return count;
  }

  static bool _importable(Note n) {
    final untitled = n.title.trim().isEmpty || n.title == 'Untitled';
    return !(untitled && n.body.trim().isEmpty);
  }

  static List<Note> selectGuestImports(
    List<Note> guest,
    Set<String> existingKeys,
  ) {
    final seen = Set<String>.of(existingKeys);
    final out = <Note>[];
    for (final g in guest) {
      if (!_importable(g)) continue;
      final key = '${g.title}\n${g.body}';
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(g);
    }
    return out;
  }

  @override
  Future<Note> createNote({required String folderId}) async {
    final now = DateTime.now();
    final note = Note(
      id: 'local_${const Uuid().v4()}',
      title: 'Untitled',
      body: '',
      folderId: folderId,
      tags: const [],
      createdAt: now,
      updatedAt: now,
      status: NoteStatus.active,
    );
    _mem.insert(0, note);
    await _persist();
    notifyListeners();
    await _pushBestEffort((remote) async {
      final created = await remote.createNote(folderId: folderId);
      final j = _mem.indexWhere((n) => n.id == note.id);
      if (j != -1) {
        _mem[j] = created;
        onRemap?.call(note.id, created.id);
        await _persist();
      }
      notifyListeners();
    });
    final j = _mem.indexWhere((n) => n.id == note.id);
    return j == -1 ? note : _mem[j];
  }

  @override
  void dispose() {
    _disposed = true;
    _monitorSub?.cancel();
    _monitor.dispose();
    _api.close();
    super.dispose();
  }
}
