import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:flutter/cupertino.dart';

/// Playable carousel games first, then locked / coming-soon slots for a 3×3.
List<GameMode?> gameGridItems({int minCount = 9}) {
  final playable = gameModeCarouselModes;
  final locked = GameMode.values
      .where((mode) => !playable.contains(mode))
      .toList();
  final items = <GameMode?>[...playable, ...locked];
  while (items.length < minCount) {
    items.add(null);
  }
  return items;
}

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
        final hidden = mode != null && hideModes.contains(mode);

        Widget slot;
        if (mode == null) {
          slot = _ComingSoonCard(tintIndex: index);
        } else if (hidden) {
          slot = const SizedBox.expand();
        } else {
          slot = GameModeCard(
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
        }

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

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.tintIndex});

  final int tintIndex;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final faces = [theme.pickerFace, theme.pickerFaceEdge, theme.pickerFaceAlt];
    final face = faces[tintIndex % faces.length];
    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .22),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lock_fill,
              size: 22,
              color: theme.textPrimary.withValues(alpha: .62),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.comingSoon,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.mutedText.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
