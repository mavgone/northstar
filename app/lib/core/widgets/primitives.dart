// Reusable primitives: pressable, buttons, inputs, chips, state views.
// All interactive controls go through AppPressable (scale + sink, no ripple).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../design/tokens.dart';

/// House pressable: scale + sink press, focus ring, semantics. No ink ripple.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.tooltip,
    this.focusable = true,
    this.enabled = true,
    this.borderRadius = AppRadius.md,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? tooltip;
  final bool focusable;
  final bool enabled;
  final double borderRadius;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _hover = false;
  bool _down = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget content = AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.ease,
        decoration: BoxDecoration(
          color: _down ? t.hover : (_hover ? t.hover : Colors.transparent),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: _focus ? Border.all(color: t.accent, width: 1.4) : null,
        ),
        child: widget.child,
      ),
    );
    if (!widget.enabled || widget.onTap == null) {
      return Opacity(opacity: 0.45, child: content);
    }
    content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _hover = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _hover = false;
          _down = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (mounted) setState(() => _down = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _down = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _down = false);
        },
        onTap: widget.onTap,
        child: FocusableActionDetector(
          enabled: widget.focusable,
          onShowFocusHighlight: (v) {
            if (mounted) setState(() => _focus = v);
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: Semantics(
            button: true,
            label: widget.semanticLabel,
            child: content,
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: content);
    }
    return content;
  }
}

enum AppButtonKind { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.kind = AppButtonKind.secondary,
    this.loading = false,
    this.fullWidth = false,
    this.shortcut,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool loading;
  final bool fullWidth;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Color bg;
    Color fg;
    BorderSide? side;
    switch (kind) {
      case AppButtonKind.primary:
        bg = t.accent;
        fg = t.isDark ? const Color(0xFF14121F) : Colors.white;
        break;
      case AppButtonKind.danger:
        bg = t.danger;
        fg = Colors.white;
        break;
      case AppButtonKind.ghost:
        bg = Colors.transparent;
        fg = t.textMuted;
        break;
      case AppButtonKind.secondary:
        bg = t.panel;
        fg = t.text;
        side = BorderSide(color: t.borderStrong);
        break;
    }
    final btn = AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withValues(alpha: 0.55) : bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: side == null ? null : Border.fromBorderSide(side),
        boxShadow: kind == AppButtonKind.primary
            ? [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (shortcut != null) ...[
            const SizedBox(width: 8),
            _Kbd(label: shortcut!),
          ],
        ],
      ),
    );
    final press = AppPressable(
      onTap: loading ? null : onPressed,
      enabled: onPressed != null,
      semanticLabel: label,
      tooltip: shortcut == null ? null : '$label ($shortcut)',
      child: btn,
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: press);
    return press;
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: t.isDark ? Colors.white24 : Colors.black26),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: t.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscure = false,
    this.prefix,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final IconData? prefix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      style: TextStyle(color: t.text, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix == null
            ? null
            : Icon(prefix, size: 15, color: t.textFaint),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    this.onRemove,
    this.selected = false,
  });
  final String tag;
  final VoidCallback? onRemove;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? t.selected
            : (t.isDark ? const Color(0x14FFFFFF) : const Color(0xFFF0EEE9)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: selected ? t.accent : t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontSize: 11.5,
              color: selected ? t.accent : t.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(LucideIcons.x, size: 12, color: t.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });
  final IconData icon;
  final String title;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: t.panel2,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 24, color: t.textFaint),
            ),
            const SizedBox(height: AppSpace.x4),
            Text(
              title,
              style: context.headlineGlow,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.x2),
            Text(
              hint,
              style: AppType.small.copyWith(color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpace.x4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: t.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(LucideIcons.triangleAlert, size: 24, color: t.danger),
            ),
            const SizedBox(height: AppSpace.x4),
            Text('Something went wrong', style: context.headlineGlow),
            const SizedBox(height: AppSpace.x2),
            Text(
              message,
              style: AppType.small.copyWith(color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.x4),
            AppButton(
              label: 'Retry',
              icon: LucideIcons.rotateCw,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class NoteListSkeleton extends StatelessWidget {
  const NoteListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (c, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loading note title placeholder', style: AppType.headline),
              SizedBox(height: 6),
              Text(
                'Preview line one placeholder text for skeleton shimmer effect demo.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Format relative time without intl (keeps deps light).
String timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

String fullDate(DateTime dt) {
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(dt.day)}.${p(dt.month)}.${dt.year}  ${p(dt.hour)}:${p(dt.minute)}';
}
