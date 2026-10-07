import 'dart:async';
import '../domain/models.dart';
abstract class NotesRepository {
  Future<List<Note>> loadNotes();
  Future<List<NoteFolder>> loadFolders();
  Future<Note> saveNote(Note note);
  Future<void> deleteForever(String id);
  Future<Note> createNote({required String folderId});
}
class MockNotesRepository implements NotesRepository {
  MockNotesRepository();
  final List<NoteFolder> _folders = const [
    NoteFolder(id: 'f_inbox', name: 'Inbox'),
    NoteFolder(id: 'f_product', name: 'Product'),
    NoteFolder(id: 'f_design', name: 'Design System'),
    NoteFolder(id: 'f_engineering', name: 'Engineering'),
    NoteFolder(id: 'f_personal', name: 'Personal'),
  ];
  late final List<Note> _notes = _seed();
  @override
  Future<List<Note>> loadNotes() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return List<Note>.unmodifiable(_notes);
  }
  @override
  Future<List<NoteFolder>> loadFolders() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<NoteFolder>.unmodifiable(_folders);
  }
  @override
  Future<Note> saveNote(Note note) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i == -1) {
      _notes.insert(0, note);
    } else {
      _notes[i] = note;
    }
    return note;
  }
  @override
  Future<void> deleteForever(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _notes.removeWhere((n) => n.id == id);
  }
  @override
  Future<Note> createNote({required String folderId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final now = DateTime.now();
    final note = Note(
      id: 'n_${now.microsecondsSinceEpoch}',
      title: 'Untitled',
      body: '',
      folderId: folderId,
      tags: const [],
      createdAt: now,
      updatedAt: now,
      status: NoteStatus.active,
    );
    _notes.insert(0, note);
    return note;
  }
  List<Note> _seed() {
    final now = DateTime.now();
    Note n({
      required String id,
      required String title,
      required String body,
      required String folder,
      List<String> tags = const [],
      required int hoursAgo,
      int modifiedHoursAgo = 0,
      bool fav = false,
      NoteStatus status = NoteStatus.active,
    }) {
      final created = now.subtract(Duration(hours: hoursAgo));
      final updated = now.subtract(Duration(hours: modifiedHoursAgo));
      return Note(
        id: id,
        title: title,
        body: body,
        folderId: folder,
        tags: tags,
        createdAt: created,
        updatedAt: updated,
        isFavorite: fav,
        status: status,
      );
    }
    return [
      n(
        id: 'n1',
        title: 'Desktop layout principles',
        body: 'Sidebar 264px, list 320px, editor fluid. Keep the editor at 760px so lines stay readable. '
            'Hover states under 150ms, panel transitions 180 to 220ms. No ripples. Press means sink plus scale.',
        folder: 'f_design',
        tags: ['design', 'desktop'],
        hoursAgo: 30,
        modifiedHoursAgo: 2,
        fav: true,
      ),
      n(
        id: 'n2',
        title: 'Q3 roadmap: notes app',
        body: '1. Multi-pane editing\n2. Command palette (Ctrl+K)\n3. Trash restore\n'
            '4. Folder drag & drop\n5. Theme tokens + dark mode',
        folder: 'f_product',
        tags: ['roadmap'],
        hoursAgo: 80,
        modifiedHoursAgo: 5,
      ),
      n(
        id: 'n3',
        title: 'Keyboard-first UX checklist',
        body: 'Ctrl+N new note · Ctrl+F search · Ctrl+K palette · Ctrl+B sidebar · '
            'Delete moves to trash · every action focusable with visible focus ring.',
        folder: 'f_engineering',
        tags: ['ux', 'a11y'],
        hoursAgo: 55,
        modifiedHoursAgo: 9,
        fav: true,
      ),
      n(
        id: 'n4',
        title: 'Design tokens v1',
        body: 'Radius 10/14/18. Spacing 4pt base. Shadows soft, never hard. '
            'Type: Inter-ish system stack, 12/13/15/20/28 scale.',
        folder: 'f_design',
        tags: ['tokens'],
        hoursAgo: 120,
        modifiedHoursAgo: 26,
      ),
      n(
        id: 'n5',
        title: 'Meeting notes: sync',
        body: 'Decided: frontend-only milestone first. Backend interfaces stay abstract; '
            'mock repos behind contracts so API can plug in later.',
        folder: 'f_inbox',
        tags: ['meeting'],
        hoursAgo: 12,
        modifiedHoursAgo: 12,
      ),
      n(
        id: 'n6',
        title: 'Empty states copy',
        body: 'Nothing here yet. Press Ctrl+N for a new note. Trash is empty too. Deleted notes wait here for 30 days.',
        folder: 'f_personal',
        tags: [],
        hoursAgo: 200,
        modifiedHoursAgo: 60,
      ),
      n(
        id: 'n7',
        title: 'Launch announcement',
        body: 'Short, calm, confident. Lead with what changed, not version numbers…',
        folder: 'f_product',
        tags: ['announcement'],
        hoursAgo: 6,
        modifiedHoursAgo: 1,
        status: NoteStatus.active,
      ),
      n(
        id: 'n8',
        title: 'Old spec (in trash)',
        body: 'This note demonstrates trash: restore or delete forever.',
        folder: 'f_inbox',
        tags: ['archive'],
        hoursAgo: 400,
        modifiedHoursAgo: 90,
        status: NoteStatus.trashed,
      ),
      n(
        id: 'n9',
        title: 'Linux window notes',
        body: 'window_manager min size 980x640. Test GNOME + KDE scaling 100/150/200%. '
            'Hide native title bar, keep custom drag region.',
        folder: 'f_engineering',
        tags: ['linux', 'windows'],
        hoursAgo: 95,
        modifiedHoursAgo: 30,
      ),
      n(
        id: 'n10',
        title: 'Raycast-style palette ideas',
        body: 'Fuzzy search with grouped results: Notes, Folders, Actions. Footer hints: Up and Down to move, Enter to open, Esc to close.',
        folder: 'f_product',
        tags: ['palette'],
        hoursAgo: 150,
        modifiedHoursAgo: 48,
      ),
      n(
        id: 'n11',
        title: 'Grocery list',
        body: 'Oats, espresso, butter, greens. Keep it minimal.',
        folder: 'f_personal',
        tags: ['life'],
        hoursAgo: 20,
        modifiedHoursAgo: 15,
      ),
      n(
        id: 'n12',
        title: 'Performance notes',
        body: 'const constructors, ListView.builder, minimal rebuilds via ListenableBuilder slices. '
            'No heavy work in build(). Debounce search 200ms.',
        folder: 'f_engineering',
        tags: ['perf'],
        hoursAgo: 70,
        modifiedHoursAgo: 22,
      ),
    ];
  }
}
