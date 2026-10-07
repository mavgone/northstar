import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:note_app/core/design/theme.dart';
import 'package:note_app/core/widgets/primitives.dart';

Widget _wrap(Widget child, {bool dark = false}) {
  return MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('EmptyState renders title, hint and action', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState(
      icon: LucideIcons.notebookPen,
      title: 'No notes yet',
      hint: 'Create one.',
      action: AppButton(label: 'New note', icon: LucideIcons.plus),
    )));
    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Create one.'), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
  });

  testWidgets('ErrorState renders message and retry invokes callback', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(ErrorState(
      message: 'boom (mock)',
      onRetry: () => retried = true,
    )));
    expect(find.text('boom (mock)'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('AppButton disabled shows label; loading shows spinner', (tester) async {
    await tester.pumpWidget(_wrap(const AppButton(label: 'Save', onPressed: null)));
    expect(find.text('Save'), findsOneWidget);

    await tester.pumpWidget(_wrap(const AppButton(label: 'Saving', loading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TagChip shows tag and reacts to remove', (tester) async {
    var removed = false;
    await tester.pumpWidget(_wrap(TagChip(tag: 'design', onRemove: () => removed = true)));
    expect(find.text('#design'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.x));
    expect(removed, isTrue);
  });

  testWidgets('NoteListSkeleton builds without overflow at 300x600', (tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const NoteListSkeleton()));
    expect(find.byType(NoteListSkeleton), findsOneWidget);
  });
}
