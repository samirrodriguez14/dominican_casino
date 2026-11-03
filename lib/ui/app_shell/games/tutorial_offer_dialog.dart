import 'package:barajando/l10n/app_localizations.dart';
import 'package:barajando/models/game_state.dart';
import 'package:barajando/services/sound_service.dart';
import 'package:barajando/style/app_theme.dart';
import 'package:barajando/ui/app_shell/games/tutorial_game_picker_dialog.dart';
import 'package:barajando/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:provider/provider.dart';

enum TutorialOfferChoice { tutorial, skip, cancel }

Future<TutorialOfferChoice?> showTutorialOfferDialog(
  BuildContext context,
  GameMode mode,
) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  GamesViewModel? gamesVm;
  try {
    gamesVm = context.read<GamesViewModel>();
  } catch (_) {}
  final gameName = tutorialModeTitle(gamesVm, mode);

  return showGeneralDialog<TutorialOfferChoice>(
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
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.tutorialOfferTitle(gameName),
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tutorialOfferBody,
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: SoundService.wrapTap(
                      () => Navigator.pop(
                        dialogContext,
                        TutorialOfferChoice.tutorial,
                      ),
                    ),
                    child: Text(
                      l10n.tutorialOfferPrimary,
                      style: TextStyle(
                        color: theme.background,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: theme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: SoundService.wrapTap(
                      () => Navigator.pop(
                        dialogContext,
                        TutorialOfferChoice.skip,
                      ),
                    ),
                    child: Text(
                      l10n.skipTutorial,
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
                    () => Navigator.pop(
                      dialogContext,
                      TutorialOfferChoice.cancel,
                    ),
                  ),
                  child: Text(l10n.cancel, style: TextStyle(color: theme.muted)),
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

Future<bool> showTutorialLeaveConfirmDialog(BuildContext context) async {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.tutorialLeaveTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.tutorialLeaveBody),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.stay),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.exit),
        ),
      ],
    ),
  );
  return result == true;
}
