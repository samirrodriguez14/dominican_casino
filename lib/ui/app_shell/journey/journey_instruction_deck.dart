import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';

/// Collapsed left-side guide deck + expanded non-wrapping fan carousel.
class JourneyInstructionDeck extends StatelessWidget {
  const JourneyInstructionDeck({
    super.key,
    required this.unlockedThrough,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    this.deckKey,
    this.initialPage,
    this.world = JourneyWorld.diamonds,
  });

  /// Highest unlocked 1-based instruction id.
  final int unlockedThrough;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final GlobalKey? deckKey;
  /// 0-based carousel index to open on (defaults to latest unlocked).
  final int? initialPage;
  final JourneyWorld world;

  /// Unlocked pages, plus one locked "next" peek when more catalog remains.
  int get _visibleCount {
    if (unlockedThrough >= journeyInstructionCatalogSize) {
      return journeyInstructionCatalogSize;
    }
    return unlockedThrough + 1;
  }

  int get _pagerTotal => _visibleCount;

  /// 0-based highest index that may be brought to the front.
  int get _maxFrontIndex => (unlockedThrough - 1).clamp(0, _visibleCount - 1);

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Center(
        child: KeyedSubtree(
          key: deckKey,
          child: _CollapsedDeck(
            world: world,
            badge: unlockedThrough,
            onTap: () {
              SoundService.instance.playLayered(GameSound.softCard);
              AppHaptics.lightImpact();
              onExpand();
            },
          ),
        ),
      );
    }

    return _ExpandedGuide(
      unlockedThrough: unlockedThrough,
      visibleCount: _visibleCount,
      pagerTotal: _pagerTotal,
      maxFrontIndex: _maxFrontIndex,
      initialIndex: (initialPage ?? _maxFrontIndex).clamp(0, _maxFrontIndex),
      world: world,
      onCollapse: onCollapse,
    );
  }
}

class _CollapsedDeck extends StatelessWidget {
  const _CollapsedDeck({
    required this.world,
    required this.badge,
    this.onTap,
  });

  final JourneyWorld world;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = journeyPaletteFor(world);
    const w = 52.0;
    final h = w / homeCardAspect;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: w + 10,
        height: h + 10,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < 3; i++)
              Positioned(
                left: i * 3.0,
                top: (2 - i) * 2.5,
                width: w,
                height: h,
                child: JourneyFaceDownCard(
                  world: world,
                  showSuit: i == 2,
                  shadow: i == 2,
                  highlighted: i == 2,
                ),
              ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: palette.background,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _ExpandedGuide extends StatelessWidget {
  const _ExpandedGuide({
    required this.unlockedThrough,
    required this.visibleCount,
    required this.pagerTotal,
    required this.maxFrontIndex,
    required this.initialIndex,
    required this.world,
    required this.onCollapse,
  });

  final int unlockedThrough;
  final int visibleCount;
  final int pagerTotal;
  final int maxFrontIndex;
  final int initialIndex;
  final JourneyWorld world;
  final VoidCallback onCollapse;

  void _onBlocked(int _) {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final palette = journeyPaletteFor(world);

    return GestureDetector(
      onTap: () {
        SoundService.instance.playLayered(GameSound.softCard);
        onCollapse();
      },
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: CupertinoColors.black.withValues(alpha: .45),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {}, // absorb taps on the carousel
                  child: SizedBox(
                    width: 340,
                    height: 420,
                    child: StackedCardCarousel(
                      key: ValueKey(
                        'journey-guide-$unlockedThrough-$initialIndex',
                      ),
                      itemCount: visibleCount,
                      initialIndex: initialIndex,
                      maxFrontIndex: maxFrontIndex,
                      peekStyle: visibleCount >= 3
                          ? CardPeekStyle.fan
                          : CardPeekStyle.stack,
                      wrap: false,
                      animateBackIn: true,
                      widthFactor: 0.82,
                      maxCardWidth: 260,
                      fitToHeight: true,
                      onBlockedAdvance: _onBlocked,
                      itemBuilder: (context, index) {
                        final pageId = index + 1;
                        final locked = pageId > unlockedThrough;
                        if (locked) {
                          return _LockedInstructionCard(
                            pageLabel: '$pageId/$pagerTotal',
                            world: world,
                            palette: palette,
                            theme: theme,
                          );
                        }
                        final page = journeyInstructions[index];
                        return _InstructionCard(
                          instruction: page,
                          pageLabel: '${page.id}/$pagerTotal',
                          palette: palette,
                          theme: theme,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  onPressed: SoundService.wrapTap(onCollapse),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: theme.textPrimary.withValues(alpha: .9),
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

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.instruction,
    required this.pageLabel,
    required this.palette,
    required this.theme,
  });

  final JourneyInstruction instruction;
  final String pageLabel;
  final JourneyWorldPalette palette;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.accent.withValues(alpha: .7),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              instruction.title,
              style: theme.title.copyWith(
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  instruction.body,
                  style: theme.body.copyWith(
                    color: palette.text.withValues(alpha: .88),
                    height: 1.35,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                pageLabel,
                style: theme.caption.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedInstructionCard extends StatelessWidget {
  const _LockedInstructionCard({
    required this.pageLabel,
    required this.world,
    required this.palette,
    required this.theme,
  });

  final String pageLabel;
  final JourneyWorld world;
  final JourneyWorldPalette palette;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: .55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.55,
            child: JourneyFaceDownCard(
              world: world,
              showSuit: true,
              shadow: false,
              radius: 18,
            ),
          ),
          ColoredBox(color: palette.background.withValues(alpha: .35)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 28,
                  color: palette.accent.withValues(alpha: .9),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sealed',
                  style: theme.title.copyWith(
                    fontSize: 18,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pageLabel,
                  style: theme.caption.copyWith(
                    color: palette.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
