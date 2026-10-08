import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/tokens.dart';
import '../../data/notes_repository.dart';
import '../../data/synced_notes_repository.dart';
import '../../domain/models.dart';

enum NotesView { all, favorites, trash }

class NotesViewModel extends ChangeNotifier {
  NotesViewModel(this._repo) {
    final repo = _repo;
    if (repo is ChangeNotifier) {
      (repo as ChangeNotifier).addListener(_forwardRepo);
    }
  }
  final NotesRepository _repo;
  SyncedNotesRepository? get _synced {
    final repo = _repo;
    return repo is SyncedNotesRepository ? repo : null;
  }

  bool get isOffline {
    final synced = _synced;
    return synced != null && !synced.online;
  }

  int get pendingCount => _synced?.pendingCount ?? 0;
  void _forwardRepo() => notifyListeners();
  List<Note> get allNotes => List<Note>.unmodifiable(_all);
  List<Note> backlinksFor(Note note) {
    if (note.title.trim().isEmpty) return const [];
    final t = RegExp.escape(note.title);
    final direct = RegExp('\\[\\[$t\\](?:\\|[^\\]]+)?\\]');
    final aliased = RegExp('\\[\\[[^\\]\n]*\\|$t\\]');
    return _all
        .where(
          (n) =>
              n.id != note.id &&
              (direct.hasMatch(n.body) || aliased.hasMatch(n.body)),
        )
        .toList();
  }

  void reselect(String oldId, String newId) {
    if (selectedId == oldId) {
      selectedId = newId;
      final synced = _synced;
      if (synced != null) {
        final fresh = synced.byId(newId);
        if (fresh != null) {
          _all.removeWhere((n) => n.id == oldId || n.id == newId);
          _all.insert(0, fresh);
        }
      }
      notifyListeners();
    }
  }

  Future<int> guestNotesCount() async {
    final synced = _synced;
    if (synced == null) return 0;
    return synced.guestNotesCount();
  }

  Future<int> importGuestNotes() async {
    final synced = _synced;
    if (synced == null) return 0;
    final count = await synced.importGuestNotes();
    await load();
    return count;
  }

  bool loading = true;
  String? error;
  List<Note> _all = [];
  List<NoteFolder> folders = [];
  Timer? _debounce;
  String query = '';
  NotesView view = NotesView.all;
  String? folderId;
  String? tagFilter;
  SortMode sort = SortMode.modifiedDesc;
  String? selectedId;
  bool sidebarCollapsed = false;
  int _loadGen = 0;
  List<Note> get visible {
    Iterable<Note> list = _all;
    switch (view) {
      case NotesView.all:
        list = list.where((n) => n.status == NoteStatus.active);
        break;
      case NotesView.favorites:
        list = list.where((n) => n.status == NoteStatus.active && n.isFavorite);
        break;
      case NotesView.trash:
        list = list.where((n) => n.status == NoteStatus.trashed);
        break;
    }
    if (folderId != null && view == NotesView.all) {
      list = list.where((n) => n.folderId == folderId);
    }
    if (tagFilter != null) {
      list = list.where((n) => n.tags.contains(tagFilter));
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (n) =>
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q) ||
            n.tags.any((t) => t.contains(q)),
      );
    }
    final out = list.toList();
    switch (sort) {
      case SortMode.modifiedDesc:
        out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortMode.modifiedAsc:
        out.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortMode.titleAsc:
        out.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortMode.createdDesc:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return out;
  }

  Note? get selected {
    if (selectedId == null) return null;
    for (final n in _all) {
      if (n.id == selectedId) return n;
    }
    return null;
  }

  int get trashCount =>
      _all.where((n) => n.status == NoteStatus.trashed).length;
  int get totalActive =>
      _all.where((n) => n.status == NoteStatus.active).length;
  int get favCount =>
      _all.where((n) => n.status == NoteStatus.active && n.isFavorite).length;
  List<String> get allTags {
    final s = <String>{};
    for (final n in _all) {
      s.addAll(n.tags);
    }
    final l = s.toList()..sort();
    return l;
  }

  int countIn(String fid) => _all
      .where((n) => n.folderId == fid && n.status == NoteStatus.active)
      .length;
  int countForTag(String tag) => _all.where((n) => n.tags.contains(tag)).length;
  String folderName(String fid) {
    for (final f in folders) {
      if (f.id == fid) return f.name;
    }
    return 'Inbox';
  }

  String get inboxId {
    for (final f in folders) {
      if (f.name == 'Inbox' && f.parentId == null) return f.id;
    }
    return folders.isNotEmpty ? folders.first.id : 'Inbox';
  }

  List<NoteFolder> childrenOf(String? parentId) {
    final out = folders.where((f) => f.parentId == parentId).toList();
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  String folderPath(String fid) {
    final byId = {for (final f in folders) f.id: f};
    final parts = <String>[];
    var current = byId[fid];
    var guard = 0;
    while (current != null && guard++ < 32) {
      parts.insert(0, current.name);
      final parent = current.parentId;
      current = parent == null ? null : byId[parent];
    }
    return parts.isEmpty ? 'Inbox' : parts.join(' / ');
  }

  int countRecursive(String fid) {
    final ids = <String>{fid};
    var grew = true;
    while (grew) {
      grew = false;
      for (final f in folders) {
        if (f.parentId != null && ids.contains(f.parentId) && ids.add(f.id)) {
          grew = true;
        }
      }
    }
    return _all.where((n) => ids.contains(n.folderId) && n.status == NoteStatus.active).length;
  }

  Future<void> createFolder({required String name, String? parentId}) async {
    await _repo.createFolder(name: name, parentId: parentId);
    folders = await _repo.loadFolders();
    notifyListeners();
  }

  Future<void> renameFolder({required String id, required String name}) async {
    await _repo.renameFolder(id: id, name: name);
    folders = await _repo.loadFolders();
    notifyListeners();
  }

  Future<void> moveFolder({required String id, String? parentId}) async {
    await _repo.moveFolder(id: id, parentId: parentId);
    folders = await _repo.loadFolders();
    notifyListeners();
  }

  Future<void> deleteFolder(String id) async {
    await _repo.deleteFolder(id);
    if (folderId != null && !_folderExists(folderId!)) {
      folderId = null;
    }
    folders = await _repo.loadFolders();
    await load();
  }

  bool _folderExists(String fid) => folders.any((f) => f.id == fid);

  static List<Note> _unique(List<Note> notes) {
    final seen = <String>{};
    return notes.where((n) => seen.add(n.id)).toList();
  }

  Future<void> load() async {
    final gen = ++_loadGen;
    loading = true;
    error = null;
    notifyListeners();
    try {
      folders = await _repo.loadFolders();
      if (gen != _loadGen) return;
      _all = _unique((await _repo.loadNotes()).toList());
      if (gen != _loadGen) return;
      if (selectedId == null || !_all.any((n) => n.id == selectedId)) {
        selectedId = visible.isNotEmpty ? visible.first.id : null;
      }
    } catch (e) {
      if (gen != _loadGen) return;
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (gen == _loadGen) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void setQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      query = v;
      notifyListeners();
    });
  }

  void setView(NotesView v) {
    view = v;
    folderId = null;
    tagFilter = null;
    final vis = visible;
    if (vis.isNotEmpty) selectedId = vis.first.id;
    notifyListeners();
  }

  void setFolder(String? fid) {
    folderId = fid;
    view = NotesView.all;
    tagFilter = null;
    final vis = visible;
    if (vis.isNotEmpty) selectedId = vis.first.id;
    notifyListeners();
  }

  void setTag(String? tag) {
    tagFilter = tag;
    notifyListeners();
  }

  void setSort(SortMode s) {
    sort = s;
    notifyListeners();
  }

  void select(String id) {
    if (selectedId == id) return;
    selectedId = id;
    notifyListeners();
  }

  void toggleSidebar() {
    sidebarCollapsed = !sidebarCollapsed;
    notifyListeners();
  }

  Future<void> create({String? inFolder}) async {
    final note = await _repo.createNote(
      folderId: inFolder ?? folderId ?? inboxId,
    );
    _all.removeWhere((n) => n.id == note.id);
    _all.insert(0, note);
    selectedId = note.id;
    if (view == NotesView.trash) view = NotesView.all;
    notifyListeners();
  }

  Future<void> patch(
    Note note, {
    String? title,
    String? body,
    List<String>? tags,
    String? fId,
    bool? fav,
    NoteStatus? status,
  }) async {
    final next = note.copyWith(
      title: title,
      body: body,
      tags: tags,
      folderId: fId,
      isFavorite: fav,
      status: status,
      updatedAt: DateTime.now(),
    );
    final saved = await _repo.saveNote(next);
    _all.removeWhere((n) => n.id == note.id || n.id == saved.id);
    _all.insert(0, saved);
    notifyListeners();
  }

  Future<void> moveTo(Note note, String newFolderId) async {
    await patch(note, fId: newFolderId);
  }

  Future<void> toTrash(Note note) async {
    await patch(note, status: NoteStatus.trashed);
    final vis = visible;
    selectedId = vis.isNotEmpty ? vis.first.id : null;
    notifyListeners();
  }

  Future<void> restore(Note note) async {
    await patch(note, status: NoteStatus.active);
    notifyListeners();
  }

  Future<void> deleteForever(Note note) async {
    await _repo.deleteForever(note.id);
    _all.removeWhere((n) => n.id == note.id);
    final vis = visible;
    selectedId = vis.isNotEmpty ? vis.first.id : null;
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final ids = _all
        .where((n) => n.status == NoteStatus.trashed)
        .map((n) => n.id)
        .toList();
    for (final id in ids) {
      try {
        await _repo.deleteForever(id);
      } catch (_) {}
    }
    _all.removeWhere((n) => ids.contains(n.id));
    selectedId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    final repo = _repo;
    if (repo is ChangeNotifier) {
      (repo as ChangeNotifier).removeListener(_forwardRepo);
    }
    _debounce?.cancel();
    super.dispose();
  }
}

class AppState extends ChangeNotifier {
  AppState({
    AppThemeId initial = AppThemeId.dark,
    double initialZoom = 1.0,
    SharedPreferences? prefs,
  }) : theme = initial,
       zoom = initialZoom.clamp(_minZoom, _maxZoom),
       _prefs = prefs;
  static const prefsKey = 'app.theme';
  static const zoomPrefsKey = 'app.zoom';
  static const _minZoom = 0.8;
  static const _maxZoom = 1.5;
  AppThemeId theme;
  double zoom;
  final SharedPreferences? _prefs;
  bool get isDark => theme != AppThemeId.light;
  void setTheme(AppThemeId id) {
    if (theme == id) return;
    theme = id;
    try {
      _prefs?.setString(prefsKey, id.name);
    } catch (_) {}
    notifyListeners();
  }

  void setZoom(double value) {
    final next = value.clamp(_minZoom, _maxZoom);
    if (zoom == next) return;
    zoom = next;
    try {
      _prefs?.setDouble(zoomPrefsKey, next);
    } catch (_) {}
    notifyListeners();
  }

  void zoomIn() => setZoom(zoom + 0.1);
  void zoomOut() => setZoom(zoom - 0.1);
  void zoomReset() => setZoom(1.0);
}
