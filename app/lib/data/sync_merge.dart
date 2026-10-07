import '../domain/models.dart';

List<Note> mergeNotes({
  required List<Note> local,
  required List<Note> remote,
  required Set<String> tombstones,
}) {
  final byId = <String, Note>{for (final n in local) n.id: n};
  for (final r in remote) {
    if (tombstones.contains(r.id)) continue;
    final l = byId[r.id];
    if (l == null) {
      byId[r.id] = r;
    } else if (r.updatedAt.isAfter(l.updatedAt)) {
      byId[r.id] = r;
    }
  }
  byId.removeWhere((id, _) => tombstones.contains(id));
  return byId.values.toList();
}
