import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/settings/legal_links.dart';
import 'package:dominican_casino/ui/settings/settings_controls.dart';
import 'package:dominican_casino/ui/widgets/account_dialogs.dart';
import 'package:dominican_casino/ui/widgets/apple_mark.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
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
    with WidgetsBindingObserver {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppRepo>().refreshNotificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppRepo>().refreshNotificationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appRepo = context.watch<AppRepo>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final face = theme.pickerFace;

    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: _cardShell(
        face: face,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
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
                          const AppPreferencesSection(),
                          const SettingsSectionDivider(),
                          SettingsSectionLabel(l10n.notifications),
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
                                        : theme.textPrimary.withValues(
                                            alpha: .7,
                                          ),
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
                                  color: theme.textPrimary.withValues(
                                    alpha: .14,
                                  ),
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
                          const SettingsSectionDivider(),
                          SettingsSectionLabel(l10n.account),
                          const SizedBox(height: 4),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: _deleting
                                ? null
                                : SoundService.wrapTap(
                                    () => _confirmDelete(
                                      context,
                                      appRepo,
                                      l10n,
                                    ),
                                  ),
                            child: _deleting
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: CupertinoActivityIndicator(
                                      radius: 8,
                                    ),
                                  )
                                : Text(
                                    appRepo.isLinkedAccount
                                        ? l10n.deleteAccount
                                        : l10n.deleteLocalData,
                                    style: const TextStyle(
                                      color: CupertinoColors.destructiveRed,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _AccountActions(
                googleLinked: appRepo.isGoogleLinked,
                appleLinked: appRepo.isAppleLinked,
                email: appRepo.linkedEmail,
                deleting: _deleting,
                onConnectGoogle: () => _connectGoogle(context, appRepo, l10n),
                onConnectApple: () => _connectApple(context, appRepo, l10n),
                onLogOut: () => _confirmLogOut(context, appRepo, l10n),
              ),
              const SizedBox(height: 12),
              Center(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  onPressed: SoundService.wrapTap(
                    () => openPrivacyPolicy(context),
                  ),
                  child: Text(
                    l10n.privacyPolicy,
                    style: theme.mutedText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.muted.withValues(alpha: .45),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final confirmed = await confirmConnectGoogle(context);
    if (!confirmed || !context.mounted) return;
    final result = await appRepo.linkGoogleAccount();
    if (!context.mounted) return;
    if (result.status == GoogleAuthStatus.canceled) return;
    if (result.status == GoogleAuthStatus.failed) {
      await showLinkAccountError(context, result.errorCode);
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

  Future<void> _connectApple(
    BuildContext context,
    AppRepo appRepo,
    AppLocalizations l10n,
  ) async {
    final confirmed = await confirmConnectApple(context);
    if (!confirmed || !context.mounted) return;
    final result = await appRepo.linkAppleAccount();
    if (!context.mounted) return;
    if (result.status == GoogleAuthStatus.canceled) return;
    if (result.status == GoogleAuthStatus.failed) {
      await showLinkAccountError(context, result.errorCode);
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
    if (_deleting) return;
    final linked = appRepo.isLinkedAccount;
    final appleLinked = appRepo.isAppleLinked;
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(linked ? l10n.deleteAccount : l10n.deleteLocalData),
        content: Text(
          appleLinked
              ? l10n.deleteAccountAppleBody
              : linked
              ? l10n.deleteAccountBody
              : l10n.deleteLocalDataBody,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
            child: Text(linked ? l10n.deleteAccount : l10n.deleteLocalData),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    setState(() => _deleting = true);
    final shown = Completer<BuildContext>();
    var loaderRequested = false;

    void showDeletingLoader() {
      if (loaderRequested) return;
      loaderRequested = true;
      unawaited(
        showCupertinoDialog<void>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (ctx) {
            if (!shown.isCompleted) shown.complete(ctx);
            return PopScope(
              canPop: false,
              child: CupertinoAlertDialog(
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        linked ? l10n.deletingAccount : l10n.deletingLocalData,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    var failed = false;
    var canceled = false;
    try {
      if (linked) {
        final result = await appRepo.deleteAccount(onBusy: showDeletingLoader);
        canceled = result == DeleteAccountResult.canceled;
        failed = result == DeleteAccountResult.failed;
      } else {
        showDeletingLoader();
        await appRepo.deleteLocalAccount();
      }
    } catch (_) {
      failed = true;
    }

    if (loaderRequested) {
      final dialogContext = await shown.future;
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }
    if (!context.mounted) return;
    setState(() => _deleting = false);
    if (canceled) return;
    if (failed) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l10n.deleteAccount),
          content: Text(l10n.deleteAccountFailed),
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
    context.go('/home');
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

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.googleLinked,
    required this.appleLinked,
    required this.email,
    required this.deleting,
    required this.onConnectGoogle,
    required this.onConnectApple,
    required this.onLogOut,
  });

  final bool googleLinked;
  final bool appleLinked;
  final String? email;
  final bool deleting;
  final VoidCallback onConnectGoogle;
  final VoidCallback onConnectApple;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linked = googleLinked || appleLinked;
    final address = email?.trim();

    if (linked) {
      final title = appleLinked ? l10n.appleConnected : l10n.googleConnected;
      final leading = appleLinked
          ? const AppleMark(size: 26)
          : const GoogleGMark(size: 26);
      final subtitle = (address != null && address.isNotEmpty)
          ? address
          : (appleLinked ? l10n.apple : l10n.google);

      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionPill(
                leading: leading,
                value: title,
                subtitle: subtitle,
                semanticLabel: title,
                onPressed: null,
              ),
              const SizedBox(width: 8),
              _CircleAction(
                icon: CupertinoIcons.square_arrow_right,
                semanticLabel: l10n.logOut,
                onPressed: deleting ? null : onLogOut,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionPill(
              leading: const GoogleGMark(size: 26),
              value: l10n.connectGoogle,
              semanticLabel: l10n.connectGoogle,
              onPressed: deleting ? null : onConnectGoogle,
            ),
            if (appleSignInAvailable) ...[
              const SizedBox(width: 8),
              _ActionPill(
                leading: const AppleMark(size: 26),
                value: l10n.connectApple,
                semanticLabel: l10n.connectApple,
                onPressed: deleting ? null : onConnectApple,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.leading,
    required this.value,
    required this.semanticLabel,
    this.subtitle,
    this.onPressed,
  });

  final Widget leading;
  final String value;
  final String semanticLabel;
  final String? subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 52, maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.textPrimary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.textPrimary.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: theme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: theme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: onPressed != null,
      label: semanticLabel,
      child: onPressed == null
          ? pill
          : CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: SoundService.wrapTap(onPressed),
              child: pill,
            ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed == null ? null : SoundService.wrapTap(onPressed),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.textPrimary.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: theme.textPrimary.withValues(alpha: .18)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: theme.textPrimary,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
