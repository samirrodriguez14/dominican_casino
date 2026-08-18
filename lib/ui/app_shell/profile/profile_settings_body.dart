import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/settings/theme_option.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/home/privacy_policy_copy.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
import 'package:dominican_casino/view_models/app_theme_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Playing-card settings face, matching the games carousel chrome.
class ProfileSettingsBody extends StatefulWidget {
  const ProfileSettingsBody({super.key});

  @override
  State<ProfileSettingsBody> createState() => _ProfileSettingsBodyState();
}

class _ProfileSettingsBodyState extends State<ProfileSettingsBody>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 420);

  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flip = AnimationController(vsync: this, duration: _flipDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppRepo>().refreshNotificationStatus();
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openPrivacy() {
    if (_flip.isAnimating || !_flip.isDismissed) return;
    SoundService.instance.playLayered(GameSound.softCard);
    _flip.forward();
  }

  void _closePrivacy() {
    if (_flip.isAnimating || !_flip.isCompleted) return;
    SoundService.instance.playLayered(GameSound.softCard);
    _flip.reverse();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppRepo>().refreshNotificationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppThemeViewModel>();
    final appRepo = context.watch<AppRepo>();
    final sounds = context.watch<SoundService>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final face = theme.pickerFace;

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(
            _flip.value.clamp(0.0, 1.0),
          );
          final angle = t * math.pi;
          final showBack = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _privacyFace(theme, face, l10n),
                  )
                : _settingsFace(
                    theme: theme,
                    face: face,
                    l10n: l10n,
                    vm: vm,
                    appRepo: appRepo,
                    sounds: sounds,
                  ),
          );
        },
      ),
    );
  }

  Widget _cardShell({required Color face, required Widget child}) {
    final theme = AppStyle.theme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _privacyFace(AppTheme theme, Color face, AppLocalizations l10n) {
    return _cardShell(
      face: face,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicy,
              style: theme.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: SingleChildScrollView(
                child: PrivacyPolicyCopy(compact: true),
              ),
            ),
            Center(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                onPressed: _closePrivacy,
                child: Text(
                  l10n.back,
                  style: theme.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsFace({
    required AppTheme theme,
    required Color face,
    required AppLocalizations l10n,
    required AppThemeViewModel vm,
    required AppRepo appRepo,
    required SoundService sounds,
  }) {
    return _cardShell(
      face: face,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings,
              style: theme.title.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(l10n.themes),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (var i = 0; i < ownedThemes.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: ThemeOptionChip(
                                  themeType: ownedThemes[i],
                                  previewTheme: themeFromEnum(ownedThemes[i]),
                                  selected: vm.appTheme == ownedThemes[i],
                                  onTap: () => vm.selectTheme(ownedThemes[i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const _SectionDivider(),
                        _SectionLabel(l10n.language),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _LanguageButton(
                                label: 'English',
                                selected: appRepo.locale.languageCode == 'en',
                                onPressed: () =>
                                    appRepo.setLocale(const Locale('en')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LanguageButton(
                                label: 'Español',
                                selected: appRepo.locale.languageCode == 'es',
                                onPressed: () =>
                                    appRepo.setLocale(const Locale('es')),
                              ),
                            ),
                          ],
                        ),
                        const _SectionDivider(),
                        _SectionLabel(l10n.sound),
                        _SettingsToggleRow(
                          label: l10n.soundEffects,
                          value: sounds.sfxEnabled,
                          onChanged: sounds.setSfxEnabled,
                          volume: sounds.sfxVolume,
                          onVolumeChanged: sounds.setSfxVolume,
                        ),
                        _SettingsToggleRow(
                          label: l10n.backgroundMusic,
                          value: sounds.musicEnabled,
                          onChanged: sounds.setMusicEnabled,
                          volume: sounds.musicVolume,
                          onVolumeChanged: sounds.setMusicVolume,
                        ),
                        _SettingsToggleRow(
                          label: l10n.hapticFeedback,
                          value: sounds.hapticEnabled,
                          onChanged: (enabled) async {
                            await sounds.setHapticEnabled(enabled);
                            if (enabled) AppHaptics.mediumImpact();
                          },
                        ),
                        const _SectionDivider(),
                        _SectionLabel(l10n.notifications),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                appRepo.notificationsEnabled
                                    ? l10n.notificationsOn
                                    : l10n.notificationsOff,
                                style: theme.mutedText.copyWith(
                                  color: appRepo.notificationsEnabled
                                      ? theme.success
                                      : theme.textPrimary.withValues(alpha: .7),
                                ),
                              ),
                            ),
                            if (!appRepo.notificationsEnabled)
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                color: theme.textPrimary.withValues(alpha: .14),
                                onPressed: SoundService.wrapTap(
                                  () => _requestNotifications(
                                    context,
                                    appRepo,
                                    l10n,
                                  ),
                                ),
                                child: Text(
                                  l10n.enableNotifications,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const _SectionDivider(),
                        _SectionLabel(l10n.account),
                        const SizedBox(height: 2),
                        _GoogleAccountRow(
                          linked: appRepo.isGoogleLinked,
                          email: appRepo.googleEmail,
                          onConnect: () =>
                              _connectGoogle(context, appRepo, l10n),
                          onLogOut: () =>
                              _confirmLogOut(context, appRepo, l10n),
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Center(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            onPressed: SoundService.wrapTap(
                              () => _confirmDelete(context, appRepo, l10n),
                            ),
                            child: Text(
                              l10n.deleteAccount,
                              style: const TextStyle(
                                color: CupertinoColors.destructiveRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            onPressed: _openPrivacy,
                            child: Text(
                              l10n.privacyPolicy,
                              style: theme.mutedText.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: theme.muted.withValues(
                                  alpha: .45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestNotifications(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.enableNotifications),
        content: Text(l10n.notificationsRationale),
        actions: [
          CupertinoDialogAction(
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
            child: Text(l10n.notNow),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
            child: Text(l10n.enableNotifications),
          ),
        ],
      ),
    );
    if (go == true) await appRepo.enableNotifications();
  }

  Future<void> _connectGoogle(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final result = await appRepo.linkGoogleAccount();
    if (!context.mounted) return;
    if (result.status == GoogleAuthStatus.canceled) return;
    if (result.status == GoogleAuthStatus.failed) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.google),
          content: Text(l10n.googleSignInError(result.errorCode)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
              child: Text(l10n.back),
            ),
          ],
        ),
      );
      return;
    }
    final suggested = result.suggestedName?.trim();
    final player = appRepo.player;
    if (suggested != null &&
        suggested.isNotEmpty &&
        (player?.needsAccountSetup ?? true)) {
      await appRepo.updatePlayer(suggested);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(
          appRepo.isGoogleLinked
              ? l10n.deleteLocalDataGoogleBody
              : l10n.deleteAccountBody,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (go == true) {
      await appRepo.deleteLocalAccount();
      if (context.mounted) context.go('/home');
    }
  }

  Future<void> _confirmLogOut(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.logOut),
        content: Text(l10n.logOutBody),
        actions: [
          CupertinoDialogAction(
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (go == true) {
      await appRepo.logOut();
      if (context.mounted) context.go('/home');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppStyle.theme.caption.copyWith(
        color: AppStyle.theme.textPrimary.withValues(alpha: .72),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: AppStyle.theme.textPrimary.withValues(alpha: .12),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: Size.zero,
      color: selected
          ? theme.textPrimary.withValues(alpha: .18)
          : theme.textPrimary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      onPressed: SoundService.wrapTap(onPressed),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? theme.textPrimary
              : theme.textPrimary.withValues(alpha: .7),
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.volume,
    this.onVolumeChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? volume;
  final ValueChanged<double>? onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final hasVolume = volume != null && onVolumeChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (hasVolume)
            SizedBox(
              width: 78,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.body.copyWith(fontSize: 13, height: 1.15),
              ),
            )
          else
            Expanded(child: Text(label, style: theme.body)),
          if (hasVolume)
            Expanded(
              child: CupertinoSlider(
                value: volume!,
                min: 0,
                max: 1,
                activeColor: theme.success,
                onChanged: onVolumeChanged,
              ),
            ),
          Transform.scale(
            scale: 0.86,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: theme.success,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleAccountRow extends StatelessWidget {
  const _GoogleAccountRow({
    required this.linked,
    required this.email,
    required this.onConnect,
    required this.onLogOut,
  });

  final bool linked;
  final String? email;
  final VoidCallback onConnect;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final address = email?.trim();

    return Row(
      children: [
        const GoogleGMark(size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: !linked
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: SoundService.wrapTap(onConnect),
                    child: Text(
                      l10n.connectGoogle,
                      style: theme.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : Text(
                  address ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.body.copyWith(fontSize: 14),
                ),
        ),
        if (linked)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            color: theme.textPrimary.withValues(alpha: .14),
            onPressed: SoundService.wrapTap(onLogOut),
            child: Text(
              l10n.logOut,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
