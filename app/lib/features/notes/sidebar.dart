import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/primitives.dart';
import '../../domain/models.dart';
import '../auth/auth_viewmodel.dart';
import '../auth/auth_screens.dart';
import 'notes_viewmodel.dart';
const _lainArt = 'assets/lain/lain.png';
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.notes,
    required this.auth,
    required this.themeId,
    required this.onTheme,
    required this.collapsed,
    this.width = 264,
    this.pendingDropFolder,
    this.onDropHighlight,
  });
  final NotesViewModel notes;
  final AuthViewModel auth;
  final AppThemeId themeId;
  final ValueChanged<AppThemeId> onTheme;
  final bool collapsed;
  final double width;
  final String? pendingDropFolder;
  final ValueChanged<String?>? onDropHighlight;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (collapsed) {
      return Container(
        width: 60,
        decoration: BoxDecoration(color: t.panel, border: Border(right: BorderSide(color: t.border))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _RailBtn(icon: LucideIcons.menu, tip: 'Expand (Ctrl+B)', onTap: notes.toggleSidebar),
            _RailBtn(icon: LucideIcons.plus, tip: 'New note (Ctrl+N)', onTap: () => notes.create()),
            const Spacer(),
            ThemeMenu(themeId: themeId, onTheme: onTheme, compact: true),
          ],
        ),
      );
    }
    return Container(
      width: width,
      decoration: BoxDecoration(color: t.panel, border: Border(right: BorderSide(color: t.border))),
      child: ListenableBuilder(
        listenable: Listenable.merge([notes, auth]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Workspace', style: AppType.caption.copyWith(color: t.textFaint, letterSpacing: 0.6)),
                  ),
                  AppPressable(
                    onTap: notes.toggleSidebar,
                    tooltip: 'Collapse sidebar (Ctrl+B)',
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(LucideIcons.panelLeftClose, size: 15, color: t.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            _viewTile(context, LucideIcons.notebookPen, 'All notes', NotesView.all, notes.totalActive),
            _viewTile(context, LucideIcons.star, 'Favorites', NotesView.favorites, notes.favCount),
            _viewTile(context, LucideIcons.trash2, 'Trash', NotesView.trash, notes.trashCount, dropToTrash: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text('Folders', style: AppType.caption.copyWith(color: t.textFaint, letterSpacing: 0.6)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: notes.folders.length,
                itemBuilder: (c, i) {
                  final f = notes.folders[i];
                  return _FolderTile(
                    folder: f,
                    count: notes.countIn(f.id),
                    active: notes.view == NotesView.all && notes.folderId == f.id,
                    isDropTarget: pendingDropFolder == f.id,
                    onTap: () => notes.setFolder(notes.folderId == f.id ? null : f.id),
                    onDrop: (note) => notes.moveTo(note, f.id),
                    onHighlight: onDropHighlight,
                  );
                },
              ),
            ),
            if (notes.allTags.isNotEmpty) _tagsBlock(context),
            _footer(context),
          ],
        ),
      ),
    );
  }
  Widget _tagsBlock(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Tags', style: AppType.caption.copyWith(color: t.textFaint, letterSpacing: 0.6)),
              ),
              if (notes.tagFilter != null)
                AppPressable(
                  onTap: () => notes.setTag(null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text('Clear',
                        style: AppType.caption.copyWith(color: t.accent, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in notes.allTags)
                _TagButton(
                  tag: tag,
                  count: notes.countForTag(tag),
                  selected: notes.tagFilter == tag,
                  onTap: () => notes.setTag(notes.tagFilter == tag ? null : tag),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _footer(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Row(
        children: [
          if (t.isLain)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  _lainArt,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(LucideIcons.terminal, size: 20, color: t.accent),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => ProfileDialog(vm: auth, notesVm: notes)),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: t.accentSoft,
              child: Text(
                (auth.user?.name.isNotEmpty ?? false) ? auth.user!.name[0].toUpperCase() : '?',
                style: TextStyle(color: t.accent, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?.name ?? '-',
                    style: AppType.small.copyWith(fontWeight: FontWeight.w600, color: t.text),
                    overflow: TextOverflow.ellipsis),
                Text(auth.user?.email ?? '',
                    style: AppType.caption.copyWith(color: t.textFaint), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ThemeMenu(themeId: themeId, onTheme: onTheme),
          AppPressable(
            onTap: () => showDialog(context: context, builder: (_) => ProfileDialog(vm: auth, notesVm: notes)),
            tooltip: 'Profile and settings',
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(LucideIcons.settings, size: 15, color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
  Widget _viewTile(BuildContext context, IconData icon, String label, NotesView v, int count, {bool dropToTrash = false}) {
    final t = context.tokens;
    final active = notes.view == v && (v != NotesView.all || notes.folderId == null);
    final shown = count;
    Widget tile(bool hot) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: AppPressable(
          onTap: () => notes.setView(v),
          tooltip: dropToTrash ? 'Drop a note here to move it to trash' : null,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.ease,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: hot ? t.selected : (active ? t.selected : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: hot ? Border.all(color: t.accent, width: 1.3) : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: hot || active ? t.accent : t.textMuted),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(label,
                      style: AppType.small.copyWith(
                        color: hot || active ? t.text : t.textMuted,
                        fontWeight: hot || active ? FontWeight.w600 : FontWeight.w500,
                      )),
                ),
                _CountPill(text: '$shown'),
              ],
            ),
          ),
        ),
      );
    }
    if (!dropToTrash) return tile(false);
    return DragTarget<Note>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => notes.toTrash(d.data),
      builder: (context, candidate, rejected) => tile(candidate.isNotEmpty),
    );
  }
}
class _CountPill extends StatelessWidget {
  const _CountPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: t.panel2, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(text, textAlign: TextAlign.center, style: AppType.caption.copyWith(color: t.textMuted)),
      ),
    );
  }
}
class _TagButton extends StatelessWidget {
  const _TagButton({required this.tag, required this.count, required this.selected, required this.onTap});
  final String tag;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? t.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? t.accent : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#$tag',
                style: TextStyle(
                    fontSize: 11.5, color: selected ? t.accent : t.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            Text('$count', style: AppType.caption.copyWith(color: t.textFaint)),
          ],
        ),
      ),
    );
  }
}
class ThemeMenu extends StatelessWidget {
  const ThemeMenu({super.key, required this.themeId, required this.onTheme, this.compact = false});
  final AppThemeId themeId;
  final ValueChanged<AppThemeId> onTheme;
  final bool compact;
  IconData get _currentIcon => switch (themeId) {
        AppThemeId.light => LucideIcons.sun,
        AppThemeId.dark => LucideIcons.moon,
        AppThemeId.lain => LucideIcons.terminal,
      };
  String get _currentTip => switch (themeId) {
        AppThemeId.light => 'Theme: Light',
        AppThemeId.dark => 'Theme: Dark',
        AppThemeId.lain => 'Theme: Lain',
      };
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<AppThemeId>(
      tooltip: 'Switch theme',
      color: t.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      onSelected: onTheme,
      itemBuilder: (c) => [
        _item(t, AppThemeId.light, LucideIcons.sun, 'Light', 'Clean paper'),
        _item(t, AppThemeId.dark, LucideIcons.moon, 'Dark', 'Calm night'),
        _item(t, AppThemeId.lain, LucideIcons.terminal, 'Lain', 'Old computer'),
      ],
      child: compact
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: AppPressable(
                onTap: null,
                tooltip: _currentTip,
                child: Padding(padding: const EdgeInsets.all(10), child: Icon(_currentIcon, size: 17)),
              ),
            )
          : AppPressable(
              onTap: null,
              tooltip: _currentTip,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(_currentIcon, size: 15, color: t.textMuted),
              ),
            ),
    );
  }
  PopupMenuItem<AppThemeId> _item(AppTokens t, AppThemeId id, IconData icon, String title, String hint) {
    final active = themeId == id;
    return PopupMenuItem(
      value: id,
      child: Row(
        children: [
          Icon(icon, size: 15, color: active ? t.accent : t.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppType.small.copyWith(fontWeight: FontWeight.w600, color: t.text))),
          Text(hint, style: AppType.caption.copyWith(color: t.textFaint)),
          if (active) ...[
            const SizedBox(width: 8),
            Icon(LucideIcons.check, size: 14, color: t.accent),
          ],
        ],
      ),
    );
  }
}
class _RailBtn extends StatelessWidget {
  const _RailBtn({required this.icon, required this.tip, required this.onTap});
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AppPressable(
        onTap: onTap,
        tooltip: tip,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 17)),
      ),
    );
  }
}
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.count,
    required this.active,
    required this.isDropTarget,
    required this.onTap,
    required this.onDrop,
    required this.onHighlight,
  });
  final NoteFolder folder;
  final int count;
  final bool active;
  final bool isDropTarget;
  final VoidCallback onTap;
  final ValueChanged<Note> onDrop;
  final ValueChanged<String?>? onHighlight;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DragTarget<Note>(
      onWillAcceptWithDetails: (_) {
        onHighlight?.call(folder.id);
        return true;
      },
      onLeave: (_) => onHighlight?.call(null),
      onAcceptWithDetails: (d) {
        onHighlight?.call(null);
        onDrop(d.data);
      },
      builder: (context, candidate, rejected) {
        final hot = isDropTarget || candidate.isNotEmpty;
        return AppPressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.ease,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: hot ? t.selected : (active ? t.selected : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: hot ? Border.all(color: t.accent, width: 1.3) : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(hot ? LucideIcons.folderOpen : LucideIcons.folder,
                    size: 15, color: hot || active ? t.accent : t.textMuted),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(folder.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.small.copyWith(
                        color: hot || active ? t.text : t.textMuted,
                        fontWeight: hot || active ? FontWeight.w600 : FontWeight.w500,
                      )),
                ),
                _CountPill(text: '$count'),
              ],
            ),
          ),
        );
      },
    );
  }
}
