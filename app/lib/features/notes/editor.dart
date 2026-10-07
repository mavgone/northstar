import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/primitives.dart';
import '../../domain/models.dart';
import 'notes_viewmodel.dart';
class EditorPane extends StatefulWidget {
  const EditorPane({super.key, required this.vm, this.zoom = 1.0});
  final NotesViewModel vm;
  final double zoom;
  @override
  State<EditorPane> createState() => _EditorPaneState();
}
class _EditorPaneState extends State<EditorPane> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tag = TextEditingController();
  late final _bodyFocus = FocusNode(onKeyEvent: _bodyTabKey);
  Timer? _save;
  String? _boundId;
  bool _saving = false;
  bool _preview = false;
  String? _linkQuery;
  int _linkIndex = 0;
  OverlayEntry? _linkOverlay;
  String _savedTitle = '';
  String _savedBody = '';
  List<String> _savedTags = const [];
  @override
  void initState() {
    super.initState();
    _bodyFocus.addListener(() {
      if (!_bodyFocus.hasFocus && _linkQuery != null) {
        _linkQuery = null;
        _refreshLinkOverlay();
      }
    });
  }
  @override
  void dispose() {
    _save?.cancel();
    _linkOverlay?.remove();
    _linkOverlay = null;
    _title.dispose();
    _body.dispose();
    _tag.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }
  void _bind(Note? n) {
    if (n?.id == _boundId) {
      final pending = _save;
      if (pending == null || !pending.isActive) {
        if (_title.text != (n?.title ?? '')) _title.text = n?.title ?? '';
        if (_body.text != (n?.body ?? '')) {
          final sel = _body.selection;
          _body.text = n?.body ?? '';
          if (sel.isValid) {
            _body.selection = TextSelection(
              baseOffset: sel.start.clamp(0, _body.text.length),
              extentOffset: sel.end.clamp(0, _body.text.length),
            );
          }
        }
        _savedTitle = _title.text;
        _savedBody = _body.text;
        _savedTags = List<String>.from(n?.tags ?? const []);
      }
      return;
    }
    _flushPending();
    _boundId = n?.id;
    _title.text = n?.title ?? '';
    _title.selection = const TextSelection.collapsed(offset: 0);
    _body.text = n?.body ?? '';
    _tag.clear();
    _preview = false;
    _linkQuery = null;
    _refreshLinkOverlay();
    _savedTitle = n?.title ?? '';
    _savedBody = n?.body ?? '';
    _savedTags = List<String>.from(n?.tags ?? const []);
  }
  void _flushPending() {
    final pending = _save;
    _save = null;
    if (pending == null || !pending.isActive) return;
    pending.cancel();
    final oldId = _boundId;
    if (oldId == null) return;
    final title = _title.text;
    final body = _body.text;
    _saveChain = _saveChain.then((_) => _doSave(oldId, title, body));
  }
  bool _tagsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  Future<void> _saveChain = Future.value();
  void _queueSave(Note n) {
    _save?.cancel();
    if (mounted) setState(() => _saving = true);
    final title = _title.text;
    final body = _body.text;
    _save = Timer(const Duration(milliseconds: 450), () {
      _saveChain = _saveChain.then((_) => _doSave(n.id, title, body));
    });
  }
  Future<void> _doSave(String id, String title, String body) async {
    try {
      Note? fresh;
      for (final x in widget.vm.allNotes) {
        if (x.id == id) {
          fresh = x;
          break;
        }
      }
      fresh ??= widget.vm.selected;
      if (fresh == null || fresh.id != id) return;
      final tags = List<String>.from(fresh.tags);
      if (_boundId == id &&
          title == _savedTitle &&
          body == _savedBody &&
          _tagsEqual(tags, _savedTags)) {
        return;
      }
      await widget.vm.patch(fresh, title: title, body: body, tags: tags);
      if (_boundId == id) {
        _savedTitle = title;
        _savedBody = body;
        _savedTags = tags;
      }
    } catch (_) {
    } finally {
      if (mounted && _boundId == id) setState(() => _saving = false);
    }
  }
  void _onBodyChanged(Note note, String text) {
    _queueSave(note);
    final sel = _body.selection;
    String? query;
    if (sel.isValid && sel.isCollapsed && sel.start >= 2) {
      final before = text.substring(0, sel.start);
      final m = RegExp(r'\[\[([^\]\n]*)$').firstMatch(before);
      if (m != null) query = m.group(1);
    }
    if (query != _linkQuery) {
      _linkQuery = query;
      _linkIndex = 0;
      _refreshLinkOverlay();
    } else if (query != null) {
      _refreshLinkOverlay();
    }
  }
  List<Note> _linkMatches(String query) {
    final q = query.trim().toLowerCase();
    final all = widget.vm.allNotes.where((n) => n.status != NoteStatus.trashed).toList();
    all.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (q.isEmpty) return all.take(7).toList();
    return all.where((n) => n.title.toLowerCase().contains(q)).take(7).toList();
  }
  void _refreshLinkOverlay() {
    if (!mounted) return;
    _linkOverlay?.remove();
    _linkOverlay = null;
    final query = _linkQuery;
    if (query == null) return;
    final pos = _caretGlobalOffset();
    if (pos == null) return;
    _linkOverlay = OverlayEntry(builder: (_) => _LinkPopup(
          matches: _linkMatches(_linkQuery ?? ''),
          index: _linkIndex,
          anchor: pos,
          onPick: _acceptLink,
        ));
    Overlay.of(context).insert(_linkOverlay!);
  }
  Offset? _caretGlobalOffset() {
    final render = _bodyFocus.context?.findRenderObject();
    if (render is! RenderBox) return null;
    final sel = _body.selection;
    if (!sel.isValid) return null;
    final style = AppType.body.copyWith(fontSize: 14.5 * widget.zoom);
    final tp = TextPainter(
      text: TextSpan(text: _body.text.substring(0, sel.start.clamp(0, _body.text.length)), style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: render.size.width);
    final caret = tp.getOffsetForCaret(TextPosition(offset: sel.start.clamp(0, _body.text.length)), Rect.zero);
    return render.localToGlobal(Offset(caret.dx, caret.dy + 20));
  }
  void _acceptLink(Note target) {
    final value = _body.value;
    final sel = value.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    final before = value.text.substring(0, sel.start);
    final m = RegExp(r'\[\[[^\]\n]*$').firstMatch(before);
    if (m == null) return;
    final insert = '[[${target.title}]]';
    final next = value.text.replaceRange(m.start, sel.start, insert);
    _body.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: m.start + insert.length),
    );
    _linkQuery = null;
    _refreshLinkOverlay();
    final note = widget.vm.selected;
    if (note != null) _queueSave(note);
  }
  void _acceptLiteral() {
    final value = _body.value;
    final sel = value.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    const insert = ']]';
    final next = value.text.replaceRange(sel.start, sel.start, insert);
    _body.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _linkQuery = null;
    _refreshLinkOverlay();
    final note = widget.vm.selected;
    if (note != null) _queueSave(note);
  }
  Future<void> _openLink(Note from, String title) async {
    final query = title.trim();
    if (query.isEmpty) return;
    Note? found;
    for (final n in widget.vm.allNotes) {
      if (n.id != from.id && n.title == query) {
        found = n;
        break;
      }
    }
    found ??= () {
      for (final n in widget.vm.allNotes) {
        if (n.id != from.id && n.title.toLowerCase() == query.toLowerCase()) return n;
      }
      return null;
    }();
    if (found != null) {
      if (found.status == NoteStatus.trashed) widget.vm.setView(NotesView.trash);
      widget.vm.select(found.id);
      return;
    }
    await widget.vm.create(inFolder: from.folderId);
    final created = widget.vm.selected;
    if (created != null) {
      await widget.vm.patch(created, title: query);
    }
  }
  KeyEventResult _bodyTabKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_linkQuery != null) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _linkQuery = null;
        _refreshLinkOverlay();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        final matches = _linkMatches(_linkQuery!);
        if (matches.isNotEmpty) {
          _acceptLink(matches[_linkIndex.clamp(0, matches.length - 1)]);
        } else {
          _acceptLiteral();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _linkIndex++;
        _refreshLinkOverlay();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _linkIndex = (_linkIndex - 1).clamp(0, 999);
        _refreshLinkOverlay();
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _indentSelection(!HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_continueList()) return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
  int _lineStart(String text, int offset) {
    var i = offset.clamp(0, text.length);
    while (i > 0 && text[i - 1] != '\n') {
      i--;
    }
    return i;
  }
  int _lineEnd(String text, int offset) {
    var i = offset.clamp(0, text.length);
    while (i < text.length && text[i] != '\n') {
      i++;
    }
    return i;
  }
  void _indentSelection(bool indent) {
    final value = _body.value;
    final sel = value.selection;
    if (!sel.isValid) return;
    final text = value.text;
    var from = _lineStart(text, sel.start);
    var to = sel.end;
    if (to > from) {
      final endLineStart = _lineStart(text, to);
      if (endLineStart == to) {
        to = to > 0 ? to - 1 : 0;
      }
    }
    final lines = text.split('\n');
    var startLine = 0;
    var pos = 0;
    for (var i = 0; i < lines.length; i++) {
      final end = pos + lines[i].length;
      if (pos <= from && from <= end) startLine = i;
      pos = end + 1;
    }
    var endLine = startLine;
    pos = 0;
    for (var i = 0; i < lines.length; i++) {
      final end = pos + lines[i].length;
      if (pos <= to && to <= end) endLine = i;
      pos = end + 1;
    }
    var shiftStart = 0;
    var shiftEnd = 0;
    for (var i = startLine; i <= endLine; i++) {
      if (indent) {
        lines[i] = '  ${lines[i]}';
        if (i == startLine) shiftStart = 2;
        shiftEnd += 2;
      } else {
        var remove = 0;
        while (remove < 2 && remove < lines[i].length && lines[i][remove] == ' ') {
          remove++;
        }
        lines[i] = lines[i].substring(remove);
        if (i == startLine) shiftStart = -remove;
        shiftEnd -= remove;
      }
    }
    final next = lines.join('\n');
    _body.value = value.copyWith(
      text: next,
      selection: TextSelection(
        baseOffset: (sel.start + shiftStart).clamp(0, next.length),
        extentOffset: (sel.end + shiftEnd).clamp(0, next.length),
      ),
    );
    final note = widget.vm.selected;
    if (note != null) _queueSave(note);
  }
  bool _continueList() {
    final value = _body.value;
    final sel = value.selection;
    if (!sel.isValid || !sel.isCollapsed) return false;
    final text = value.text;
    final start = _lineStart(text, sel.start);
    final end = _lineEnd(text, sel.start);
    final line = text.substring(start, end);
    final bare = RegExp(r'^(\s*)\[([ xX])\]\s*(.*)$').firstMatch(line);
    if (bare != null && !line.trimLeft().startsWith('-')) {
      if (bare.group(3)!.trim().isEmpty) {
        final next = text.replaceRange(start, end, '');
        _body.value = value.copyWith(text: next, selection: TextSelection.collapsed(offset: start));
        final note = widget.vm.selected;
        if (note != null) _queueSave(note);
        return true;
      }
      if (RegExp(r'^\s*-\s+').hasMatch(bare.group(3)!)) {
        return false;
      }
      const marker = '[ ] ';
      final indent = bare.group(1)!;
      final next = text.replaceRange(sel.start, sel.start, '\n$indent$marker');
      _body.value = value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: sel.start + 1 + indent.length + marker.length),
      );
      final note = widget.vm.selected;
      if (note != null) _queueSave(note);
      return true;
    }
    final bullet = RegExp(r'^(\s*[-+*]\s+)(.+)?$').firstMatch(line);
    if (bullet != null) {
      if ((bullet.group(2) ?? '').trim().isEmpty) {
        final next = text.replaceRange(start, end, '');
        _body.value = value.copyWith(text: next, selection: TextSelection.collapsed(offset: start));
      } else {
        final marker = bullet.group(1)!;
        final next = text.replaceRange(sel.start, sel.start, '\n$marker');
        _body.value = value.copyWith(
          text: next,
          selection: TextSelection.collapsed(offset: sel.start + 1 + marker.length),
        );
      }
      final note = widget.vm.selected;
      if (note != null) _queueSave(note);
      return true;
    }
    final ordered = RegExp(r'^(\s*)(\d+)(\.\s+)(.+)?$').firstMatch(line);
    if (ordered != null) {
      if ((ordered.group(4) ?? '').trim().isEmpty) {
        final next = text.replaceRange(start, end, '');
        _body.value = value.copyWith(text: next, selection: TextSelection.collapsed(offset: start));
      } else {
        final marker = '${ordered.group(1)}${int.parse(ordered.group(2)!) + 1}${ordered.group(3)}';
        final next = text.replaceRange(sel.start, sel.start, '\n$marker');
        _body.value = value.copyWith(
          text: next,
          selection: TextSelection.collapsed(offset: sel.start + 1 + marker.length),
        );
      }
      final note = widget.vm.selected;
      if (note != null) _queueSave(note);
      return true;
    }
    return false;
  }
  static final _taskLine = RegExp(
      '^(\\s*[-+*]\\s+)\\[([ xX])\\]${String.fromCharCode(0x200B)}?(?=\\s|\$)');
  static final _bareTask = RegExp(r'^(\s*)\[([ xX])\](?=\s|$)');
  static List<int> _taskLines(String src) {
    final out = <int>[];
    final lines = src.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (_taskLine.hasMatch(lines[i])) out.add(i);
    }
    return out;
  }
  void _toggleTask(Note note, int ordinal) {
    final view = _normalizeTasks(_body.text);
    final lines = _body.text.split('\n');
    final targets = _taskLines(view);
    if (ordinal < 0 || ordinal >= targets.length) return;
    final i = targets[ordinal];
    final m = _bareTask.firstMatch(lines[i]);
    if (m == null) return;
    final mark = m.group(2) != ' ' ? ' ' : 'x';
    lines[i] = lines[i].replaceFirst(_bareTask, '${m.group(1)}[$mark]');
    _body.text = lines.join('\n');
    _queueSave(note);
  }
  MarkdownStyleSheet _previewSheet(AppTokens t, double zoom) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      p: AppType.body.copyWith(color: t.text, fontSize: 14.5 * zoom),
      h1: AppType.display.copyWith(color: t.text, fontSize: 22 * zoom),
      h2: AppType.title.copyWith(color: t.text, fontSize: 18 * zoom),
      h3: AppType.headline.copyWith(color: t.text, fontSize: 15 * zoom),
      a: AppType.body.copyWith(color: t.accent, fontSize: 16 * zoom),
      code: AppType.mono.copyWith(color: t.text, fontSize: 12 * zoom),
      checkbox: AppType.body.copyWith(color: t.accent, fontSize: 14 * zoom),
    );
  }
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final note = widget.vm.selected;
        if (note == null) {
          return const EmptyState(
            icon: LucideIcons.mousePointerClick,
            title: 'Select a note',
            hint: 'Choose a note from the list, or create a new one with Ctrl+N.',
          );
        }
        _bind(note);
        final trashed = note.status == NoteStatus.trashed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(context, note, trashed),
            if (trashed) _trashBanner(context, note),
            Expanded(
              child: LayoutBuilder(
                builder: (context, pane) {
                  final maxW = pane.maxWidth > 2000
                      ? 1000.0
                      : pane.maxWidth > 1600
                          ? 920.0
                          : pane.maxWidth > 1100
                              ? 800.0
                              : 760.0;
                  final titleSize = pane.maxWidth < 560 ? 20.0 : 26.0;
                  final column = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(28, 44, 28, 40),
                      children: [
                        _TitleBlock(
                          title: _title,
                          fontSize: titleSize * widget.zoom,
                          enabled: !trashed,
                          onChanged: () => _queueSave(note),
                        ),
                      _MetaBar(note: note, folderName: widget.vm.folderName(note.folderId)),
                      const SizedBox(height: 8),
                      if (note.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in note.tags)
                              TagChip(
                                tag: tag,
                                onRemove: trashed
                                    ? null
                                    : () => widget.vm.patch(
                                        note, tags: List<String>.from(note.tags)..remove(tag)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      if (_preview)
                        _TaskPreview(
                          text: _body.text,
                          sheet: _previewSheet(t, widget.zoom),
                          onToggle: (ordinal) => _toggleTask(note, ordinal),
                          onOpenLink: (title) => _openLink(note, title),
                        )
                      else
                        TextField(
                          controller: _body,
                          focusNode: _bodyFocus,
                          enabled: !trashed,
                        maxLines: null,
                        style: AppType.body.copyWith(color: t.text, fontSize: 14.5 * widget.zoom),
                        decoration: InputDecoration(
                          hintText: 'Start writing… Markdown supported in spirit.',
                          hintStyle: TextStyle(color: t.textFaint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: (v) => _onBodyChanged(note, v),
                      ),
                    ],
                    ),
                  );
                  return Center(child: column);
                },
              ),
            ),
            _backlinksBar(context, note),
            _statusbar(context, note),
          ],
        );
      },
    );
  }
  Widget _backlinksBar(BuildContext context, Note note) {
    final t = context.tokens;
    final links = widget.vm.backlinksFor(note);
    if (links.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Icon(LucideIcons.link2, size: 13, color: t.textFaint),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final link in links.take(8))
                  AppPressable(
                    onTap: () {
                      if (link.status == NoteStatus.trashed) {
                        widget.vm.setView(NotesView.trash);
                      }
                      widget.vm.select(link.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.panel2,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: t.border),
                      ),
                      child: Text(
                        link.title.isEmpty ? 'Untitled' : link.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.small.copyWith(color: t.accent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _toolbar(BuildContext context, Note note, bool trashed) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: Row(
        children: [
          if (_saving)
            Row(
              children: [
                const SizedBox(
                    width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 7),
                Text('Saving…', style: AppType.caption.copyWith(color: t.textFaint)),
              ],
            )
          else
            Row(
              children: [
                Icon(LucideIcons.check, size: 13, color: t.textFaint),
                const SizedBox(width: 6),
                Text('Saved ${timeAgo(note.updatedAt)}', style: AppType.caption.copyWith(color: t.textFaint)),
              ],
            ),
          const Spacer(),
          AppPressable(
            onTap: () => setState(() => _preview = !_preview),
            tooltip: _preview ? 'Edit' : 'Preview',
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(_preview ? LucideIcons.pen : LucideIcons.eye,
                  size: 15, color: _preview ? t.accent : t.textMuted),
            ),
          ),
          AppPressable(
            onTap: () => widget.vm.patch(note, fav: !note.isFavorite),
            tooltip: note.isFavorite ? 'Remove favorite' : 'Favorite',
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(note.isFavorite ? LucideIcons.star : LucideIcons.star,
                  size: 15, color: note.isFavorite ? t.accent : t.textMuted),
            ),
          ),
          if (!trashed)
            AppPressable(
              onTap: () => widget.vm.toTrash(note),
              tooltip: 'Move to trash (Del)',
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(LucideIcons.trash2, size: 15, color: t.textMuted),
              ),
            )
          else ...[
            AppButton(label: 'Restore', icon: LucideIcons.archiveRestore, onPressed: () => widget.vm.restore(note)),
            const SizedBox(width: 8),
            AppButton(
              label: 'Delete forever',
              icon: LucideIcons.trash,
              kind: AppButtonKind.danger,
              onPressed: () => widget.vm.deleteForever(note),
            ),
          ],
        ],
      ),
    );
  }
  Widget _trashBanner(BuildContext context, Note note) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: t.warningSoft,
      child: Row(
        children: [
          Icon(LucideIcons.trash2, size: 14, color: t.textMuted),
          const SizedBox(width: 8),
          const Expanded(child: Text('This note is in trash. Restore to edit it.', style: AppType.small)),
          AppPressable(
            onTap: () => widget.vm.restore(note),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Restore', style: AppType.small.copyWith(color: t.accent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
  Widget _statusbar(BuildContext context, Note note) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextField(
                controller: _tag,
                enabled: note.status != NoteStatus.trashed,
                style: AppType.small.copyWith(color: t.text),
                decoration: InputDecoration(
                  hintText: 'Add tag + Enter',
                  prefixIcon: Icon(LucideIcons.tag, size: 13, color: t.textFaint),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onSubmitted: (v) {
                  final tag = v.trim().replaceAll('#', '').toLowerCase();
                  if (tag.isEmpty) return;
                  if (!note.tags.contains(tag)) {
                    widget.vm.patch(note, tags: [...note.tags, tag]);
                  }
                  _tag.clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (widget.vm.isOffline || widget.vm.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.vm.isOffline ? t.textFaint : t.accent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.vm.isOffline
                        ? (widget.vm.pendingCount > 0
                            ? 'Offline · ${widget.vm.pendingCount} pending'
                            : 'Offline')
                        : '${widget.vm.pendingCount} pending',
                    style: AppType.caption.copyWith(color: t.textFaint),
                  ),
                ],
              ),
            ),
          Text('${note.wordCount} words', style: AppType.caption.copyWith(color: t.textFaint)),
        ],
      ),
    );
  }
}
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.fontSize,
    required this.enabled,
    required this.onChanged,
  });
  final TextEditingController title;
  final double fontSize;
  final bool enabled;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: title,
            builder: (c, v, _) {
              if (v.text.isEmpty) {
                return Text('Untitled',
                    style: context.displayGlow.copyWith(
                      fontSize: fontSize,
                      color: t.textFaint,
                      shadows: null,
                    ));
              }
              return Text(v.text, style: context.displayGlow.copyWith(fontSize: fontSize));
            },
          ),
          Positioned.fill(
            child: TextSelectionTheme(
              data: TextSelectionThemeData(
                cursorColor: t.accent,
                selectionColor: t.accent.withValues(alpha: 0.3),
                selectionHandleColor: t.accent,
              ),
              child: TextField(
                controller: title,
                enabled: enabled,
                maxLines: null,
                style: context.displayGlow.copyWith(
                  fontSize: fontSize,
                  color: Colors.transparent,
                  shadows: null,
                ),
                decoration: const InputDecoration(
                  hintText: null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _MetaBar extends StatelessWidget {
  const _MetaBar({required this.note, required this.folderName});
  final Note note;
  final String folderName;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget item(IconData icon, String label, String value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: t.textFaint),
          const SizedBox(width: 5),
          Text(label, style: AppType.caption.copyWith(color: t.textFaint)),
          const SizedBox(width: 4),
          Text(value, style: AppType.caption.copyWith(color: t.textMuted, fontWeight: FontWeight.w600)),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.panel2.withValues(alpha: t.isDark ? 0.6 : 1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          item(LucideIcons.calendarPlus, 'Created', fullDate(note.createdAt)),
          item(LucideIcons.clock, 'Modified', fullDate(note.updatedAt)),
          item(LucideIcons.folder, 'Folder', folderName),
        ],
      ),
    );
  }
}
String _normalizeTasks(String src) {
  return src.split('\n').map((line) {
    var out = line;
    final bare = RegExp(r'^(\s*)\[([ xX])\](?=\s|$)').firstMatch(out);
    if (bare != null) {
      final rest = out.substring(bare.end);
      if (RegExp(r'^\s*-\s+').hasMatch(rest)) {
        out = out.replaceFirst('[', '\\[').replaceFirst(']', '\\]');
      } else {
        out = '${bare.group(1)}- [${bare.group(2)}]$rest';
      }
    } else {
      final dashed = RegExp(r'^(\s*[-+*]\s+)\[([ xX])\](?=\s|$)').firstMatch(out);
      if (dashed != null) {
        out = out.replaceFirst('[', '\\[').replaceFirst(']', '\\]');
      }
    }
    out = out.replaceAll('[](', '[\u200B](');
    if (RegExp(r'^(\s*[-+*]\s+)\[([ xX])\]\s*$').hasMatch(out)) {
      out = '$out\u200B';
    }
    return out;
  }).join('\n');
}
String _expandBlanks(String src) {
  final lines = src.split('\n');
  var blanks = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) {
      blanks++;
      if (blanks > 1) lines[i] = '\u200B';
    } else {
      blanks = 0;
    }
  }
  return lines.join('\n');
}
String _linkify(String src) {
  return src.replaceAllMapped(
    RegExp(r'\[\[([^\]\n]+?)(?:\|([^\]\n]+?))?\]\]'),
    (m) {
      final target = m.group(1)!.trim();
      if (target.isEmpty) return m.group(0)!;
      final label = (m.group(2) ?? target).trim();
      return '[$label](#note:${Uri.encodeComponent(target)})';
    },
  );
}
class _TaskPreview extends StatelessWidget {  const _TaskPreview({required this.text, required this.sheet, required this.onToggle, required this.onOpenLink});
  final String text;
  final MarkdownStyleSheet sheet;
  final ValueChanged<int> onToggle;
  final ValueChanged<String> onOpenLink;
  @override
  Widget build(BuildContext context) {
    var ordinal = 0;
    final fontSize = sheet.p?.fontSize ?? 14;
    final lineHeight = fontSize * (sheet.p?.height ?? 1.55);
    return MarkdownBody(
      data: _expandBlanks(_normalizeTasks(_linkify(text))),
      styleSheet: sheet,
      softLineBreak: true,
      onTapLink: (label, href, title) {
        if (href != null && href.startsWith('#note:')) {
          onOpenLink(Uri.decodeComponent(href.substring('#note:'.length)));
        }
      },
      checkboxBuilder: (checked) {
        final index = ordinal++;
        return _TaskBox(
          value: checked,
          onChanged: () => onToggle(index),
          color: sheet.checkbox?.color,
          size: sheet.checkbox?.fontSize,
          boxHeight: lineHeight,
        );
      },
    );
  }
}
class _LinkPopup extends StatelessWidget {
  const _LinkPopup({required this.matches, required this.index, required this.anchor, required this.onPick});
  final List<Note> matches;
  final int index;
  final Offset anchor;
  final ValueChanged<Note> onPick;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final current = matches.isEmpty ? -1 : index.clamp(0, matches.length - 1);
    return Positioned(
      left: anchor.dx.clamp(0, 600).toDouble(),
      top: anchor.dy,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: t.panel,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: t.border),
              boxShadow: [BoxShadow(color: t.shadow, blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('No matches — Enter creates it',
                        style: AppType.small.copyWith(color: t.textFaint)),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < matches.length; i++)
                        _LinkRow(
                          note: matches[i],
                          active: i == current,
                          onTap: () => onPick(matches[i]),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.note, required this.active, required this.onTap});
  final Note note;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: active ? t.selected : Colors.transparent,
        child: Text(
          note.title.isEmpty ? 'Untitled' : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.small.copyWith(
            color: active ? t.text : t.textMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
class _TaskBox extends StatelessWidget {
  const _TaskBox({required this.value, required this.onChanged, required this.color, required this.size, required this.boxHeight});
  final bool value;
  final VoidCallback onChanged;
  final Color? color;
  final double? size;
  final double boxHeight;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: boxHeight,
      child: Align(
        alignment: const Alignment(0, 1.0),
        child: GestureDetector(
          onTap: onChanged,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: size ?? 16,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
