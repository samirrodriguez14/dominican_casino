import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';

/// Game-picker face used on the home How to play stack.
class HomeInstructionCard extends StatelessWidget {
  const HomeInstructionCard({
    super.key,
    required this.section,
    required this.pageNumber,
    required this.totalPages,
    this.firstPageFace,
    this.onPlay,
    this.onTutorial,
  });

  final InstructionSection section;
  final int pageNumber;
  final int totalPages;
  final Color? firstPageFace;
  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final face = _faceFor(theme, pageNumber, firstPageFace: firstPageFace);

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
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                onTutorial != null ? 44 : 16,
                onPlay != null ? 18 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: theme.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: InstructionSectionContent(section: section),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: onPlay != null ? 56 : 0),
                    child: Center(
                      child: Text(
                        '$pageNumber / $totalPages',
                        style: theme.caption.copyWith(
                          color: theme.textPrimary.withValues(alpha: .7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTutorial != null)
              Positioned(
                top: 10,
                right: 10,
                child: _CardCircleButton(
                  icon: CupertinoIcons.lightbulb_fill,
                  label: AppLocalizations.of(context).startTutorial,
                  onPressed: onTutorial!,
                  size: 32,
                  iconSize: 15,
                ),
              ),
            if (onPlay != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: _CardCircleButton(
                  icon: CupertinoIcons.play_fill,
                  label: AppLocalizations.of(context).play,
                  onPressed: onPlay!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _faceFor(AppTheme theme, int page, {Color? firstPageFace}) {
    if (page == 1 && firstPageFace != null) return firstPageFace;
    final i = (page - 1) % 3;
    return [theme.pickerFace, theme.pickerFaceAlt, theme.pickerFaceEdge][i];
  }
}

class InstructionSectionContent extends StatelessWidget {
  const InstructionSectionContent({
    super.key,
    required this.section,
    this.bodyFontSize = 14,
    this.cardWidth = 48,
  });

  final InstructionSection section;
  final double bodyFontSize;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final hasDescription = section.description.isNotEmpty;
    final hasFacts = section.facts.isNotEmpty;
    final hasBody = section.body.isNotEmpty;
    final hasCards = section.specialCards.isNotEmpty;
    final hasGroups = section.cardGroups.isNotEmpty;
    final hasVisuals = hasCards || hasGroups;

    final descriptionBlock = [
      Text(
        section.description,
        style: theme.body.copyWith(
          fontSize: bodyFontSize,
          height: 1.3,
          color: theme.textPrimary.withValues(alpha: .82),
        ),
      ),
    ];
    final bodyBlock = [
      for (final paragraph in section.body) ...[
        Text(
          paragraph,
          style: theme.body.copyWith(
            fontSize: bodyFontSize,
            height: 1.35,
            color: theme.textPrimary.withValues(alpha: .9),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
    final cardsBlock = [
      if (hasGroups)
        _CardGroups(groups: section.cardGroups, cardWidth: cardWidth)
      else if (hasCards)
        _SpecialCardsRow(
          cards: section.specialCards,
          cardWidth: cardWidth,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription) ...[
          ...descriptionBlock,
          if (hasFacts || hasBody || hasVisuals) const SizedBox(height: 12),
        ],
        if (hasFacts) _FactsTable(facts: section.facts),
        if (hasFacts && (hasBody || hasVisuals)) const SizedBox(height: 12),
        if (section.showCardsFirst && hasVisuals) ...[
          ...cardsBlock,
          if (hasBody) const SizedBox(height: 10),
          ...bodyBlock,
        ] else ...[
          ...bodyBlock,
          if (hasBody && hasVisuals) const SizedBox(height: 4),
          if (hasVisuals) ...cardsBlock,
        ],
      ],
    );
  }
}

class _FactsTable extends StatelessWidget {
  const _FactsTable({required this.facts});

  final List<InstructionFact> facts;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Column(
      children: [
        for (var i = 0; i < facts.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.textPrimary.withValues(alpha: .12),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facts[i].label,
                  style: theme.caption.copyWith(
                    color: theme.textPrimary.withValues(alpha: .65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    facts[i].value,
                    textAlign: TextAlign.right,
                    style: theme.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SpecialCardsRow extends StatelessWidget {
  const _SpecialCardsRow({
    required this.cards,
    required this.cardWidth,
  });

  final List<InstructionSpecialCard> cards;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final n = cards.length;
        final columns = n == 4
            ? 2
            : (n >= 3 && constraints.maxWidth >= 210 ? 3 : n.clamp(1, 2));
        final slot =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final faceWidth = (slot * 0.72).clamp(32.0, cardWidth);
        final rows = (n / columns).ceil();

        return Column(
          children: [
            for (var row = 0; row < rows; row++)
              Padding(
                padding: EdgeInsets.only(bottom: row < rows - 1 ? 10 : 0),
                child: Row(
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: spacing),
                      Expanded(
                        child: _specialCardAt(
                          theme,
                          row * columns + col,
                          faceWidth,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _specialCardAt(AppTheme theme, int index, double faceWidth) {
    if (index >= cards.length) return const SizedBox.shrink();
    final special = cards[index];
    return Column(
      children: [
        PlayingCard(
          playingCardModel: PlayingCardModel(
            id: 'home-$index-${special.rank}-${special.suit}',
            rank: special.rank,
            suit: special.suit,
          ),
          width: faceWidth,
          isSelected: false,
          showCoinHint: false,
        ),
        if (special.points.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            special.points,
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _CardGroups extends StatelessWidget {
  const _CardGroups({
    required this.groups,
    required this.cardWidth,
  });

  final List<InstructionCardGroup> groups;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '+',
                style: theme.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary.withValues(alpha: .7),
                ),
              ),
            ),
          if (groups[i].label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                groups[i].label,
                style: theme.caption.copyWith(
                  color: theme.textPrimary.withValues(alpha: .7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var c = 0; c < groups[i].cards.length; c++)
                PlayingCard(
                  playingCardModel: PlayingCardModel(
                    id: 'group-$i-$c-${groups[i].cards[c].rank}-${groups[i].cards[c].suit}',
                    rank: groups[i].cards[c].rank,
                    suit: groups[i].cards[c].suit,
                  ),
                  width: cardWidth,
                  isSelected: false,
                  showCoinHint: false,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CardCircleButton extends StatelessWidget {
  const _CardCircleButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.size = 52,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onPressed),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.textPrimary.withValues(alpha: .14),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.textPrimary.withValues(alpha: .18),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: theme.textPrimary),
        ),
      ),
    );
  }
}

/// Default how-to on the home instructions pane is Casino.
const homeInstructionMode = GameMode.casino;
