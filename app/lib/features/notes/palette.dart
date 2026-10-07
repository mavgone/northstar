import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/primitives.dart';
import '../../domain/models.dart';
import 'notes_viewmodel.dart';
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.vm, required this.onNewNote, required this.onWelcome});
  final NotesViewModel vm;
  final VoidCallback onNewNote;
  final Future<void> Function() onWelcome;
  static Future<void> show(BuildContext context, NotesViewModel vm, VoidCallback onNew, Future<void> Function() onWelcome) {
    return showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.only(top: 110, left: 16, right: 16),
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CommandPalette(vm: vm, onNewNote: onNew, onWelcome: onWelcome),
        ),
      ),
    );
  }
  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}
class _CommandPaletteState extends State<CommandPalette> {
  final _ctrl = TextEditingController();
  String q = '';
  int index = 0;
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  List<_Entry> _entries() {
    final query = q.trim().toLowerCase();
    final out = <_Entry>[
      _Entry.action('New note', 'Create a note in current folder', LucideIcons.plus, widget.onNewNote),
      _Entry.action('Show welcome notes', 'Replay the introduction', LucideIcons.sparkles, () => widget.onWelcome()),
      _Entry.action('Go: All notes', 'Show everything', LucideIcons.notebookPen, () => widget.vm.setView(NotesView.all)),
      _Entry.action('Go: Favorites', 'Starred notes', LucideIcons.star, () => widget.vm.setView(NotesView.favorites)),
      _Entry.action('Go: Trash', 'Deleted notes', LucideIcons.trash2, () => widget.vm.setView(NotesView.trash)),
      for (final f in widget.vm.folders)
        _Entry.action('Folder: ${f.name}', '${widget.vm.countIn(f.id)} notes', LucideIcons.folder,
            () => widget.vm.setFolder(f.id)),
      for (final n in (query.isEmpty ? widget.vm.visible : widget.vm.allNotes).take(60))
        if (query.isEmpty ||
            n.title.toLowerCase().contains(query) ||
            n.body.toLowerCase().contains(query) ||
            n.tags.any((t) => t.contains(query)))
          _Entry.note(n),
    ];
    return out;
  }
  void _run(_Entry e) {
    Navigator.of(context).pop();
    if (e.note != null) {
      if (widget.vm.folderId != null && e.note!.folderId != widget.vm.folderId) {
        widget.vm.setFolder(null);
      }
      widget.vm.select(e.note!.id);
      if (e.note!.status == NoteStatus.trashed) widget.vm.setView(NotesView.trash);
    } else {
      e.fn?.call();
    }
  }
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final entries = _entries();
    if (index >= entries.length) index = 0;
    return Material(
      color: t.panel,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() {
                  q = v;
                  index = 0;
                }),
                onSubmitted: (_) {
                  if (entries.isNotEmpty) _run(entries[index.clamp(0, entries.length - 1)]);
                },
                style: TextStyle(color: t.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a command or search notes…',
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: t.textFaint),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No results', style: AppType.small),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (c, i) {
                        final e = entries[i];
                        final active = i == index;
                        return AppPressable(
                          onTap: () => _run(e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? t.selected : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            child: Row(
                              children: [
                                Icon(e.icon, size: 15, color: active ? t.accent : t.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          style: AppType.small.copyWith(
                                              fontWeight: FontWeight.w600, color: t.text)),
                                      Text(e.hint,
                                          style: AppType.caption.copyWith(color: t.textFaint)),
                                    ],
                                  ),
                                ),
                                if (e.note != null)
                                  Text(timeAgo(e.note!.updatedAt),
                                      style: AppType.caption.copyWith(color: t.textFaint)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.border)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  _hint(t, 'Up/Down', 'navigate'),
                  const SizedBox(width: 12),
                  _hint(t, 'Enter', 'open'),
                  const SizedBox(width: 12),
                  _hint(t, 'Esc', 'close'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _hint(AppTokens t, String k, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: t.panel2, borderRadius: BorderRadius.circular(5)),
          child: Text(k, style: AppType.caption.copyWith(color: t.textMuted, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppType.caption.copyWith(color: t.textFaint)),
      ],
    );
  }
}
class _Entry {
  _Entry.action(this.title, this.hint, this.icon, this.fn) : note = null;
  _Entry.note(Note item)
      : note = item,
        title = item.title.isEmpty ? 'Untitled' : item.title,
        hint = item.preview,
        icon = LucideIcons.fileText,
        fn = null;
  final String title;
  final String hint;
  final IconData icon;
  final VoidCallback? fn;
  final Note? note;
}
