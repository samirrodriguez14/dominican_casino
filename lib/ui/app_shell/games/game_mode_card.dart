import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/sage_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Playing-card face for the Games picker. Stack depth comes from the carousel.
class GameModeCard extends StatelessWidget {
  final GameMode mode;

  const GameModeCard({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GamesViewModel>();
    final theme = AppStyle.theme;
    final game = vm.gamesInfo.firstWhere((g) => g.id == mode.name);
    final face = _pickerFace(theme);
    final enabled = mode != GameMode.robaito;
    final markColor = _suitColor(theme);

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
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
        child: Stack(
          children: [
            // Title + how-to stay optically centered regardless of corners.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      style: theme.title.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                        height: 1.02,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      onPressed:
                          enabled ? () => showGameInfo(context, mode) : null,
                      child: Text(
                        'How to play',
                        style: theme.mutedText.copyWith(
                          color: enabled
                              ? theme.textPrimary.withValues(alpha: .78)
                              : theme.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              theme.textPrimary.withValues(alpha: .35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _ModeMark(mode: mode, color: markColor),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: enabled
                    ? () => showEnterGameDialog(context, vm, mode)
                    : null,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: enabled
                        ? theme.textPrimary.withValues(alpha: .14)
                        : theme.muted.withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.textPrimary.withValues(alpha: .18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.play_fill,
                    size: 22,
                    color: enabled
                        ? theme.textPrimary
                        : theme.muted.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _suitColor(AppTheme theme) {
    return switch (mode) {
      GameMode.tresydos => theme.suitRed,
      GameMode.casino || GameMode.robaito => theme.textPrimary,
    };
  }

  Color _pickerFace(AppTheme theme) {
    if (theme is SageTheme) {
      return switch (mode) {
        GameMode.casino => theme.pickerFace,
        GameMode.tresydos => theme.pickerFaceAlt,
        GameMode.robaito => theme.pickerFaceEdge,
      };
    }
    return switch (mode) {
      GameMode.casino => const Color(0xFF3A634F),
      GameMode.tresydos => const Color(0xFF3D4F58),
      GameMode.robaito => const Color(0xFF2E3A36),
    };
  }
}

class _ModeMark extends StatelessWidget {
  const _ModeMark({
    required this.mode,
    required this.color,
  });

  final GameMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (mode) {
      GameMode.casino => '♠',
      GameMode.tresydos => '♦',
      GameMode.robaito => '♣',
    };
    return Text(
      glyph,
      style: TextStyle(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
  }
}
