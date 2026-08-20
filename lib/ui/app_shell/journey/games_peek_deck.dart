import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Collapsed games deck peek when the Journey is on the table.
class GamesPeekDeck extends StatelessWidget {
  const GamesPeekDeck({
    super.key,
    required this.onTap,
    this.progress = 0,
  });

  final VoidCallback onTap;
  final double progress;

  static const _peekAngle = -0.14;
  static const _cardRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final scale = 1 - (progress * 0.12);
    const modes = [GameMode.casino, GameMode.tresydos, GameMode.rummy];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: AspectRatio(
          aspectRatio: homeCardAspect,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < modes.length; i++)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(i * 5.0, i * 4.0),
                    child: Transform.rotate(
                      angle: _peekAngle + i * 0.04,
                      child: _PeekGameCard(mode: modes[i]),
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                top: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.surface.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.border.withValues(alpha: .5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Games',
                      style: theme.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _PeekGameCard extends StatelessWidget {
  const _PeekGameCard({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final face = GameModeCard.pickerFaceFor(theme, mode);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(GamesPeekDeck._cardRadius),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: .14),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.gamecontroller_fill,
          color: theme.textPrimary.withValues(alpha: .35),
          size: 22,
        ),
      ),
    );
  }
}
