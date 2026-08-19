import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:flutter/cupertino.dart';

/// Playable carousel modes only (Robaito and other enum values stay hidden).
List<GameMode> gameGridItems() => List.unmodifiable(gameModeCarouselModes);

const gameGridGap = 10.0;
const gameGridPadH = 4.0;
const gameGridPadV = 8.0;

Rect gameGridCellRect(Size stage, int index) {
  final inner = stage.width - gameGridPadH * 2;
  final cellW = (inner - gameGridGap * 2) / 3;
  final cellH = cellW / (2.5 / 3.5);
  final col = index % 3;
  final row = index ~/ 3;
  return Rect.fromLTWH(
    gameGridPadH + col * (cellW + gameGridGap),
    gameGridPadV + row * (cellH + gameGridGap),
    cellW,
    cellH,
  );
}

class GameModeGrid extends StatelessWidget {
  const GameModeGrid({
    super.key,
    required this.progress,
    this.hideModes = const {},
    this.cardKeys = const {},
    this.onHowToPlay,
  });

  /// 0 collapsed / hidden, 1 fully shown.
  final double progress;
  final Set<GameMode> hideModes;
  final Map<GameMode, GlobalKey> cardKeys;
  final void Function(GameMode mode, Rect globalRect)? onHowToPlay;

  @override
  Widget build(BuildContext context) {
    final items = gameGridItems();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: gameGridPadH,
        vertical: gameGridPadV,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: gameGridGap,
        mainAxisSpacing: gameGridGap,
        childAspectRatio: 2.5 / 3.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final delay = (index / items.length) * 0.35;
        final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        final mode = items[index];
        final hidden = hideModes.contains(mode);

        final slot = hidden
            ? const SizedBox.expand()
            : GameModeCard(
                key: cardKeys[mode],
                mode: mode,
                compact: true,
                onHowToPlay: onHowToPlay == null
                    ? null
                    : () {
                        final ctx = cardKeys[mode]?.currentContext ?? context;
                        final box = ctx.findRenderObject() as RenderBox?;
                        if (box == null || !box.hasSize) return;
                        final rect = box.localToGlobal(Offset.zero) & box.size;
                        onHowToPlay!(mode, rect);
                      },
              );

        return Opacity(
          opacity: hidden ? 0 : eased,
          child: Transform.scale(
            scale: hidden ? 1 : 0.92 + 0.08 * eased,
            child: slot,
          ),
        );
      },
    );
  }
}
