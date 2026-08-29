import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';

/// Center fan carousel of defeated royals (same look as challenge focus cards).
class JourneyDefeatedCarousel extends StatefulWidget {
  const JourneyDefeatedCarousel({
    super.key,
    required this.worldDef,
    required this.focusRank,
    required this.onFocusRankChanged,
    required this.onDismiss,
    this.onReplay,
  });

  final JourneyWorldDef worldDef;
  final JourneyRank focusRank;
  final ValueChanged<JourneyRank> onFocusRankChanged;
  final VoidCallback onDismiss;
  final ValueChanged<JourneyCardDef>? onReplay;

  static JourneyRank initialFocus(JourneyWorldDef worldDef) {
    final defeated = worldDef.defeatedRoyals;
    for (final prefer in [
      JourneyRank.queen,
      JourneyRank.king,
      JourneyRank.jack,
    ]) {
      for (final c in defeated) {
        if (c.rank == prefer) return prefer;
      }
    }
    return JourneyRank.queen;
  }

  @override
  State<JourneyDefeatedCarousel> createState() =>
      _JourneyDefeatedCarouselState();
}

class _JourneyDefeatedCarouselState extends State<JourneyDefeatedCarousel> {
  late int _frontIndex;

  List<JourneyCardDef> get _cards => widget.worldDef.defeatedRoyals;

  int _indexForRank(JourneyRank rank) {
    final i = _cards.indexWhere((c) => c.rank == rank);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _frontIndex = _indexForRank(widget.focusRank);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final cards = _cards;
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final safeFront = _frontIndex.clamp(0, cards.length - 1);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Color(0x00000000)),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${JourneyL10n.of(context).worldLabel(widget.worldDef.world)} ${JourneyL10n.of(context).defeatedLabel}',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.muted,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                width: double.infinity,
                child: StackedCardCarousel(
                  key: ValueKey(
                    '${widget.worldDef.world.name}_${cards.length}',
                  ),
                  itemCount: cards.length,
                  initialIndex: _indexForRank(widget.focusRank),
                  peekStyle: CardPeekStyle.fan,
                  wrap: false,
                  widthFactor: 0.58,
                  maxCardWidth: 200,
                  fitToHeight: true,
                  onIndexChanged: (i) {
                    AppHaptics.selectionClick();
                    SoundService.instance.playLayered(GameSound.softCard);
                    setState(() => _frontIndex = i);
                    widget.onFocusRankChanged(cards[i].rank);
                  },
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    return AspectRatio(
                      aspectRatio: homeCardAspect,
                      child: _DefeatedChallengeCard(
                        card: card,
                        showReplay: i == safeFront,
                        onReplay: widget.onReplay == null
                            ? null
                            : () => widget.onReplay!(card),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Matches [JourneyChallengerFocus] face: cutout on world surface + chrome.
class _DefeatedChallengeCard extends StatelessWidget {
  const _DefeatedChallengeCard({
    required this.card,
    required this.showReplay,
    this.onReplay,
  });

  final JourneyCardDef card;
  final bool showReplay;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(card.world);
    final theme = AppStyle.theme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.accent.withValues(alpha: .8),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .3),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: palette.surface),
            Image.asset(
              card.avatarAssetPath,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => Image.asset(
                card.assetPath,
                fit: BoxFit.cover,
              ),
            ),
            if (showReplay)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background.withValues(alpha: 0),
                        palette.background.withValues(alpha: .92),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          style: theme.title.copyWith(
                            fontSize: 18,
                            color: palette.text,
                          ),
                        ),
                        if (card.gameLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            card.gameLabel,
                            style: theme.body.copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          borderRadius: BorderRadius.circular(12),
                          color: palette.accent.withValues(alpha: .95),
                          minimumSize: Size.zero,
                          onPressed: onReplay == null
                              ? null
                              : SoundService.wrapTap(onReplay),
                          child: Text(
                            'Replay',
                            style: TextStyle(
                              color: palette.background,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
