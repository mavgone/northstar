// Interactive widget previews (flutter widget-preview start).
// Covers design primitives in light + dark.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'core/design/theme.dart';
import 'core/design/tokens.dart';
import 'core/widgets/primitives.dart';

@Preview(name: 'Buttons - light', brightness: Brightness.light)
Widget buttonsLight() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Primary',
              icon: LucideIcons.plus,
              kind: AppButtonKind.primary,
            ),
            SizedBox(height: 8),
            AppButton(label: 'Secondary', icon: LucideIcons.search),
            SizedBox(height: 8),
            AppButton(
              label: 'Danger',
              icon: LucideIcons.trash2,
              kind: AppButtonKind.danger,
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Buttons - dark', brightness: Brightness.dark)
Widget buttonsDark() {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Primary',
              icon: LucideIcons.plus,
              kind: AppButtonKind.primary,
            ),
            SizedBox(height: 8),
            AppButton(label: 'Secondary', icon: LucideIcons.search),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'States - empty and error')
Widget statesPreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: EmptyState(
              icon: LucideIcons.notebookPen,
              title: 'No notes yet',
              hint: 'Create your first note with Ctrl+N.',
            ),
          ),
          Expanded(
            child: ErrorState(
              message: 'Mock error for preview.',
              onRetry: () {},
            ),
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'Lain - old computer', brightness: Brightness.dark)
Widget lainPreview() {
  return MaterialApp(
    theme: AppTheme.lain(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) => Text(
                'present day, present time',
                style: context.headlineGlow.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            const AppButton(
              label: 'Connect',
              icon: LucideIcons.terminal,
              kind: AppButtonKind.primary,
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 6,
              children: [
                TagChip(tag: 'wired'),
                TagChip(tag: 'lain', selected: true),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Chips and inputs')
Widget chipsPreview() {
  return MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              children: [
                TagChip(tag: 'design'),
                TagChip(tag: 'roadmap', selected: true),
              ],
            ),
            SizedBox(height: 12),
            AppTextField(hint: 'Search notes…'),
          ],
        ),
      ),
    ),
  );
}
