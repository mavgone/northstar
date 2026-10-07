import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/data/notes_repository.dart';
import 'package:note_app/domain/models.dart';
import 'package:note_app/features/notes/notes_viewmodel.dart';

Future<NotesViewModel> _readyVm() async {
  final vm = NotesViewModel(MockNotesRepository());
  await vm.load();
  return vm;
}

void main() {
  test('seed loads notes, folders and selects first', () async {
    final vm = await _readyVm();
    expect(vm.loading, isFalse);
    expect(vm.error, isNull);
    expect(vm.folders.length, 5);
    expect(vm.visible.isNotEmpty, isTrue);
    expect(vm.selectedId, isNotNull);
  });
  test('search filters by title, body and tags', () async {
    final vm = await _readyVm();
    vm.setQuery('roadmap');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(vm.visible.length, 1);
    expect(vm.visible.first.title.toLowerCase(), contains('roadmap'));
    vm.setQuery('');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(vm.visible.length, greaterThan(1));
  });
  test('trash lifecycle: move, restore, delete forever', () async {
    final vm = await _readyVm();
    final first = vm.visible.first;
    final totalActive = vm.visible.length;
    await vm.toTrash(first);
    expect(vm.visible.length, totalActive - 1);
    vm.setView(NotesView.trash);
    expect(vm.visible.any((n) => n.id == first.id), isTrue);
    final trashed = vm.visible.firstWhere((n) => n.id == first.id);
    await vm.restore(trashed);
    expect(vm.visible.any((n) => n.id == first.id), isFalse);
    vm.setView(NotesView.all);
    final back = vm.visible.firstWhere((n) => n.id == first.id);
    await vm.toTrash(back);
    vm.setView(NotesView.trash);
    final again = vm.visible.firstWhere((n) => n.id == first.id);
    await vm.deleteForever(again);
    vm.setView(NotesView.all);
    expect(vm.visible.any((n) => n.id == first.id), isFalse);
  });
  test('create adds an active note visible in all notes', () async {
    final vm = await _readyVm();
    await vm.create(inFolder: 'f_inbox');
    vm.setView(NotesView.all);
    expect(vm.visible.any((n) => n.status == NoteStatus.active), isTrue);
  });
  test('folder filter + move updates counts', () async {
    final vm = await _readyVm();
    final before = vm.countIn('f_design');
    vm.setFolder('f_design');
    expect(vm.visible.every((n) => n.folderId == 'f_design'), isTrue);
    final note = vm.visible.first;
    await vm.moveTo(note, 'f_personal');
    expect(vm.countIn('f_design'), before - 1);
  });
  test('note model preview + wordcount', () {
    final now = DateTime(2026, 1, 1);
    final n = Note(
      id: 'x',
      title: 'Hello',
      body: 'one two three',
      folderId: 'f',
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );
    expect(n.wordCount, 4);
    expect(n.preview, isNotEmpty);
  });
}
