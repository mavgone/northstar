import '../domain/models.dart';
import 'api_client.dart';
import 'notes_repository.dart';

class HttpNotesRepository implements NotesRepository {
  HttpNotesRepository({required ApiClient client}) : _api = client;
  final ApiClient _api;
  List<Note>? _cached;
  static NoteStatus _status(String? raw) => switch (raw) {
    'trashed' => NoteStatus.trashed,
    _ => NoteStatus.active,
  };
  static Note _toNote(Map<String, dynamic> json) => Note(
    id: json['id'].toString(),
    title: (json['title'] ?? 'Untitled').toString(),
    body: (json['body'] ?? '').toString(),
    folderId: (json['folder'] ?? json['folderId'] ?? 'Inbox').toString(),
    tags: ((json['tags'] as List?) ?? const [])
        .map((t) => t.toString())
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isFavorite: (json['isFavorite'] ?? json['favorite'] ?? false) as bool,
    status: _status(json['status']?.toString()),
  );
  @override
  Future<List<Note>> loadNotes() async {
    final raw = await _api.get('/notes') as List;
    _cached = raw.map((e) => _toNote(e as Map<String, dynamic>)).toList();
    return List<Note>.unmodifiable(_cached!);
  }

  static NoteFolder _toFolder(Map<String, dynamic> json) => NoteFolder(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        parentId: json['parentId']?.toString(),
      );
  @override
  Future<List<NoteFolder>> loadFolders() async {
    final raw = await _api.get('/folders') as List;
    return raw.map((e) => _toFolder(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Note> saveNote(Note note) async {
    final body = await _api.patch('/notes/${note.id}', {
      'title': note.title,
      'body': note.body,
      'folderId': note.folderId,
      'tags': note.tags,
      'isFavorite': note.isFavorite,
      'status': note.status.name,
    });
    final saved = _toNote(body);
    _cached = null;
    return saved;
  }

  @override
  Future<void> deleteForever(String id) async {
    await _api.delete('/notes/$id');
    _cached = null;
  }

  @override
  Future<Note> createNote({required String folderId}) async {
    final body = await _api.post('/notes', {'folderId': folderId}, auth: true);
    _cached = null;
    return _toNote(body);
  }

  @override
  Future<NoteFolder> createFolder({required String name, String? parentId}) async {
    final body = await _api.post('/folders', {
      'name': name,
      ...?parentId == null ? null : {'parentId': parentId},
    }, auth: true);
    return _toFolder(body);
  }

  @override
  Future<NoteFolder> renameFolder({required String id, required String name}) async {
    final body = await _api.patch('/folders/$id', {'name': name});
    return _toFolder(body);
  }

  @override
  Future<void> moveFolder({required String id, String? parentId}) async {
    if (parentId == null) {
      await _api.patch('/folders/$id/move-to-root', {});
    } else {
      await _api.patch('/folders/$id', {'parentId': parentId});
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _api.delete('/folders/$id');
  }
}
