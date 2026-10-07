import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/data/synced_notes_repository.dart';
import 'package:note_app/domain/models.dart';

Note n(String id, String title, String body) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: id,
    title: title,
    body: body,
    folderId: 'Inbox',
    tags: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('skips blank Untitled notes', () {
    final out = SyncedNotesRepository.selectGuestImports([
      n('1', 'Untitled', ''),
    ], {});
    expect(out, isEmpty);
  });

  test('skips exact duplicates', () {
    final out = SyncedNotesRepository.selectGuestImports(
      [n('1', 'Hello', 'world')],
      {'Hello\nworld'},
    );
    expect(out, isEmpty);
  });

  test('takes new notes once even if listed twice', () {
    final out = SyncedNotesRepository.selectGuestImports([
      n('1', 'Hello', 'world'),
      n('2', 'Hello', 'world'),
    ], {});
    expect(out.length, 1);
  });

  test('keeps content notes', () {
    final out = SyncedNotesRepository.selectGuestImports([
      n('1', 'Untitled', 'has body'),
      n('2', 'Has title', ''),
    ], {});
    expect(out.length, 2);
  });
}
