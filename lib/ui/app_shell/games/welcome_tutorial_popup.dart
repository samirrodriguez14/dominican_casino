import 'package:youareup/l10n/app_localizations.dart';
import 'package:youareup/services/sound_service.dart';
import 'package:youareup/style/app_theme.dart';
import 'package:youareup/ui/app_shell/games/tutorial_flow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;

/// First-run welcome on Games. Start tutorial or dismiss for this session.
Future<void> showWelcomeTutorialPopup(BuildContext context) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: CupertinoColors.transparent,
          child: Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeTutorialBody,
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: theme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: SoundService.wrapTap(() async {
                      Navigator.pop(dialogContext);
                      await runHomeQuickPlay(context);
                    }),
                    child: Text(
                      l10n.startTutorial,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 4),
                  onPressed: SoundService.wrapTap(
                    () => Navigator.pop(dialogContext),
                  ),
                  child: Text(l10n.later, style: TextStyle(color: theme.muted)),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}
