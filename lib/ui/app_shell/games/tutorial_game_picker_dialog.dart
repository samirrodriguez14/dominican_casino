import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/tutorial_game_modes.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:provider/provider.dart';

String tutorialModeTitle(GamesViewModel? vm, GameMode mode) {
  if (vm != null) {
    for (final game in vm.gamesInfo) {
      if (game.id == mode.name) return game.title;
    }
  }
  return switch (mode) {
    GameMode.casino => 'Sweep',
    GameMode.casinoSpeed => 'Sweep Speed',
    GameMode.tresydos => 'Tres y Dos',
    GameMode.rummy => 'Rummy',
    GameMode.bs => 'BS',
    GameMode.robaito => 'Robaito',
  };
}

/// Pick a tutorial game. Info button opens rules deck without selecting.
Future<GameMode?> showTutorialGamePickerDialog(
  BuildContext context, {
  String? title,
}) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  GamesViewModel? gamesVm;
  try {
    gamesVm = context.read<GamesViewModel>();
  } catch (_) {}

  return showGeneralDialog<GameMode>(
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
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? l10n.tutorialPickerTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                for (final mode in tutorialGameModes) ...[
                  _PickerRow(
                    label: tutorialModeTitle(gamesVm, mode),
                    onInfo: () async {
                      await showGameModeHowTo(
                        dialogContext,
                        mode,
                        cardWidth: 200,
                        showPlay: false,
                      );
                    },
                    onSelect: () => Navigator.pop(dialogContext, mode),
                  ),
                  if (mode != tutorialGameModes.last)
                    const SizedBox(height: 8),
                ],
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 6),
                  onPressed: SoundService.wrapTap(
                    () => Navigator.pop(dialogContext),
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

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.onInfo,
    required this.onSelect,
  });

  final String label;
  final VoidCallback onInfo;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: Size.zero,
          onPressed: SoundService.wrapTap(onInfo),
          child: Icon(
            CupertinoIcons.info_circle,
            color: theme.muted,
            size: 22,
            semanticLabel: l10n.tutorialRulesInfo,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            color: theme.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            onPressed: SoundService.wrapTap(onSelect),
            child: Text(
              label,
              style: theme.title.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
