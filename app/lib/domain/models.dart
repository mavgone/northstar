enum NoteStatus { active, trashed }

enum SortMode { modifiedDesc, modifiedAsc, titleAsc, createdDesc }

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.folderId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.status = NoteStatus.active,
  });
  final String id;
  final String title;
  final String body;
  final String folderId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final NoteStatus status;
  Note copyWith({
    String? title,
    String? body,
    String? folderId,
    List<String>? tags,
    DateTime? updatedAt,
    bool? isFavorite,
    NoteStatus? status,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      folderId: folderId ?? this.folderId,
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
    );
  }

  String get preview {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return 'No additional text';
    return flat.length > 110 ? '${flat.substring(0, 110)}…' : flat;
  }

  int get wordCount {
    final t = ('$title $body').trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

class NoteFolder {
  const NoteFolder({required this.id, required this.name, this.icon = 0});
  final String id;
  final String name;
  final int icon;
  NoteFolder copyWith({String? name}) =>
      NoteFolder(id: id, name: name ?? this.name);
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
}
