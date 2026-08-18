import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Playing-card face for the Games picker. Stack depth comes from the carousel.
class GameModeCard extends StatelessWidget {
  final GameMode mode;
  final VoidCallback? onHowToPlay;
  final bool showActions;

  const GameModeCard({
    super.key,
    required this.mode,
    this.onHowToPlay,
    this.showActions = true,
  });

  static Color pickerFaceFor(AppTheme theme, GameMode mode) {
    return switch (mode) {
      GameMode.casino => theme.pickerFace,
      GameMode.casinoSpeed => theme.pickerFaceEdge,
      GameMode.tresydos => theme.pickerFaceAlt,
      GameMode.robaito => theme.pickerFaceEdge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GamesViewModel>();
    final theme = AppStyle.theme;
    final game = vm.gamesInfo.firstWhere((g) => g.id == mode.name);
    final face = pickerFaceFor(theme, mode);
    final playEnabled = game.enabled;
    final howToEnabled = mode != GameMode.robaito;
    final markColor = _suitColor(theme);

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: GestureDetector(
        onTap: howToEnabled && onHowToPlay != null
            ? SoundService.wrapTap(onHowToPlay)
            : null,
        behavior: HitTestBehavior.opaque,
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
                          fontSize: game.title.length > 8 ? 30 : 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          height: 1.02,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _TapForInstructionsHint(enabled: howToEnabled),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: _ModeMark(mode: mode, color: markColor),
              ),
              if (showActions)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: playEnabled
                        ? SoundService.wrapTap(
                            () => showEnterGameDialog(context, vm, mode),
                          )
                        : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: playEnabled
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
                        color: playEnabled
                            ? theme.textPrimary
                            : theme.muted.withValues(alpha: .5),
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

  Color _suitColor(AppTheme theme) {
    return switch (mode) {
      GameMode.tresydos => theme.suitRed,
      GameMode.casino ||
      GameMode.casinoSpeed ||
      GameMode.robaito => theme.textPrimary,
    };
  }
}

class _ModeMark extends StatelessWidget {
  const _ModeMark({required this.mode, required this.color});

  final GameMode mode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (mode) {
      GameMode.casino => '♠',
      GameMode.casinoSpeed => '♠',
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

class _TapForInstructionsHint extends StatefulWidget {
  const _TapForInstructionsHint({required this.enabled});

  final bool enabled;

  @override
  State<_TapForInstructionsHint> createState() =>
      _TapForInstructionsHintState();
}

class _TapForInstructionsHintState extends State<_TapForInstructionsHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.enabled) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TapForInstructionsHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.enabled && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final label = AppLocalizations.of(context).tapForInstructions;
    final color = widget.enabled
        ? theme.textPrimary.withValues(alpha: .78)
        : theme.muted;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final opacity = widget.enabled ? 0.35 + 0.65 * _pulse.value : 0.45;
        return Opacity(opacity: opacity, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.mutedText.copyWith(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
