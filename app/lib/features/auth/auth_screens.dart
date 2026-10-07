import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/primitives.dart';
import '../notes/notes_viewmodel.dart';
import 'auth_viewmodel.dart';

const _logoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
<rect width="32" height="32" rx="9" fill="#6E56CF"/>
<path d="M10 22V10l12 12V10" stroke="white" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 38});
  final double size;
  static String assetFor(AppThemeId id) => switch (id) {
    AppThemeId.light => 'assets/logo/light/mark-dark.png',
    AppThemeId.dark => 'assets/logo/primary/mark-light.png',
    AppThemeId.lain => 'assets/logo/terminal/mark-phosphor.png',
  };
  @override
  Widget build(BuildContext context) {
    final path = assetFor(context.tokens.id);
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (c, e, s) {
        debugPrint('AppLogoMark: missing asset $path ($e)');
        return SvgPicture.string(_logoSvg, width: size, height: size);
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.vm, required this.child});
  final AuthViewModel vm;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (!vm.isAuthed) return AuthScreenView(vm: vm);
        return child;
      },
    );
  }
}

class AuthScreenView extends StatefulWidget {
  const AuthScreenView({super.key, required this.vm});
  final AuthViewModel vm;
  @override
  State<AuthScreenView> createState() => _AuthScreenViewState();
}

class _AuthScreenViewState extends State<AuthScreenView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final vm = widget.vm;
        return Scaffold(
          backgroundColor: t.bg,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.isLain)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Image.asset(
                            'assets/lain/lain.png',
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => SvgPicture.string(
                              _logoSvg,
                              width: 64,
                              height: 64,
                            ),
                          ),
                        ),
                      ),
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppLogoMark(size: 38),
                            const SizedBox(width: 10),
                            Text(
                              'Northstar',
                              style: context.headlineGlow.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: AppMotion.slow)
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: AppMotion.slow,
                          curve: AppMotion.ease,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      vm.screen == AuthScreen.login
                          ? 'Welcome back. Your notes are waiting.'
                          : vm.screen == AuthScreen.register
                          ? 'Create your workspace in seconds.'
                          : 'Reset your password.',
                      style: AppType.small.copyWith(color: t.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: t.panel,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: t.border),
                            boxShadow: [
                              BoxShadow(
                                color: t.shadow,
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _tabs(vm, t),
                              const SizedBox(height: 16),
                              if (vm.screen == AuthScreen.register) ...[
                                AppTextField(
                                  controller: _name,
                                  hint: 'Full name',
                                  prefix: LucideIcons.user,
                                ),
                                const SizedBox(height: 10),
                              ],
                              AppTextField(
                                controller: _email,
                                hint: 'Email address',
                                prefix: LucideIcons.mail,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 10),
                              AppTextField(
                                controller: _pass,
                                hint: 'Password (min 6 chars)',
                                prefix: LucideIcons.lock,
                                obscure: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(vm),
                              ),
                              if (vm.error != null) ...[
                                const SizedBox(height: 10),
                                _banner(t, vm.error!, true),
                              ],
                              if (vm.info != null) ...[
                                const SizedBox(height: 10),
                                _banner(t, vm.info!, false),
                              ],
                              const SizedBox(height: 14),
                              AppButton(
                                label: vm.screen == AuthScreen.login
                                    ? 'Sign in'
                                    : 'Create account',
                                icon: LucideIcons.arrowRight,
                                kind: AppButtonKind.primary,
                                fullWidth: true,
                                loading: vm.busy,
                                shortcut: 'Enter',
                                onPressed: vm.busy ? null : () => _submit(vm),
                              ),
                              if (vm.screen == AuthScreen.login) ...[
                                const SizedBox(height: 8),
                                AppPressable(
                                  onTap: vm.busy
                                      ? null
                                      : () => vm.continueAsGuest(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Continue as guest (offline)',
                                        style: AppType.small.copyWith(
                                          color: t.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (vm.screen != AuthScreen.login) ...[
                                const SizedBox(height: 8),
                                AppPressable(
                                  onTap: () => vm.show(AuthScreen.login),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '← Back to sign in',
                                        style: AppType.small.copyWith(
                                          color: t.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppMotion.slow,
                          delay: const Duration(milliseconds: 80),
                        )
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: AppMotion.slow,
                          curve: AppMotion.ease,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tabs(AuthViewModel vm, AppTokens t) {
    Widget tab(String label, AuthScreen s) {
      final isActive =
          (s == AuthScreen.login && vm.screen == AuthScreen.login) ||
          (s == AuthScreen.register && vm.screen == AuthScreen.register);
      return Expanded(
        child: AppPressable(
          onTap: () => vm.show(s),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? t.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? t.accent : t.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Sign in', AuthScreen.login),
        tab('Register', AuthScreen.register),
      ],
    );
  }

  Widget _banner(AppTokens t, String msg, bool isError) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? t.dangerSoft : t.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isError
              ? t.danger.withValues(alpha: 0.35)
              : t.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        msg,
        style: AppType.small.copyWith(color: isError ? t.danger : t.accent),
      ),
    );
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (vm.screen == AuthScreen.login) {
      await vm.signIn(_email.text, _pass.text);
    } else {
      await vm.signUp(_name.text, _email.text, _pass.text);
    }
  }
}

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key, required this.vm, this.notesVm});
  final AuthViewModel vm;
  final NotesViewModel? notesVm;
  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.vm.user?.name ?? '',
  );
  int? _guestCount;
  String? _importMsg;
  bool _importing = false;
  @override
  void initState() {
    super.initState();
    _loadGuestCount();
  }

  Future<void> _loadGuestCount() async {
    final vm = widget.notesVm;
    if (vm == null || widget.vm.user?.id == 'guest') return;
    try {
      final count = await vm.guestNotesCount();
      if (mounted) setState(() => _guestCount = count);
    } catch (_) {}
  }

  Future<void> _doImport() async {
    final vm = widget.notesVm;
    if (vm == null) return;
    setState(() {
      _importing = true;
      _importMsg = null;
    });
    try {
      final count = await vm.importGuestNotes();
      if (!mounted) return;
      setState(() {
        _importMsg = count > 0
            ? 'Imported $count note${count == 1 ? '' : 's'} from guest.'
            : 'No guest notes to import.';
        _guestCount = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _importMsg = 'Import failed. Try again.');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final u = widget.vm.user;
        return AlertDialog(
          backgroundColor: t.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: const Text('Profile', style: AppType.headline),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: t.accentSoft,
                      child: Text(
                        (u?.name.isNotEmpty ?? false)
                            ? u!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: t.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u?.name ?? '-',
                            style: AppType.headline.copyWith(color: t.text),
                          ),
                          Text(
                            u?.email ?? '-',
                            style: AppType.small.copyWith(color: t.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _name,
                  hint: 'Display name',
                  prefix: LucideIcons.user,
                ),
                if (widget.vm.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.vm.error!,
                    style: AppType.small.copyWith(color: t.danger),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        icon: LucideIcons.check,
                        kind: AppButtonKind.primary,
                        loading: widget.vm.busy,
                        onPressed: widget.vm.busy
                            ? null
                            : () async {
                                final ok = await widget.vm.rename(_name.text);
                                if (ok && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Sign out',
                        icon: LucideIcons.logOut,
                        onPressed: () {
                          widget.vm.signOut();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.notesVm != null &&
                    widget.vm.user?.id != 'guest' &&
                    (_guestCount ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label:
                        'Import $_guestCount guest note${_guestCount == 1 ? '' : 's'}',
                    icon: LucideIcons.download,
                    loading: _importing,
                    onPressed: _importing ? null : _doImport,
                  ),
                ],
                if (_importMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _importMsg!,
                    style: AppType.small.copyWith(color: t.textMuted),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
