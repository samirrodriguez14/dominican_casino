import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_theme_unlock_ceremony.dart';
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
    this.carouselKey,
    this.initialPage,
    this.world = JourneyWorld.diamonds,
    this.showUnlockChallengerCta = false,
    this.unlockChallengerLabel = 'Unlock next challenger',
    this.onUnlockNextChallenger,
    this.showEnterKingdomCta = false,
    this.enterKingdomLabel = 'Enter Diamonds kingdom',
    this.enterKingdomPageId = 1,
    this.onEnterKingdom,
    this.ceremonyPageId,
    this.ceremonyT,
  });

  /// Highest unlocked 1-based instruction id.
  final int unlockedThrough;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final GlobalKey? deckKey;
  final GlobalKey<StackedCardCarouselState>? carouselKey;
  /// 0-based carousel index to open on (defaults to latest unlocked).
  final int? initialPage;
  final JourneyWorld world;
  final bool showUnlockChallengerCta;
  final String unlockChallengerLabel;
  final VoidCallback? onUnlockNextChallenger;
  /// CTA to enter a kingdom (Diamonds page 1, Clubs page 6, …).
  final bool showEnterKingdomCta;
  final String enterKingdomLabel;
  /// 1-based instruction page that shows [enterKingdomLabel].
  final int enterKingdomPageId;
  final VoidCallback? onEnterKingdom;
  /// 1-based page currently playing the sealed → reveal ceremony.
  final int? ceremonyPageId;
  /// Ceremony timeline 0→1 when [ceremonyPageId] is set.
  final double? ceremonyT;

  /// Unlocked pages, plus one locked "next" peek when more catalog remains.
  int get _visibleCount {
    if (unlockedThrough >= journeyInstructionCatalogSize) {
      return journeyInstructionCatalogSize;
    }
    return unlockedThrough + 1;
  }

  int get _pagerTotal => _visibleCount;

  /// 0-based highest index that may be brought to the front.
  int get _maxFrontIndex {
    final ceremony = ceremonyPageId;
    // During unlock ceremony the sealed page must be allowably fronted.
    if (ceremony != null) {
      return (ceremony - 1).clamp(0, _visibleCount - 1);
    }
    return (unlockedThrough - 1).clamp(0, _visibleCount - 1);
  }

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

    final ceremonyActive = ceremonyPageId != null && ceremonyT != null;
    return _ExpandedGuide(
      unlockedThrough: unlockedThrough,
      visibleCount: _visibleCount,
      pagerTotal: _pagerTotal,
      maxFrontIndex: _maxFrontIndex,
      initialIndex: (initialPage ?? (unlockedThrough - 1).clamp(0, _maxFrontIndex))
          .clamp(0, _maxFrontIndex),
      world: world,
      onCollapse: onCollapse,
      showUnlockChallengerCta: showUnlockChallengerCta,
      unlockChallengerLabel: unlockChallengerLabel,
      onUnlockNextChallenger: onUnlockNextChallenger,
      showEnterKingdomCta: showEnterKingdomCta,
      enterKingdomLabel: enterKingdomLabel,
      enterKingdomPageId: enterKingdomPageId,
      onEnterKingdom: onEnterKingdom,
      carouselKey: carouselKey,
      ceremonyPageId: ceremonyPageId,
      ceremonyT: ceremonyT,
      // Keep carousel alive across the unlock bump at boom.
      stableCarousel: ceremonyActive,
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
    this.showUnlockChallengerCta = false,
    this.unlockChallengerLabel = 'Unlock next challenger',
    this.onUnlockNextChallenger,
    this.showEnterKingdomCta = false,
    this.enterKingdomLabel = 'Enter Diamonds kingdom',
    this.enterKingdomPageId = 1,
    this.onEnterKingdom,
    this.carouselKey,
    this.ceremonyPageId,
    this.ceremonyT,
    this.stableCarousel = false,
  });

  final int unlockedThrough;
  final int visibleCount;
  final int pagerTotal;
  final int maxFrontIndex;
  final int initialIndex;
  final JourneyWorld world;
  final VoidCallback onCollapse;
  final bool showUnlockChallengerCta;
  final String unlockChallengerLabel;
  final VoidCallback? onUnlockNextChallenger;
  final bool showEnterKingdomCta;
  final String enterKingdomLabel;
  final int enterKingdomPageId;
  final VoidCallback? onEnterKingdom;
  final GlobalKey<StackedCardCarouselState>? carouselKey;
  final int? ceremonyPageId;
  final double? ceremonyT;
  final bool stableCarousel;

  void _onBlocked(int _) {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
  }

  bool get _ceremonyActive =>
      ceremonyPageId != null && ceremonyT != null;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final palette = journeyPaletteFor(world);
    final blockDismiss = showUnlockChallengerCta || _ceremonyActive;

    return GestureDetector(
      onTap: blockDismiss
          ? null
          : () {
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
                      key: carouselKey ??
                          ValueKey(
                            stableCarousel
                                ? 'journey-guide-ceremony'
                                : 'journey-guide-$unlockedThrough-$initialIndex',
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
                        final isCeremonyPage = ceremonyPageId == pageId &&
                            ceremonyT != null;

                        Widget card;
                        if (isCeremonyPage) {
                          card = _CeremonyInstructionCard(
                            pageId: pageId,
                            pagerTotal: pagerTotal,
                            world: world,
                            palette: palette,
                            theme: theme,
                            timeline: JourneyThemeUnlockTimeline(ceremonyT!),
                            unlockedThrough: unlockedThrough,
                            showUnlockChallengerCta: showUnlockChallengerCta,
                            unlockChallengerLabel: unlockChallengerLabel,
                            onUnlockNextChallenger: onUnlockNextChallenger,
                          );
                        } else if (locked) {
                          card = _LockedInstructionCard(
                            pageLabel: '$pageId/$pagerTotal',
                            world: world,
                            palette: palette,
                            theme: theme,
                          );
                        } else {
                          final page = journeyInstructions[index];
                          final isLatest = pageId == unlockedThrough;
                          final showEnter = showEnterKingdomCta &&
                              page.id == enterKingdomPageId &&
                              onEnterKingdom != null;
                          card = _InstructionCard(
                            instruction: page,
                            pageLabel: '${page.id}/$pagerTotal',
                            palette: palette,
                            theme: theme,
                            unlockChallengerLabel: showUnlockChallengerCta &&
                                    isLatest &&
                                    onUnlockNextChallenger != null
                                ? unlockChallengerLabel
                                : null,
                            onUnlockChallenger:
                                showUnlockChallengerCta && isLatest
                                    ? onUnlockNextChallenger
                                    : null,
                            enterKingdomLabel:
                                showEnter ? enterKingdomLabel : null,
                            onEnterKingdom: showEnter ? onEnterKingdom : null,
                          );
                        }

                        return card;
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
                  onPressed: blockDismiss
                      ? null
                      : SoundService.wrapTap(onCollapse),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: theme.textPrimary.withValues(
                      alpha: blockDismiss ? .35 : .9,
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

/// Sealed instruction that shakes, breaks, and reveals catalog copy.
class _CeremonyInstructionCard extends StatelessWidget {
  const _CeremonyInstructionCard({
    required this.pageId,
    required this.pagerTotal,
    required this.world,
    required this.palette,
    required this.theme,
    required this.timeline,
    required this.unlockedThrough,
    required this.showUnlockChallengerCta,
    required this.unlockChallengerLabel,
    this.onUnlockNextChallenger,
  });

  final int pageId;
  final int pagerTotal;
  final JourneyWorld world;
  final JourneyWorldPalette palette;
  final AppTheme theme;
  final JourneyThemeUnlockTimeline timeline;
  final int unlockedThrough;
  final bool showUnlockChallengerCta;
  final String unlockChallengerLabel;
  final VoidCallback? onUnlockNextChallenger;

  @override
  Widget build(BuildContext context) {
    final page = journeyInstructionById(pageId) ??
        (pageId >= 1 && pageId <= journeyInstructions.length
            ? journeyInstructions[pageId - 1]
            : null);
    final isLatest = pageId == unlockedThrough || timeline.pastBoom;
    final revealed = page == null
        ? _LockedInstructionCard(
            pageLabel: '$pageId/$pagerTotal',
            world: world,
            palette: palette,
            theme: theme,
          )
        : _InstructionCard(
            instruction: page,
            pageLabel: '${page.id}/$pagerTotal',
            palette: palette,
            theme: theme,
            unlockChallengerLabel: showUnlockChallengerCta &&
                    isLatest &&
                    timeline.pastBoom &&
                    onUnlockNextChallenger != null
                ? unlockChallengerLabel
                : null,
            onUnlockChallenger: showUnlockChallengerCta &&
                    isLatest &&
                    timeline.pastBoom
                ? onUnlockNextChallenger
                : null,
          );

    return JourneyThemeUnlockTransform(
      timeline: timeline,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: timeline.revealAmount,
            child: revealed,
          ),
          Opacity(
            opacity: timeline.lockOpacity,
            child: _LockedInstructionCard(
              pageLabel: '$pageId/$pagerTotal',
              world: world,
              palette: palette,
              theme: theme,
            ),
          ),
        ],
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
    this.unlockChallengerLabel,
    this.onUnlockChallenger,
    this.enterKingdomLabel,
    this.onEnterKingdom,
  });

  final JourneyInstruction instruction;
  final String pageLabel;
  final JourneyWorldPalette palette;
  final AppTheme theme;
  final String? unlockChallengerLabel;
  final VoidCallback? onUnlockChallenger;
  final String? enterKingdomLabel;
  final VoidCallback? onEnterKingdom;

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
            if (enterKingdomLabel != null && onEnterKingdom != null) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                color: palette.accent.withValues(alpha: .95),
                minimumSize: Size.zero,
                onPressed: SoundService.wrapTap(onEnterKingdom),
                child: Text(
                  enterKingdomLabel!,
                  style: TextStyle(
                    color: palette.background,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (unlockChallengerLabel != null &&
                onUnlockChallenger != null) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                color: palette.accent.withValues(alpha: .95),
                minimumSize: Size.zero,
                onPressed: SoundService.wrapTap(onUnlockChallenger),
                child: Text(
                  unlockChallengerLabel!,
                  style: TextStyle(
                    color: palette.background,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
