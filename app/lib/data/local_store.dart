import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/models.dart';
class LocalSnapshot {
  const LocalSnapshot({required this.notes, required this.tombstones});
  final List<Note> notes;
  final Set<String> tombstones;
}
class LocalNotesStore {
  LocalNotesStore._(this.userId, this._file);
  final String userId;
  final File _file;
  static Future<LocalNotesStore> open(String userId) async {
    final safe = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dir = await getApplicationSupportDirectory();
    return LocalNotesStore._(userId, File('${dir.path}/northstar_$safe.json'));
  }
  Future<LocalSnapshot> load() async {
    try {
      if (!await _file.exists()) {
        return LocalSnapshot(notes: [], tombstones: {});
      }
      final raw = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      final notes = ((raw['notes'] as List?) ?? const [])
          .map((e) => _noteFromJson(e as Map<String, dynamic>))
          .toList();
      final tombstones = ((raw['tombstones'] as List?) ?? const []).map((e) => e.toString()).toSet();
      return LocalSnapshot(notes: notes, tombstones: tombstones);
    } catch (_) {
      return LocalSnapshot(notes: [], tombstones: {});
    }
  }
  Future<void> save(List<Note> notes, Set<String> tombstones) async {
    try {
      await _file.parent.create(recursive: true);
      final data = {
        'notes': notes.map(_noteToJson).toList(),
        'tombstones': tombstones.toList(),
      };
      await _file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
  static Map<String, dynamic> _noteToJson(Note n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'folderId': n.folderId,
        'tags': n.tags,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
        'isFavorite': n.isFavorite,
        'status': n.status.name,
      };
  static Note _noteFromJson(Map<String, dynamic> json) => Note(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Untitled').toString(),
        body: (json['body'] ?? '').toString(),
        folderId: (json['folderId'] ?? 'Inbox').toString(),
        tags: ((json['tags'] as List?) ?? const []).map((t) => t.toString()).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isFavorite: (json['isFavorite'] ?? false) as bool,
        status: NoteStatus.values.asNameMap()[json['status']] ?? NoteStatus.active,
      );
}
