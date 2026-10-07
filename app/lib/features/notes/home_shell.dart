import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../domain/models.dart';
import '../auth/auth_viewmodel.dart';
import 'editor.dart';
import 'note_list.dart';
import 'notes_viewmodel.dart';
import 'palette.dart';
import 'sidebar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.notes,
    required this.auth,
    required this.themeId,
    required this.onTheme,
    required this.zoom,
    required this.onZoom,
    required this.onWelcome,
  });
  final NotesViewModel notes;
  final AuthViewModel auth;
  final AppThemeId themeId;
  final ValueChanged<AppThemeId> onTheme;
  final double zoom;
  final ValueChanged<double> onZoom;
  final Future<void> Function() onWelcome;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String? _dropFolder;
  int _mobileTab = 1;
  @override
  void initState() {
    super.initState();
    widget.notes.load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _palette() => CommandPalette.show(
    context,
    widget.notes,
    () => widget.notes.create(),
    widget.onWelcome,
  );
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            widget.notes.create(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _palette,
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            widget.notes.toggleSidebar,
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
            widget.onZoom(widget.zoom + 0.1),
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
            widget.onZoom(widget.zoom - 0.1),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
            widget.onZoom(1.0),
        const SingleActivator(LogicalKeyboardKey.delete): () {
          final s = widget.notes.selected;
          if (s != null && s.status != NoteStatus.trashed) {
            widget.notes.toTrash(s);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: t.bg,
          body: ListenableBuilder(
            listenable: widget.notes,
            builder: (context, _) => LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                if (w < 760) return _mobile(context);
                final showEditor = w >= 1050 || widget.notes.selectedId != null;
                return Row(
                  children: [
                    Sidebar(
                      notes: widget.notes,
                      auth: widget.auth,
                      themeId: widget.themeId,
                      onTheme: widget.onTheme,
                      collapsed: widget.notes.sidebarCollapsed || w < 900,
                      pendingDropFolder: _dropFolder,
                      onDropHighlight: (v) => setState(() => _dropFolder = v),
                    ),
                    SizedBox(
                      width: w >= 1280 ? 340 : 300,
                      child: NoteListPane(
                        vm: widget.notes,
                        searchCtrl: _searchCtrl,
                        searchFocus: _searchFocus,
                        onOpenPalette: _palette,
                      ),
                    ),
                    if (showEditor)
                      Expanded(
                        child: EditorPane(vm: widget.notes, zoom: widget.zoom),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    final t = context.tokens;
    final tabs = ['Folders', 'Notes', 'Editor'];
    Widget body = switch (_mobileTab) {
      0 => Sidebar(
        notes: widget.notes,
        auth: widget.auth,
        themeId: widget.themeId,
        onTheme: widget.onTheme,
        collapsed: false,
        width: double.infinity,
        pendingDropFolder: _dropFolder,
        onDropHighlight: (v) => setState(() => _dropFolder = v),
      ),
      2 => EditorPane(vm: widget.notes, zoom: widget.zoom),
      _ => NoteListPane(
        vm: widget.notes,
        searchCtrl: _searchCtrl,
        searchFocus: _searchFocus,
        onOpenPalette: _palette,
      ),
    };
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.panel,
        title: const Text('Northstar', style: AppType.headline),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.command, color: t.textMuted),
            onPressed: _palette,
            tooltip: 'Palette (Ctrl+K)',
          ),
          ThemeMenu(themeId: widget.themeId, onTheme: widget.onTheme),
          IconButton(
            icon: Icon(LucideIcons.plus, color: t.textMuted),
            onPressed: () => widget.notes.create(),
            tooltip: 'New',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SegmentedButton<int>(
              segments: [
                for (var i = 0; i < tabs.length; i++)
                  ButtonSegment(value: i, label: Text(tabs[i])),
              ],
              selected: {_mobileTab},
              onSelectionChanged: (s) => setState(() => _mobileTab = s.first),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
