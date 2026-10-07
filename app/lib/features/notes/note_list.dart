import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/primitives.dart';
import '../../domain/models.dart';
import 'notes_viewmodel.dart';

class NoteListPane extends StatelessWidget {
  const NoteListPane({
    super.key,
    required this.vm,
    required this.searchCtrl,
    required this.searchFocus,
    this.onOpenPalette,
  });
  final NotesViewModel vm;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final VoidCallback? onOpenPalette;
  String _title(NotesView v) {
    switch (v) {
      case NotesView.all:
        return 'All notes';
      case NotesView.favorites:
        return 'Favorites';
      case NotesView.trash:
        return 'Trash';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? t.bg : t.panel,
        border: Border(right: BorderSide(color: t.border)),
      ),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.loading) {
            return const Column(
              children: [
                SizedBox(height: 12),
                Expanded(child: NoteListSkeleton()),
              ],
            );
          }
          if (vm.error != null) {
            return ErrorState(message: vm.error!, onRetry: vm.load);
          }
          final items = vm.visible;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title(vm.view),
                            style: AppType.headline.copyWith(color: t.text),
                          ),
                          Text(
                            '${items.length} notes${vm.tagFilter != null ? ' · #${vm.tagFilter}' : ''}',
                            style: AppType.caption.copyWith(color: t.textFaint),
                          ),
                        ],
                      ),
                    ),
                    _SortMenu(vm: vm),
                    const SizedBox(width: 4),
                    AppPressable(
                      onTap: () => vm.create(),
                      tooltip: 'New note (Ctrl+N)',
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: t.accent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          size: 15,
                          color: t.isDark
                              ? const Color(0xFF14121F)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        focusNode: searchFocus,
                        onChanged: vm.setQuery,
                        style: TextStyle(color: t.text, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search notes…  (Ctrl+F)',
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 15,
                            color: t.textFaint,
                          ),
                          suffixIcon: vm.query.isEmpty
                              ? GestureDetector(
                                  onTap: onOpenPalette,
                                  child: Icon(
                                    LucideIcons.command,
                                    size: 15,
                                    color: t.textFaint,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    searchCtrl.clear();
                                    vm.setQuery('');
                                  },
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 15,
                                    color: t.textFaint,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.tagFilter != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      TagChip(
                        tag: vm.tagFilter!,
                        selected: true,
                        onRemove: () => vm.setTag(null),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: vm.view == NotesView.trash
                            ? LucideIcons.trash2
                            : vm.query.isNotEmpty
                            ? LucideIcons.searchX
                            : LucideIcons.notebookPen,
                        title: vm.view == NotesView.trash
                            ? 'Trash is empty'
                            : vm.query.isNotEmpty
                            ? 'No results for "${vm.query}"'
                            : 'No notes here yet',
                        hint: vm.view == NotesView.trash
                            ? 'Deleted notes rest here. Restore or delete them forever.'
                            : 'Create your first note with Ctrl+N.',
                        action: vm.view == NotesView.trash
                            ? null
                            : AppButton(
                                label: 'New note',
                                icon: LucideIcons.plus,
                                onPressed: () => vm.create(),
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 2, 6, 20),
                        itemCount: items.length,
                        itemBuilder: (c, i) {
                          final n = items[i];
                          return _NoteCard(
                            key: ValueKey('note_${n.id}'),
                            note: n,
                            vm: vm,
                          );
                        },
                      ),
              ),
              if (vm.view == NotesView.trash && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AppButton(
                    label: 'Empty trash (${items.length})',
                    icon: LucideIcons.trash,
                    kind: AppButtonKind.danger,
                    fullWidth: true,
                    onPressed: () => _confirmEmpty(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmEmpty(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Empty trash?', style: AppType.headline),
        content: const Text(
          'This permanently deletes all trashed notes. This cannot be undone.',
          style: AppType.small,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'Delete forever',
              style: TextStyle(color: context.tokens.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) vm.emptyTrash();
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({super.key, required this.note, required this.vm});
  final Note note;
  final NotesViewModel vm;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = vm.selectedId == note.id;
    final Color cardBg = active && t.isDark
        ? t.selected.withValues(alpha: 0.55)
        : t.panel;
    final card =
        AppPressable(
              onTap: () => vm.select(note.id),
              semanticLabel: 'Note ${note.title}',
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.ease,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: active ? t.accent.withValues(alpha: 0.55) : t.border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.headline.copyWith(
                              fontSize: 13.5,
                              color: t.text,
                            ),
                          ),
                        ),
                        if (note.isFavorite)
                          Icon(LucideIcons.star, size: 13, color: t.accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.small.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo(note.updatedAt),
                          style: AppType.caption.copyWith(color: t.textFaint),
                        ),
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '#${note.tags.take(2).join('  #')}',
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption.copyWith(color: t.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: AppMotion.normal, curve: AppMotion.ease)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: AppMotion.normal,
              curve: AppMotion.ease,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LongPressDraggable<Note>(
        data: note,
        delay: const Duration(milliseconds: 220),
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Opacity(
              opacity: 0.92,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.panel,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: t.accent, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: t.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  note.title,
                  style: AppType.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: card,
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.vm});
  final NotesViewModel vm;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<SortMode>(
      tooltip: 'Sort notes',
      color: t.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      onSelected: vm.setSort,
      itemBuilder: (c) => const [
        PopupMenuItem(
          value: SortMode.modifiedDesc,
          child: Text('Recently modified', style: AppType.small),
        ),
        PopupMenuItem(
          value: SortMode.modifiedAsc,
          child: Text('Least recent', style: AppType.small),
        ),
        PopupMenuItem(
          value: SortMode.titleAsc,
          child: Text('Title A-Z', style: AppType.small),
        ),
        PopupMenuItem(
          value: SortMode.createdDesc,
          child: Text('Recently created', style: AppType.small),
        ),
      ],
      child: AppPressable(
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            LucideIcons.arrowDownWideNarrow,
            size: 15,
            color: t.textMuted,
          ),
        ),
      ),
    );
  }
}
