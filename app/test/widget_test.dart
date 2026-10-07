import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/app.dart';

void main() {
  testWidgets('Auth gate shows login, sign-in leads to notes shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const NoteApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'demo@obsidian.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password (min 6 chars)'),
      'demo1234',
    );
    await tester.pump();
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('All notes'), findsWidgets);
    expect(find.text('Workspace'), findsOneWidget);
  });
}
