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
  final bool compact;

  const GameModeCard({
    super.key,
    required this.mode,
    this.onHowToPlay,
    this.showActions = true,
    this.compact = false,
  });

  static Color pickerFaceFor(AppTheme theme, GameMode mode) {
    return switch (mode) {
      GameMode.casino => theme.pickerFace,
      GameMode.casinoSpeed => theme.pickerFaceEdge,
      GameMode.tresydos => theme.pickerFaceAlt,
      GameMode.rummy => theme.pickerFaceAlt,
      GameMode.robaito => theme.pickerFaceEdge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GamesViewModel>();
    final theme = AppStyle.theme;
    final game = vm.gamesInfo.where((g) => g.id == mode.name).firstOrNull;
    final face = pickerFaceFor(theme, mode);
    final playEnabled = game?.enabled ?? false;
    final howToEnabled = playEnabled && mode != GameMode.robaito;
    final markColor = _suitColor(theme);
    final title = game?.title ?? mode.name;
    final radius = compact ? 14.0 : 18.0;
    final playSize = compact ? 34.0 : 52.0;

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Opacity(
        opacity: playEnabled ? 1 : 0.82,
        child: GestureDetector(
          onTap: howToEnabled && onHowToPlay != null
              ? SoundService.wrapTap(onHowToPlay)
              : null,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: .14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .30),
                  blurRadius: compact ? 10 : 18,
                  offset: Offset(0, compact ? 5 : 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.title.copyWith(
                            fontSize: compact
                                ? (title.length > 8 ? 13.0 : 16.0)
                                : (title.length > 8 ? 30.0 : 44.0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                            height: 1.05,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: compact ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 8),
                          _TapForInstructionsHint(enabled: howToEnabled),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: compact ? 8 : 16,
                  left: compact ? 8 : 16,
                  child: _ModeMark(
                    mode: mode,
                    color: markColor,
                    size: compact ? 16 : 28,
                  ),
                ),
                if (showActions)
                  Positioned(
                    right: compact ? 8 : 14,
                    bottom: compact ? 8 : 14,
                    child: playEnabled
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: SoundService.wrapTap(
                              () => showEnterGameDialog(context, vm, mode),
                            ),
                            child: Container(
                              width: playSize,
                              height: playSize,
                              decoration: BoxDecoration(
                                color: theme.textPrimary.withValues(alpha: .14),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.textPrimary.withValues(
                                    alpha: .18,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                CupertinoIcons.play_fill,
                                size: compact ? 14 : 22,
                                color: theme.textPrimary,
                              ),
                            ),
                          )
                        : Container(
                            width: playSize,
                            height: playSize,
                            decoration: BoxDecoration(
                              color: theme.muted.withValues(alpha: .14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.textPrimary.withValues(alpha: .14),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              CupertinoIcons.lock_fill,
                              size: compact ? 14 : 20,
                              color: theme.textPrimary.withValues(alpha: .72),
                            ),
                          ),
                  ),
              ],
            ),
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
      GameMode.robaito ||
      GameMode.rummy => theme.textPrimary,
    };
  }
}

class _ModeMark extends StatelessWidget {
  const _ModeMark({required this.mode, required this.color, this.size = 28});

  final GameMode mode;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (mode) {
      GameMode.casino => '♠',
      GameMode.casinoSpeed => '♠',
      GameMode.tresydos => '♦',
      GameMode.rummy => '♥',
      GameMode.robaito => '♣',
    };
    return Text(
      glyph,
      style: TextStyle(
        color: color,
        fontSize: size,
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
