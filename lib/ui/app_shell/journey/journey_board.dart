import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/models/journey_instruction.dart';
import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/models/local_bot_roster.dart';
import 'package:dominican_casino/models/theme_avatar_unlocks.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_active_stage.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_coach.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_defeated_carousel.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_defeated_row.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_enter_kingdom.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_instruction_deck.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_loss_taunt.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_progress_trail.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_story_convos.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_theme_unlock_ceremony.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_world_piles.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/journey_theme_unlock_reward.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

export 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart'
    show JourneyDealPlan, JourneyDealSlot, JourneyOpenProgress;

/// Four-band Journey board: piles / progress trail / active stage / defeated.
class JourneyBoard extends StatefulWidget {
  const JourneyBoard({
    super.key,
    this.openProgress = JourneyOpenProgress.settled,
    this.onWorldThemeEquipped,
  });

  static const worldCount = JourneyDealPlan.worldCount;
  static const cardsPerPile = JourneyDealPlan.cardsPerPile;
  static const dealCardCount = JourneyDealPlan.dealCardCount;

  final JourneyOpenProgress openProgress;
  final ValueChanged<JourneyWorld>? onWorldThemeEquipped;

  static List<JourneyDealSlot> dealPlanFor(JourneyDisplaySnapshot snap) =>
      JourneyDealPlan.forSnapshot(snap);

  static int challengerCount(List<JourneyDealSlot> plan) =>
      JourneyDealPlan.challengerCount(plan);

  static int defeatedCount(List<JourneyDealSlot> plan) =>
      JourneyDealPlan.defeatedCount(plan);

  static double challengerFlight(
    List<JourneyDealSlot> plan,
    double pileDeal,
    int challengerIndex,
  ) =>
      JourneyDealPlan.challengerFlight(plan, pileDeal, challengerIndex);

  static double defeatedFlight(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    int defeatedIndex,
  ) =>
      JourneyDealPlan.defeatedFlight(plan, defeatedDeal, defeatedIndex);

  static int challengerLandedDepth(
    List<JourneyDealSlot> plan,
    double pileDeal,
    JourneyWorld world,
  ) =>
      JourneyDealPlan.challengerLandedDepth(plan, pileDeal, world);

  static int defeatedLandedCount(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    JourneyWorld world,
  ) =>
      JourneyDealPlan.defeatedLandedCount(plan, defeatedDeal, world);

  @override
  State<JourneyBoard> createState() => JourneyBoardState();
}

class JourneyBoardState extends State<JourneyBoard>
    with TickerProviderStateMixin {
  static const _flipDuration = Duration(milliseconds: 720);
  static const _defeatFlyDuration = Duration(milliseconds: 520);
  static const _revealDuration = Duration(milliseconds: 1700);
  static const _themeUnlockDuration = Duration(milliseconds: 1700);
  static const _instructionUnlockDuration = Duration(milliseconds: 1700);

  late List<JourneyWorldDef> _worlds;
  JourneyWorld _activeWorld = JourneyWorld.diamonds;
  JourneyCardDef? _selected;
  /// Where the focused card lives when not centered.
  bool _selectedFromDefeated = false;
  /// First Jack unlock: fly from pile face-down, flip into focus, then unlock.
  bool _selectStartsFaceDown = false;
  Offset? _selectFromOverride;
  late final AnimationController _selectAnim;
  late final AnimationController _defeatFlyAnim;
  late final AnimationController _revealAnim;
  late final AnimationController _themeUnlockAnim;
  late final AnimationController _instructionUnlockAnim;
  JourneyCardDef? _defeatFlying;
  /// Override flight target (Ace → trail token); null uses defeated pile.
  Offset? _defeatFlyTo;
  double _defeatFlySize = 0;
  JourneyCardDef? _revealCard;

  /// Live drag of a pile card toward the center.
  JourneyCardDef? _dragging;
  bool _draggingFromDefeated = false;
  Offset? _dragPos;

  final GlobalKey _pilesKey = GlobalKey();
  final GlobalKey _centerKey = GlobalKey();
  final GlobalKey _defeatedKey = GlobalKey();
  final GlobalKey _trailKey = GlobalKey();
  final GlobalKey _trailTokenKey = GlobalKey();
  final GlobalKey _instructionDeckKey = GlobalKey();
  final GlobalKey<StackedCardCarouselState> _instructionCarouselKey =
      GlobalKey();
  final Map<JourneyWorld, GlobalKey> _pileKeys = {
    for (final w in JourneyWorld.values) w: GlobalKey(),
  };
  late final JourneyCoachController _coach;
  late final JourneyJackIntroController _jackIntro;
  late final JourneyQueenIntroController _queenIntro;
  late final JourneyKingIntroController _kingIntro;
  late final JourneyAceEscapeController _aceEscape;
  late final JourneyClubsJackIntroController _clubsJackIntro;
  late final JourneyClubsCourtController _clubsCourt;
  late final JourneyClubsAceOfferController _clubsAceOffer;
  late final JourneyClubsHeartsSendoffController _clubsHeartsSendoff;
  late final JourneyHeartsJackIntroController _heartsJackIntro;
  late final JourneyHeartsQueenEscortController _heartsQueenEscort;
  late final JourneyHeartsKingIntroController _heartsKingIntro;
  late final JourneyHeartsAceOfferController _heartsAceOffer;
  late final JourneySpadesJackIntroController _spadesJackIntro;
  late final JourneySpadesKingEscortController _spadesKingEscort;
  late final JourneySpadesCampController _spadesCamp;
  late final JourneySpadesRuinsApproachController _spadesRuinsApproach;
  late final JourneySpadesRuinsClimaxController _spadesRuinsClimax;
  late final JourneySpadesFinaleController _spadesFinale;

  JourneyWorld? _themeUnlockWorld;
  bool _themeUnlockForceSealed = false;
  bool _themeUnlockApplied = false;
  Future<void>? _themeUnlockApplyFuture;
  JourneyWorld? _themeUnlockRewardWorld;
  /// After Diamonds theme reward, unlock instruction page 2 with ceremony.
  bool _pendingDiamondsInstructionReveal = false;
  /// After Clubs theme reward, start Clubs Jack bushes intro.
  bool _pendingClubsJackIntro = false;
  /// After Hearts theme reward, start Hearts Jack court intro.
  bool _pendingHeartsJackIntro = false;
  /// After Spades theme reward, unlock briefing page 13.
  bool _pendingSpadesBriefing = false;
  int? _instructionCeremonyPageId;
  bool _instructionCeremonyUnlocked = false;
  bool _instructionCeremonyShowCta = false;

  bool _guideExpanded = false;
  int? _guideOpenPage;
  bool _coachScheduled = false;
  bool _jackIntroScheduled = false;
  bool _queenIntroScheduled = false;
  bool _kingIntroScheduled = false;
  bool _aceEscapeScheduled = false;
  bool _clubsJackIntroScheduled = false;
  bool _clubsCourtScheduled = false;
  bool _clubsAceOfferScheduled = false;
  bool _clubsHeartsSendoffScheduled = false;
  bool _heartsJackIntroScheduled = false;
  bool _heartsQueenEscortScheduled = false;
  bool _heartsKingIntroScheduled = false;
  bool _heartsAceOfferScheduled = false;
  bool _spadesJackIntroScheduled = false;
  bool _spadesKingEscortScheduled = false;
  bool _spadesCampScheduled = false;
  bool _spadesRuinsApproachScheduled = false;
  bool _spadesRuinsClimaxScheduled = false;
  bool _spadesFinaleScheduled = false;
  /// After page 14 unlock: wait for Continue before ruins approach.
  bool _pendingSpadesRuinsApproachContinue = false;
  /// After page 15 unlock: wait for Continue before ruins climax.
  bool _pendingSpadesRuinsClimaxContinue = false;
  /// After page 16 unlock: wait for Continue before dismissing the letter CTA.
  bool _pendingSpadesFinaleLetterContinue = false;
  bool _sessionTutorialDone = false;
  AppRepo? _repo;
  int _lastLevel = 1;
  int _lastStoryEpoch = 0;
  bool _tauntScheduled = false;
  /// Lagged unlock count while celebrating a win (null = live value).
  int? _guideDisplayedUnlock;
  bool _guideShowUnlockCta = false;
  JourneyCardDef? _pendingUnlockCard;
  /// Center carousel when browsing a defeated kingdom stack.
  JourneyWorld? _defeatedCarouselWorld;
  JourneyRank _defeatedCarouselRank = JourneyRank.queen;
  late final AnimationController _trailTokenEat;
  bool _trophiesOpen = false;

  @override
  void initState() {
    super.initState();
    _worlds = _copyWorlds(journeyBoardSnapshot);
    _selectAnim = AnimationController(vsync: this, duration: _flipDuration);
    _defeatFlyAnim = AnimationController(
      vsync: this,
      duration: _defeatFlyDuration,
    );
    _revealAnim = AnimationController(vsync: this, duration: _revealDuration);
    _themeUnlockAnim = AnimationController(
      vsync: this,
      duration: _themeUnlockDuration,
    );
    _themeUnlockAnim.addListener(_onThemeUnlockTick);
    _instructionUnlockAnim = AnimationController(
      vsync: this,
      duration: _instructionUnlockDuration,
    );
    _instructionUnlockAnim.addListener(_onInstructionUnlockTick);
    _trailTokenEat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _coach = JourneyCoachController(
      trailKey: _trailKey,
      deckKey: _instructionDeckKey,
    );
    _jackIntro = JourneyJackIntroController();
    _queenIntro = JourneyQueenIntroController();
    _kingIntro = JourneyKingIntroController();
    _aceEscape = JourneyAceEscapeController();
    _clubsJackIntro = JourneyClubsJackIntroController();
    _clubsCourt = JourneyClubsCourtController();
    _clubsAceOffer = JourneyClubsAceOfferController();
    _clubsHeartsSendoff = JourneyClubsHeartsSendoffController();
    _heartsJackIntro = JourneyHeartsJackIntroController();
    _heartsQueenEscort = JourneyHeartsQueenEscortController();
    _heartsKingIntro = JourneyHeartsKingIntroController();
    _heartsAceOffer = JourneyHeartsAceOfferController();
    _spadesJackIntro = JourneySpadesJackIntroController();
    _spadesKingEscort = JourneySpadesKingEscortController();
    _spadesCamp = JourneySpadesCampController();
    _spadesRuinsApproach = JourneySpadesRuinsApproachController();
    _spadesRuinsClimax = JourneySpadesRuinsClimaxController();
    _spadesFinale = JourneySpadesFinaleController();
    _bindStoryLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<AppRepo>();
      final done = repo.player?.completedJourneyTutorial ?? false;
      await repo.maybeRestoreMistakenJackDefeat();
      if (!mounted) return;
      _lastLevel = repo.experienceProgress.level;
      _lastStoryEpoch = repo.journeyStoryEpoch;
      setState(() {
        _sessionTutorialDone = done;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      _maybeShowPendingLossTaunt();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<AppRepo>();
    if (!identical(_repo, repo)) {
      _repo?.removeListener(_onRepoChanged);
      _repo = repo;
      _repo!.addListener(_onRepoChanged);
      _bindStoryLocale();
    }
  }

  /// Keep story dialogue controllers on the live app locale.
  void _bindStoryLocale() {
    bool isEs() => (_repo?.locale.languageCode ?? 'en') == 'es';
    _coach.isEs = isEs;
    _jackIntro.isEs = isEs;
    _queenIntro.isEs = isEs;
    _kingIntro.isEs = isEs;
    _aceEscape.isEs = isEs;
    _clubsJackIntro.isEs = isEs;
    _clubsCourt.isEs = isEs;
    _clubsAceOffer.isEs = isEs;
    _clubsHeartsSendoff.isEs = isEs;
    _heartsJackIntro.isEs = isEs;
    _heartsQueenEscort.isEs = isEs;
    _heartsKingIntro.isEs = isEs;
    _heartsAceOffer.isEs = isEs;
    _spadesJackIntro.isEs = isEs;
    _spadesKingEscort.isEs = isEs;
    _spadesCamp.isEs = isEs;
    _spadesRuinsApproach.isEs = isEs;
    _spadesRuinsClimax.isEs = isEs;
    _spadesFinale.isEs = isEs;
  }

  JourneyL10n get _jl10n =>
      JourneyL10n((_repo?.locale.languageCode ?? 'en') == 'es');

  @override
  void dispose() {
    _repo?.removeListener(_onRepoChanged);
    _themeUnlockAnim.removeListener(_onThemeUnlockTick);
    _instructionUnlockAnim.removeListener(_onInstructionUnlockTick);
    _selectAnim.dispose();
    _defeatFlyAnim.dispose();
    _revealAnim.dispose();
    _themeUnlockAnim.dispose();
    _instructionUnlockAnim.dispose();
    _trailTokenEat.dispose();
    _coach.dispose();
    _jackIntro.dispose();
    _queenIntro.dispose();
    _kingIntro.dispose();
    _aceEscape.dispose();
    _clubsJackIntro.dispose();
    _clubsCourt.dispose();
    _clubsAceOffer.dispose();
    _clubsHeartsSendoff.dispose();
    _heartsJackIntro.dispose();
    _heartsQueenEscort.dispose();
    _heartsKingIntro.dispose();
    _heartsAceOffer.dispose();
    _spadesJackIntro.dispose();
    _spadesKingEscort.dispose();
    _spadesCamp.dispose();
    _spadesRuinsApproach.dispose();
    _spadesRuinsClimax.dispose();
    _spadesFinale.dispose();
    super.dispose();
  }

  void pulseTrailTokenEat() {
    _trailTokenEat.forward(from: 0);
  }

  /// Spit the Journey trophies card out of the trail avatar (and eat on close).
  Future<void> openJourneyTrophies({JourneyWorld? revealWorld}) async {
    if (!mounted || _trophiesOpen) return;
    _trophiesOpen = true;
    final repo = context.read<AppRepo>();
    try {
      await showJourneyAceAccessoriesPopup(
        context,
        avatarId: repo.player?.avatarId,
        defeatedAces: repo.journeyProgress.defeatedAceWorlds,
        sourceKey: _trailTokenKey,
        onSourcePulse: pulseTrailTokenEat,
        revealWorld: revealWorld,
      );
    } finally {
      _trophiesOpen = false;
    }
  }

  void _onThemeUnlockTick() {
    if (!mounted || _themeUnlockWorld == null) return;
    final timeline = JourneyThemeUnlockTimeline(_themeUnlockAnim.value);
    if (!_themeUnlockApplied && timeline.shouldApplyTheme) {
      _themeUnlockApplied = true;
      AppHaptics.heavyImpact();
      SoundService.instance.play(GameSound.win);
      final world = _themeUnlockWorld!;
      final repo = context.read<AppRepo>();
      _themeUnlockApplyFuture = world == JourneyWorld.diamonds
          ? repo.enterDiamondsKingdom()
          : world == JourneyWorld.clubs
              ? repo.enterClubsKingdom()
              : world == JourneyWorld.hearts
                  ? repo.enterHeartsKingdom()
                  : world == JourneyWorld.spades
                      ? repo.enterSpadesKingdom()
                      : repo.unlockAndEquipPack(world.themeId).then((_) {});
      widget.onWorldThemeEquipped?.call(world);
    }
    setState(() {});
  }

  /// First-time theme unlock ceremony for [world]. Returns false if cancelled.
  Future<bool> _runThemeUnlockCeremony(JourneyWorld world) async {
    if (_themeUnlockWorld != null) return false;
    final repo = context.read<AppRepo>();
    if (!repo.canEnterKingdom(world)) return false;
    final alreadyOwned = repo.ownsPack(world.themeId) &&
        repo.journeyProgress.hasEntered(world);
    if (alreadyOwned) {
      if (world == JourneyWorld.clubs) {
        await repo.enterClubsKingdom();
      } else if (world == JourneyWorld.hearts) {
        await repo.enterHeartsKingdom();
      } else if (world == JourneyWorld.spades) {
        await repo.enterSpadesKingdom();
      } else {
        await repo.unlockAndEquipPack(world.themeId);
      }
      if (!mounted) return false;
      widget.onWorldThemeEquipped?.call(world);
      return true;
    }

    final boardUnlocked = _snapshot.worldOf(world).unlocked;
    setState(() {
      _guideExpanded = false;
      _defeatedCarouselWorld = null;
      _selected = null;
      _selectAnim.value = 0;
      _themeUnlockWorld = world;
      _themeUnlockForceSealed = boardUnlocked;
      _themeUnlockApplied = false;
      _themeUnlockApplyFuture = null;
      _activeWorld = world;
    });
    _themeUnlockAnim.value = 0;
    AppHaptics.mediumImpact();
    SoundService.instance.playLayered(GameSound.softCard);
    await _themeUnlockAnim.forward();
    if (!mounted) return false;

    // Ensure unlock landed even if the boom tick was skipped.
    if (!_themeUnlockApplied) {
      _themeUnlockApplied = true;
      _themeUnlockApplyFuture = world == JourneyWorld.diamonds
          ? repo.enterDiamondsKingdom()
          : world == JourneyWorld.clubs
              ? repo.enterClubsKingdom()
              : world == JourneyWorld.hearts
                  ? repo.enterHeartsKingdom()
                  : world == JourneyWorld.spades
                      ? repo.enterSpadesKingdom()
                      : repo.unlockAndEquipPack(world.themeId).then((_) {});
      widget.onWorldThemeEquipped?.call(world);
    }
    await _themeUnlockApplyFuture;
    if (!mounted) return false;

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _themeUnlockWorld = null;
      _themeUnlockForceSealed = false;
      _themeUnlockRewardWorld = world;
      // Diamonds: hold instruction page 2 sealed until the reward is dismissed.
      if (world == JourneyWorld.diamonds) {
        _pendingDiamondsInstructionReveal = true;
        _guideDisplayedUnlock = 1;
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      }
      if (world == JourneyWorld.clubs) {
        _pendingClubsJackIntro = true;
      }
      if (world == JourneyWorld.hearts) {
        _pendingHeartsJackIntro = true;
      }
      if (world == JourneyWorld.spades) {
        _pendingSpadesBriefing = true;
      }
    });
    _themeUnlockAnim.value = 0;
    return true;
  }

  void _onInstructionUnlockTick() {
    if (!mounted || _instructionCeremonyPageId == null) return;
    final timeline = JourneyThemeUnlockTimeline(_instructionUnlockAnim.value);
    if (!_instructionCeremonyUnlocked && timeline.pastBoom) {
      _instructionCeremonyUnlocked = true;
      AppHaptics.heavyImpact();
      SoundService.instance.playLayered(GameSound.softCard);
      setState(() {
        _guideDisplayedUnlock = _instructionCeremonyPageId;
        _guideOpenPage = (_instructionCeremonyPageId! - 1).clamp(0, 100);
      });
    } else {
      setState(() {});
    }
  }

  /// Open the guide on the sealed next page, then shake → boom → reveal.
  Future<void> _runInstructionUnlockCeremony({
    required int beforeUnlock,
    required int afterUnlock,
    bool showUnlockCtaAfter = false,
  }) async {
    if (!mounted || afterUnlock <= beforeUnlock) return;
    if (_instructionCeremonyPageId != null) return;

    final sealedIndex = afterUnlock - 1;
    setState(() {
      _guideExpanded = true;
      // Hold unlock count so the target page stays sealed while front.
      _guideDisplayedUnlock = beforeUnlock;
      // Open directly on the sealed page (allowed via ceremony maxFrontIndex).
      _guideOpenPage = sealedIndex;
      _guideShowUnlockCta = false;
      _instructionCeremonyPageId = afterUnlock;
      _instructionCeremonyUnlocked = false;
      _instructionCeremonyShowCta = showUnlockCtaAfter;
      _instructionUnlockAnim.value = 0;
    });

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    // Ensure the sealed page is front even if the carousel remounted.
    await _instructionCarouselKey.currentState?.goToIndex(sealedIndex);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    AppHaptics.mediumImpact();
    SoundService.instance.playLayered(GameSound.softCard);
    await _instructionUnlockAnim.forward();
    if (!mounted) return;

    if (!_instructionCeremonyUnlocked) {
      _instructionCeremonyUnlocked = true;
      setState(() {
        _guideDisplayedUnlock = afterUnlock;
        _guideOpenPage = sealedIndex;
      });
    }

    setState(() {
      _instructionCeremonyPageId = null;
      _guideShowUnlockCta = _instructionCeremonyShowCta;
      _instructionCeremonyShowCta = false;
    });
    _instructionUnlockAnim.value = 0;
  }

  Future<void> _onThemeUnlockRewardDismissed({
    required bool goToProfile,
  }) async {
    final rewardWorld = _themeUnlockRewardWorld;
    if (!mounted) return;
    setState(() => _themeUnlockRewardWorld = null);

    if (rewardWorld == JourneyWorld.clubs && _pendingClubsJackIntro) {
      _pendingClubsJackIntro = false;
      if (!context.read<AppRepo>().journeyProgress.clubsJackIntroSeen) {
        _startClubsJackIntro();
      }
      return;
    }

    if (rewardWorld == JourneyWorld.hearts && _pendingHeartsJackIntro) {
      _pendingHeartsJackIntro = false;
      if (!context.read<AppRepo>().journeyProgress.heartsJackIntroSeen) {
        _startHeartsJackIntro();
      }
      return;
    }

    if (rewardWorld == JourneyWorld.spades && _pendingSpadesBriefing) {
      _pendingSpadesBriefing = false;
      await _runInstructionUnlockCeremony(
        beforeUnlock: 12,
        afterUnlock: 13,
        showUnlockCtaAfter: true,
      );
      return;
    }

    if (rewardWorld != JourneyWorld.diamonds ||
        !_pendingDiamondsInstructionReveal) {
      return;
    }

    // Profile path: keep pending so Games tab return can reveal later.
    if (goToProfile) return;

    _pendingDiamondsInstructionReveal = false;
    await _runInstructionUnlockCeremony(
      beforeUnlock: 1,
      afterUnlock: 2,
      showUnlockCtaAfter: true,
    );
  }

  /// Called when the Games tab is focused again (e.g. after Go to profile).
  void onShellTabVisible() {
    if (_pendingDiamondsInstructionReveal &&
        _themeUnlockRewardWorld == null &&
        _instructionCeremonyPageId == null) {
      _pendingDiamondsInstructionReveal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _runInstructionUnlockCeremony(
          beforeUnlock: 1,
          afterUnlock: 2,
          showUnlockCtaAfter: true,
        );
      });
      return;
    }
    _maybeStartJackIntro();
  }

  List<JourneyWorldDef> _copyWorlds(JourneyDisplaySnapshot snap) {
    return [
      for (final world in snap.worlds)
        JourneyWorldDef(
          world: world.world,
          unlocked: world.unlocked,
          cards: List<JourneyCardDef>.from(world.cards),
        ),
    ];
  }

  void _onRepoChanged() {
    if (!mounted || _repo == null) return;
    final level = _repo!.experienceProgress.level;
    final epoch = _repo!.journeyStoryEpoch;
    if (epoch != _lastStoryEpoch) {
      _lastStoryEpoch = epoch;
      _lastLevel = level;
      _applyStoryResetFromRepo();
      return;
    }
    if (level == _lastLevel) return;
    _lastLevel = level;
    setState(() {
      _worlds = _copyWorlds(_repo!.journeyBoardForLevel(level));
    });
  }

  void _applyStoryResetFromRepo() {
    _selectAnim.stop();
    _selectAnim.value = 0;
    _defeatFlyAnim.stop();
    _defeatFlyAnim.value = 0;
    _revealAnim.stop();
    _revealAnim.value = 0;
    _themeUnlockAnim.stop();
    _themeUnlockAnim.value = 0;
    _instructionUnlockAnim.stop();
    _instructionUnlockAnim.value = 0;
    _coach.reset();
    _jackIntro.reset();
    _queenIntro.reset();
    _kingIntro.reset();
    _aceEscape.reset();
    _clubsJackIntro.reset();
    _clubsCourt.reset();
    _clubsAceOffer.reset();
    _clubsHeartsSendoff.reset();
    _heartsJackIntro.reset();
    _heartsQueenEscort.reset();
    _heartsKingIntro.reset();
    _heartsAceOffer.reset();
    _spadesJackIntro.reset();
    _spadesKingEscort.reset();
    _spadesCamp.reset();
    _spadesRuinsApproach.reset();
    _spadesRuinsClimax.reset();
    _spadesFinale.reset();
    setState(() {
      _worlds = _copyWorlds(_repo!.journeyBoardForLevel());
      _activeWorld = _resumeWorldAfterStoryReset(_repo!.journeyProgress);
      _selected = null;
      _selectedFromDefeated = false;
      _selectStartsFaceDown = false;
      _selectFromOverride = null;
      _defeatFlying = null;
      _revealCard = null;
      _dragging = null;
      _draggingFromDefeated = false;
      _dragPos = null;
      _guideExpanded = false;
      _guideOpenPage = null;
      _coachScheduled = false;
      _jackIntroScheduled = false;
      _queenIntroScheduled = false;
      _kingIntroScheduled = false;
      _aceEscapeScheduled = false;
      _clubsJackIntroScheduled = false;
      _clubsCourtScheduled = false;
      _clubsAceOfferScheduled = false;
      _clubsHeartsSendoffScheduled = false;
      _heartsJackIntroScheduled = false;
      _heartsQueenEscortScheduled = false;
      _heartsKingIntroScheduled = false;
      _heartsAceOfferScheduled = false;
      _spadesJackIntroScheduled = false;
      _spadesKingEscortScheduled = false;
      _spadesCampScheduled = false;
      _spadesRuinsApproachScheduled = false;
      _spadesRuinsClimaxScheduled = false;
      _spadesFinaleScheduled = false;
      _pendingSpadesRuinsApproachContinue = false;
      _pendingSpadesRuinsClimaxContinue = false;
      _pendingSpadesFinaleLetterContinue = false;
      _sessionTutorialDone = false;
      _tauntScheduled = false;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _themeUnlockWorld = null;
      _themeUnlockRewardWorld = null;
      _pendingDiamondsInstructionReveal = false;
      _pendingClubsJackIntro = false;
      _pendingHeartsJackIntro = false;
      _pendingSpadesBriefing = false;
      _instructionCeremonyPageId = null;
      _instructionCeremonyUnlocked = false;
      _instructionCeremonyShowCta = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeStartCoach();
      _resumeStoryAfterSoftRestart();
    });
  }

  JourneyWorld _resumeWorldAfterStoryReset(JourneyProgress progress) {
    for (final world in JourneyWorld.values.reversed) {
      if (progress.hasEntered(world)) return world;
    }
    return JourneyWorld.diamonds;
  }

  void _resumeStoryAfterSoftRestart() {
    final progress = _repo?.journeyProgress;
    if (progress == null) return;

    if (progress.hasEntered(JourneyWorld.spades) &&
        !progress.spadesJackIntroSeen) {
      setState(() => _activeWorld = JourneyWorld.spades);
      _runInstructionUnlockCeremony(
        beforeUnlock: 12,
        afterUnlock: 13,
        showUnlockCtaAfter: true,
      );
      return;
    }
    if (progress.hasEntered(JourneyWorld.hearts) &&
        !progress.heartsJackIntroSeen) {
      setState(() => _activeWorld = JourneyWorld.hearts);
      _startHeartsJackIntro();
      return;
    }
    if (progress.hasEntered(JourneyWorld.clubs) &&
        !progress.clubsJackIntroSeen) {
      setState(() => _activeWorld = JourneyWorld.clubs);
      _startClubsJackIntro();
      return;
    }
    if (progress.diamondsEntered &&
        !progress.diamondsJackUnlocked &&
        !progress.diamondsJackIntroSeen) {
      setState(() => _activeWorld = JourneyWorld.diamonds);
      _startJackIntro();
    }
  }

  Future<void> _maybeShowPendingLossTaunt() async {
    if (_tauntScheduled || !mounted) return;
    final repo = context.read<AppRepo>();
    final taunt = repo.journeyProgress.pendingLossTaunt;
    if (taunt == null) return;
    _tauntScheduled = true;
    final card = _snapshot.worldOf(taunt.world).cardOf(taunt.rank) ??
        JourneyCardDef(
          world: taunt.world,
          rank: taunt.rank,
          state: JourneyCardState.available,
          requiredLevel: 1,
          gameMode: journeyGameForRank(taunt.rank),
        );
    final action = await showJourneyLossTaunt(
      context,
      card: card,
      message: taunt.world == JourneyWorld.spades &&
              taunt.rank == JourneyRank.king
          ? _jl10n.iToldYouNotToLose
          : null,
    );
    if (!mounted) return;
    await repo.clearPendingJourneyLossTaunt();
    _tauntScheduled = false;
    if (!mounted) return;

    if (action == JourneyLossAction.restartKingdom) {
      await repo.restartJourneyAtKingdom(card.world);
      return;
    }

    // Replay (default): immediately rematch the same challenger.
    if (action == JourneyLossAction.replay || action == null) {
      if (card.state == JourneyCardState.defeated) {
        await _selectCard(card, fromDefeated: true, skipEquip: true);
      } else if (card.isSelectable) {
        await _selectCard(card, fromDefeated: false, skipEquip: true);
      }
      if (!mounted) return;
      await _startJourneyMatch(card);
    }
  }

  Future<void> _maybeShowReplayPraise() async {
    if (!mounted) return;
    final repo = context.read<AppRepo>();
    final praise = repo.journeyProgress.pendingReplayPraise;
    if (praise == null) return;
    final card = _snapshot.worldOf(praise.world).cardOf(praise.rank) ??
        JourneyCardDef(
          world: praise.world,
          rank: praise.rank,
          state: JourneyCardState.defeated,
          requiredLevel: 1,
          gameMode: journeyGameForRank(praise.rank),
        );
    await showJourneyReplayPraise(context, card: card);
    if (!mounted) return;
    await repo.clearPendingReplayPraise();
  }

  @override
  void didUpdateWidget(covariant JourneyBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStartCoach();
    _maybeStartJackIntro();
    _maybeStartQueenIntro();
  }

  void _maybeStartCoach() {
    if (_coachScheduled || _coach.isActive || _coach.isFinished) return;
    if (_coach.isWaitingForLetter) return;
    final open = widget.openProgress;
    final settled = open.pileDeal > 0.95 &&
        open.defeatedDeal > 0.95 &&
        open.cardGather < 0.02;
    if (!settled) return;
    final alreadyDone =
        context.read<AppRepo>().player?.completedJourneyTutorial ?? false;
    if (alreadyDone) {
      if (!_sessionTutorialDone) {
        setState(() => _sessionTutorialDone = true);
      }
      return;
    }
    _coachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _coach.start();
      setState(() {});
    });
  }

  void _maybeStartJackIntro() {
    if (_jackIntroScheduled || _jackIntro.isActive || _jackIntro.isFinished) {
      return;
    }
    if (_coach.isActive ||
        _coach.isWaitingForLetter ||
        _queenIntro.isActive ||
        _guideExpanded ||
        _themeUnlockWorld != null ||
        _themeUnlockRewardWorld != null ||
        _pendingDiamondsInstructionReveal ||
        _instructionCeremonyPageId != null) {
      return;
    }
    final open = widget.openProgress;
    final settled = open.pileDeal > 0.95 &&
        open.defeatedDeal > 0.95 &&
        open.cardGather < 0.02;
    if (!settled) return;

    final progress = context.read<AppRepo>().journeyProgress;
    if (!progress.diamondsEntered ||
        progress.diamondsJackIntroSeen ||
        progress.diamondsJackUnlocked) {
      return;
    }

    _startJackIntro();
  }

  void _startJackIntro() {
    if (_jackIntro.isActive) return;
    if (_jackIntro.isFinished) {
      // Conversation already done — go straight to unlock + challenge.
      _onJackIntroChallenge();
      return;
    }
    _jackIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _jackIntro.isActive || _jackIntro.isFinished) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _jackIntro.start();
      setState(() {});
    });
  }

  /// Resume Queen intro if Jack is beaten and the story convo hasn't played.
  void _maybeStartQueenIntro() {
    if (_queenIntroScheduled ||
        _queenIntro.isActive ||
        _queenIntro.isFinished) {
      return;
    }
    if (_coach.isActive ||
        _coach.isWaitingForLetter ||
        _jackIntro.isActive ||
        _guideExpanded ||
        _themeUnlockWorld != null ||
        _themeUnlockRewardWorld != null ||
        _pendingDiamondsInstructionReveal ||
        _instructionCeremonyPageId != null) {
      return;
    }
    final open = widget.openProgress;
    final settled = open.pileDeal > 0.95 &&
        open.defeatedDeal > 0.95 &&
        open.cardGather < 0.02;
    if (!settled) return;

    final repo = context.read<AppRepo>();
    final progress = repo.journeyProgress;
    if (progress.diamondsQueenIntroSeen) return;
    if (!progress.isDefeated(JourneyWorld.diamonds, JourneyRank.jack)) {
      return;
    }
    if (progress.isDefeated(JourneyWorld.diamonds, JourneyRank.queen)) {
      return;
    }
    // Home rewards / Jack win celebration own the first trigger.
    if (repo.hasPendingHomeRewardSequence) return;
    final pending = progress.pendingWinCelebration;
    if (pending != null &&
        pending.world == JourneyWorld.diamonds &&
        pending.rank == JourneyRank.jack) {
      return;
    }

    _startQueenIntro();
  }

  void _startQueenIntro() {
    if (_queenIntroScheduled ||
        _queenIntro.isActive ||
        _queenIntro.isFinished) {
      return;
    }
    _queenIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _queenIntro.start();
      setState(() {});
    });
  }

  void _startKingIntro() {
    if (_kingIntroScheduled || _kingIntro.isActive || _kingIntro.isFinished) {
      return;
    }
    _kingIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _kingIntro.start();
      setState(() {});
    });
  }

  void _startAceEscape() {
    if (_aceEscapeScheduled || _aceEscape.isActive || _aceEscape.isFinished) {
      return;
    }
    _aceEscapeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _aceEscape.start();
      setState(() {});
    });
  }

  void _startClubsJackIntro() {
    if (_clubsJackIntroScheduled ||
        _clubsJackIntro.isActive ||
        _clubsJackIntro.isFinished) {
      return;
    }
    _clubsJackIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _clubsJackIntro.start();
      setState(() {});
    });
  }

  void _startClubsCourt() {
    if (_clubsCourtScheduled ||
        _clubsCourt.isActive ||
        _clubsCourt.isFinished) {
      return;
    }
    _clubsCourtScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _clubsCourt.start();
      setState(() {});
    });
  }

  void _startClubsAceOffer() {
    if (_clubsAceOfferScheduled ||
        _clubsAceOffer.isActive ||
        _clubsAceOffer.isFinished) {
      return;
    }
    _clubsAceOfferScheduled = true;
    final won =
        context.read<AppRepo>().journeyProgress.clubsCourtMatchWon;
    _clubsAceOffer.configure(won: won);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _clubsAceOffer.start();
      setState(() {});
    });
  }

  void _startClubsHeartsSendoff() {
    if (_clubsHeartsSendoffScheduled ||
        _clubsHeartsSendoff.isActive ||
        _clubsHeartsSendoff.isFinished) {
      return;
    }
    _clubsHeartsSendoffScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _clubsHeartsSendoff.start();
      setState(() {});
    });
  }

  void _startHeartsJackIntro() {
    if (_heartsJackIntroScheduled ||
        _heartsJackIntro.isActive ||
        _heartsJackIntro.isFinished) {
      return;
    }
    _heartsJackIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _heartsJackIntro.start();
      setState(() {});
    });
  }

  void _startHeartsQueenEscort() {
    if (_heartsQueenEscortScheduled ||
        _heartsQueenEscort.isActive ||
        _heartsQueenEscort.isFinished) {
      return;
    }
    _heartsQueenEscortScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _heartsQueenEscort.start();
      setState(() {});
    });
  }

  void _startHeartsKingIntro() {
    if (_heartsKingIntroScheduled ||
        _heartsKingIntro.isActive ||
        _heartsKingIntro.isFinished) {
      return;
    }
    _heartsKingIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _heartsKingIntro.start();
      setState(() {});
    });
  }

  void _startHeartsAceOffer() {
    if (_heartsAceOfferScheduled ||
        _heartsAceOffer.isActive ||
        _heartsAceOffer.isFinished) {
      return;
    }
    _heartsAceOfferScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _heartsAceOffer.start();
      setState(() {});
    });
  }

  void _startSpadesJackIntro() {
    if (_spadesJackIntroScheduled ||
        _spadesJackIntro.isActive ||
        _spadesJackIntro.isFinished) {
      return;
    }
    _spadesJackIntroScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesJackIntro.start();
      setState(() {});
    });
  }

  void _startSpadesKingEscort() {
    if (_spadesKingEscortScheduled ||
        _spadesKingEscort.isActive ||
        _spadesKingEscort.isFinished) {
      return;
    }
    _spadesKingEscortScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesKingEscort.start();
      setState(() {});
    });
  }

  void _startSpadesCamp() {
    if (_spadesCampScheduled ||
        _spadesCamp.isActive ||
        _spadesCamp.isFinished) {
      return;
    }
    _spadesCampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesCamp.start();
      setState(() {});
    });
  }

  void _startSpadesRuinsApproach() {
    if (_spadesRuinsApproachScheduled ||
        _spadesRuinsApproach.isActive ||
        _spadesRuinsApproach.isFinished) {
      return;
    }
    _spadesRuinsApproachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesRuinsApproach.start();
      setState(() {});
    });
  }

  void _startSpadesRuinsClimax() {
    if (_spadesRuinsClimaxScheduled ||
        _spadesRuinsClimax.isActive ||
        _spadesRuinsClimax.isFinished) {
      return;
    }
    _spadesRuinsClimaxScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesRuinsClimax.start();
      setState(() {});
    });
  }

  void _startSpadesFinale() {
    if (_spadesFinaleScheduled ||
        _spadesFinale.isActive ||
        _spadesFinale.isFinished) {
      return;
    }
    _spadesFinaleScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _spadesFinale.start();
      setState(() {});
    });
  }

  Future<void> _onSpadesJackChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markSpadesJackIntroSeen();
    if (!mounted) return;

    final lockedJack = _snapshot
        .worldOf(JourneyWorld.spades)
        .cardOf(JourneyRank.jack);
    if (lockedJack == null) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _activeWorld = JourneyWorld.spades;
      _selectStartsFaceDown = true;
    });

    await _selectCard(
      lockedJack,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    if (!repo.journeyProgress.spadesJackUnlocked) {
      await repo.unlockSpadesJack();
      if (!mounted) return;
    }

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selectStartsFaceDown = false;
    });
    final unlocked =
        _snapshot.worldOf(JourneyWorld.spades).cardOf(JourneyRank.jack);
    if (unlocked == null) return;
    setState(() => _selected = unlocked);

    await _promptChallengeMatch(unlocked);
  }

  Future<void> _onSpadesKingEscortChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markSpadesKingEscortSeen();
    await repo.clearPendingSpadesKingEscort();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _activeWorld = JourneyWorld.spades;
    });

    final king =
        _snapshot.worldOf(JourneyWorld.spades).cardOf(JourneyRank.king);
    if (king == null) return;

    setState(() {
      _revealCard = king;
      _revealAnim.value = 0;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(
      king,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;
    await _promptChallengeMatch(king);
  }

  Future<void> _onSpadesCampComplete() async {
    final repo = context.read<AppRepo>();
    await repo.clearPendingSpadesRuins();
    if (!mounted) return;

    setState(() {
      _guideDisplayedUnlock = 13;
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
    });
    await _runInstructionUnlockCeremony(
      beforeUnlock: 13,
      afterUnlock: 14,
      showUnlockCtaAfter: true,
    );
    if (!mounted) return;
    setState(() => _pendingSpadesRuinsApproachContinue = true);
  }

  Future<void> _onSpadesRuinsApproachComplete() async {
    setState(() => _guideDisplayedUnlock = 14);
    await _runInstructionUnlockCeremony(
      beforeUnlock: 14,
      afterUnlock: 15,
      showUnlockCtaAfter: true,
    );
    if (!mounted) return;
    setState(() => _pendingSpadesRuinsClimaxContinue = true);
  }

  Future<void> _onSpadesRuinsClimaxComplete() async {
    final repo = context.read<AppRepo>();
    if (!mounted) return;

    final ace =
        _snapshot.worldOf(JourneyWorld.spades).cardOf(JourneyRank.ace);
    if (ace == null) return;

    setState(() {
      _revealCard = ace;
      _revealAnim.value = 0;
      _activeWorld = JourneyWorld.spades;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(
      ace,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    final claim = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        final j = JourneyL10n.of(ctx);
        return CupertinoAlertDialog(
          title: Text(j.cardTitle(ace)),
          content: Text(j.claimAce(JourneyWorld.spades)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(j.claim),
            ),
          ],
        );
      },
    );
    if (!mounted || claim != true) return;

    await repo.applyJourneyDefeat(
      JourneyWorld.spades,
      JourneyRank.ace,
      celebrate: true,
    );
    if (!mounted) return;
    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selected = null;
      _selectAnim.value = 0;
      _guideDisplayedUnlock = 15;
    });

    await _awaitHomeRewardsThen(() async {
      await repo.clearPendingWinCelebration();
      if (!mounted) return;
      setState(() {
        _pendingUnlockCard = null;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      _startSpadesFinale();
    });
  }

  Future<void> _onSpadesFinaleComplete() async {
    final repo = context.read<AppRepo>();
    await repo.markSpadesFinaleSeen();
    if (!mounted) return;
    setState(() {
      _guideDisplayedUnlock = 15;
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
    });
    await _runInstructionUnlockCeremony(
      beforeUnlock: 15,
      afterUnlock: 16,
      showUnlockCtaAfter: true,
    );
    if (!mounted) return;
    setState(() => _pendingSpadesFinaleLetterContinue = true);
  }

  Future<void> _maybeShowSpadesJackCampDenied() async {
    final repo = context.read<AppRepo>();
    if (!repo.journeyProgress.pendingSpadesJackCampDenied) return;
    final jack =
        _snapshot.worldOf(JourneyWorld.spades).cardOf(JourneyRank.jack) ??
            const JourneyCardDef(
              world: JourneyWorld.spades,
              rank: JourneyRank.jack,
              state: JourneyCardState.available,
              requiredLevel: 1,
              gameMode: GameMode.tresydos,
            );
    final action = await showJourneyLossTaunt(
      context,
      card: jack,
      message: _jl10n.spadesJackMustLose,
    );
    if (!mounted) return;
    await repo.clearPendingSpadesJackCampDenied();
    if (!mounted) return;

    if (action == JourneyLossAction.restartKingdom) {
      await repo.restartJourneyAtKingdom(JourneyWorld.spades);
      return;
    }

    // Replay (default): rematch the Jack.
    if (action == JourneyLossAction.replay || action == null) {
      setState(() {
        _activeWorld = JourneyWorld.spades;
        _selected = jack;
      });
      if (jack.isSelectable) {
        await _selectCard(jack, fromDefeated: false, skipEquip: true);
      }
      if (!mounted) return;
      await _startJourneyMatch(jack);
    }
  }

  Future<void> _onKingIntroChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markDiamondsKingIntroSeen();
    if (!mounted) return;

    final next = _pendingUnlockCard ??
        _snapshot.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.king);
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
    });

    final king = next == null
        ? null
        : (_snapshot.worldOf(next.world).cardOf(next.rank) ?? next);
    final unlocked = king ??
        _snapshot.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.king);
    if (unlocked == null) return;

    setState(() {
      _revealCard = unlocked;
      _revealAnim.value = 0;
      _activeWorld = JourneyWorld.diamonds;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(unlocked, fromDefeated: false, skipEquip: true);
    if (!mounted) return;
    await _promptChallengeMatch(unlocked);
  }

  /// After King win: claim Ace with "Yes, I won", then escape dialogue.
  Future<void> _offerDiamondsAceClaim() async {
    final repo = context.read<AppRepo>();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _activeWorld = JourneyWorld.diamonds;
    });

    final ace =
        _snapshot.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.ace);
    if (ace == null) return;

    setState(() {
      _revealCard = ace;
      _revealAnim.value = 0;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(ace, fromDefeated: false, skipEquip: true);
    if (!mounted) return;

    final claim = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        final j = JourneyL10n.of(ctx);
        return CupertinoAlertDialog(
          title: Text(j.cardTitle(ace)),
          content: Text(j.yesIWon),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(j.claim),
            ),
          ],
        );
      },
    );
    if (!mounted || claim != true) return;
    await _resolveDefeat(ace);
  }

  Future<void> _onAceEscapeComplete() async {
    final repo = context.read<AppRepo>();
    await repo.markDiamondsAceEscapeSeen();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;
    setState(() {
      _pendingUnlockCard = null;
      _guideDisplayedUnlock = 5;
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
    });
    await _runInstructionUnlockCeremony(
      beforeUnlock: 5,
      afterUnlock: 6,
      showUnlockCtaAfter: false,
    );
  }

  Future<void> _onClubsJackChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markClubsJackIntroSeen();
    if (!mounted) return;

    // Keep Jack hidden in data for the face-down → center flip, then unlock.
    final lockedJack = _snapshot
        .worldOf(JourneyWorld.clubs)
        .cardOf(JourneyRank.jack);
    if (lockedJack == null) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _activeWorld = JourneyWorld.clubs;
      _selectStartsFaceDown = true;
    });

    await _selectCard(
      lockedJack,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    if (!repo.journeyProgress.clubsJackUnlocked) {
      await repo.unlockClubsJack();
      if (!mounted) return;
    }

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selectStartsFaceDown = false;
    });
    final unlocked =
        _snapshot.worldOf(JourneyWorld.clubs).cardOf(JourneyRank.jack);
    if (unlocked == null) return;
    setState(() => _selected = unlocked);
    await _promptChallengeMatch(unlocked);
  }

  Future<void> _onClubsCourtChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markClubsCourtIntroSeen();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _activeWorld = JourneyWorld.clubs;
    });

    final king =
        _snapshot.worldOf(JourneyWorld.clubs).cardOf(JourneyRank.king);
    if (king == null) return;

    setState(() {
      _revealCard = king;
      _revealAnim.value = 0;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(
      king,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;
    await _promptChallengeMatch(king);
  }

  Future<void> _onClubsAceOfferComplete() async {
    final repo = context.read<AppRepo>();
    await repo.clearPendingClubsAceOffer();
    if (!mounted) return;

    final ace =
        _snapshot.worldOf(JourneyWorld.clubs).cardOf(JourneyRank.ace);
    if (ace == null) return;

    setState(() {
      _revealCard = ace;
      _revealAnim.value = 0;
      _activeWorld = JourneyWorld.clubs;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(
      ace,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    final claim = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        final j = JourneyL10n.of(ctx);
        return CupertinoAlertDialog(
          title: Text(j.cardTitle(ace)),
          content: Text(j.claimAce(JourneyWorld.clubs)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(j.claim),
            ),
          ],
        );
      },
    );
    if (!mounted || claim != true) return;

    await repo.applyJourneyDefeat(
      JourneyWorld.clubs,
      JourneyRank.ace,
      celebrate: true,
    );
    if (!mounted) return;
    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selected = null;
      _selectAnim.value = 0;
    });

    await _awaitHomeRewardsThen(() async {
      _startClubsHeartsSendoff();
    });
  }

  Future<void> _onClubsHeartsSendoffComplete() async {
    final repo = context.read<AppRepo>();
    await repo.markClubsAceGiftSeen();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;
    setState(() {
      _pendingUnlockCard = null;
      _guideDisplayedUnlock = 7;
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
    });
    await _runInstructionUnlockCeremony(
      beforeUnlock: 7,
      afterUnlock: 8,
      showUnlockCtaAfter: false,
    );
  }

  Future<void> _onHeartsJackChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markHeartsJackIntroSeen();
    if (!mounted) return;

    final lockedJack = _snapshot
        .worldOf(JourneyWorld.hearts)
        .cardOf(JourneyRank.jack);
    if (lockedJack == null) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _activeWorld = JourneyWorld.hearts;
      _selectStartsFaceDown = true;
    });

    await _selectCard(
      lockedJack,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    if (!repo.journeyProgress.heartsJackUnlocked) {
      await repo.unlockHeartsJack();
      if (!mounted) return;
    }

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selectStartsFaceDown = false;
    });
    final unlocked =
        _snapshot.worldOf(JourneyWorld.hearts).cardOf(JourneyRank.jack);
    if (unlocked == null) return;
    setState(() => _selected = unlocked);

    await _promptChallengeMatch(unlocked);
  }

  Future<void> _onHeartsQueenEscortChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markHeartsQueenEscortSeen();
    await repo.clearPendingHeartsQueenEscort();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _activeWorld = JourneyWorld.hearts;
    });

    final queen =
        _snapshot.worldOf(JourneyWorld.hearts).cardOf(JourneyRank.queen);
    if (queen == null) return;

    setState(() {
      _revealCard = queen;
      _revealAnim.value = 0;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(queen, fromDefeated: false, skipEquip: true);
    if (!mounted) return;
    await _promptChallengeMatch(queen);
  }

  Future<void> _onHeartsKingIntroChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markHeartsKingIntroSeen();
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _activeWorld = JourneyWorld.hearts;
    });

    final king =
        _snapshot.worldOf(JourneyWorld.hearts).cardOf(JourneyRank.king);
    if (king == null) return;

    setState(() {
      _revealCard = king;
      _revealAnim.value = 0;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(king, fromDefeated: false, skipEquip: true);
    if (!mounted) return;
    await _promptChallengeMatch(king);
  }

  Future<void> _onHeartsAceOfferComplete() async {
    final repo = context.read<AppRepo>();
    await repo.clearPendingHeartsAceOffer();
    if (!mounted) return;

    final ace =
        _snapshot.worldOf(JourneyWorld.hearts).cardOf(JourneyRank.ace);
    if (ace == null) return;

    setState(() {
      _revealCard = ace;
      _revealAnim.value = 0;
      _activeWorld = JourneyWorld.hearts;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(
      ace,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    final claim = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        final j = JourneyL10n.of(ctx);
        return CupertinoAlertDialog(
          title: Text(j.cardTitle(ace)),
          content: Text(j.claimAce(JourneyWorld.hearts)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(j.claim),
            ),
          ],
        );
      },
    );
    if (!mounted || claim != true) return;

    await repo.applyJourneyDefeat(
      JourneyWorld.hearts,
      JourneyRank.ace,
      celebrate: true,
    );
    if (!mounted) return;
    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selected = null;
      _selectAnim.value = 0;
    });

    await _awaitHomeRewardsThen(() async {
      await repo.markHeartsAceGiftSeen();
      await repo.clearPendingWinCelebration();
      if (!mounted) return;
      setState(() {
        _pendingUnlockCard = null;
        _guideDisplayedUnlock = 8;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      await _runInstructionUnlockCeremony(
        beforeUnlock: 8,
        afterUnlock: 12,
        showUnlockCtaAfter: false,
      );
    });
  }

  bool get _tutorialDoneForUnlocks =>
      _sessionTutorialDone || _coach.isFinished;

  int get _unlockedThrough => journeyUnlockedThrough(
        snapshot: _snapshot,
        tutorialDone: _tutorialDoneForUnlocks,
        diamondsEntered: context.read<AppRepo>().journeyProgress.diamondsEntered,
        diamondsAceEscapeSeen:
            context.read<AppRepo>().journeyProgress.diamondsAceEscapeSeen,
        clubsAceGiftSeen:
            context.read<AppRepo>().journeyProgress.clubsAceGiftSeen,
        heartsAceGiftSeen:
            context.read<AppRepo>().journeyProgress.heartsAceGiftSeen,
        spadesEntered: context
            .read<AppRepo>()
            .journeyProgress
            .hasEntered(JourneyWorld.spades),
        spadesFinaleSeen:
            context.read<AppRepo>().journeyProgress.spadesFinaleSeen,
      );

  bool get _needsFirstJackUnlock {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.diamondsEntered && !progress.diamondsJackUnlocked;
  }

  /// Page-2 Continue while Jack is still locked and his intro hasn't played.
  bool get _showJackContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.diamondsEntered &&
        !progress.diamondsJackUnlocked &&
        !progress.diamondsJackIntroSeen;
  }

  /// Page-3 Continue after Jack win before Queen conversation.
  bool get _showQueenContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.isDefeated(JourneyWorld.diamonds, JourneyRank.jack) &&
        !progress.isDefeated(JourneyWorld.diamonds, JourneyRank.queen) &&
        !progress.diamondsQueenIntroSeen &&
        !_queenIntro.isActive;
  }

  /// Page-4 Continue after Queen win before King conversation.
  bool get _showKingContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.isDefeated(JourneyWorld.diamonds, JourneyRank.queen) &&
        !progress.isDefeated(JourneyWorld.diamonds, JourneyRank.king) &&
        !progress.diamondsKingIntroSeen &&
        !_kingIntro.isActive;
  }

  /// Page-7 Continue after Clubs Jack win before court conversation.
  bool get _showClubsCourtContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.isDefeated(JourneyWorld.clubs, JourneyRank.jack) &&
        !progress.clubsCourtIntroSeen &&
        !_clubsCourt.isActive;
  }

  /// After Hearts Jack (win path): Continue → Queen escort.
  bool get _showHeartsQueenContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.isDefeated(JourneyWorld.hearts, JourneyRank.jack) &&
        !progress.heartsQueenEscortSeen &&
        !progress.pendingHeartsQueenEscort &&
        !_heartsQueenEscort.isActive;
  }

  /// After Hearts Queen win: Continue → King intro.
  bool get _showHeartsKingContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.isDefeated(JourneyWorld.hearts, JourneyRank.queen) &&
        !progress.isDefeated(JourneyWorld.hearts, JourneyRank.king) &&
        !progress.heartsKingIntroSeen &&
        !_heartsKingIntro.isActive;
  }

  /// Page-13 Continue after Spades enter → Jack intro.
  bool get _showSpadesJackContinueCta {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.hasEntered(JourneyWorld.spades) &&
        !progress.spadesJackIntroSeen &&
        !_spadesJackIntro.isActive;
  }

  /// Page-14 Continue after camp → ruins approach.
  bool get _showSpadesRuinsApproachContinueCta =>
      _pendingSpadesRuinsApproachContinue &&
      !_spadesRuinsApproach.isActive &&
      !_spadesRuinsApproach.isFinished;

  /// Page-15 Continue after ruins approach → climax.
  bool get _showSpadesRuinsClimaxContinueCta =>
      _pendingSpadesRuinsClimaxContinue &&
      !_spadesRuinsClimax.isActive &&
      !_spadesRuinsClimax.isFinished;

  /// Page-16 Continue after finale letter reveal.
  bool get _showSpadesFinaleLetterContinueCta =>
      _pendingSpadesFinaleLetterContinue;

  bool get _showStoryContinueCta =>
      _showJackContinueCta ||
      _showQueenContinueCta ||
      _showKingContinueCta ||
      _showClubsCourtContinueCta ||
      _showHeartsQueenContinueCta ||
      _showHeartsKingContinueCta ||
      _showSpadesJackContinueCta ||
      _showSpadesRuinsApproachContinueCta ||
      _showSpadesRuinsClimaxContinueCta ||
      _showSpadesFinaleLetterContinueCta;

  /// Unlock count shown in the guide (may lag during win celebration).
  int get _guideUnlockCount => _guideDisplayedUnlock ?? _unlockedThrough;

  void _openGuide({int? page}) {
    setState(() {
      _guideExpanded = true;
      _guideOpenPage = page ?? (_guideUnlockCount - 1).clamp(0, 100);
    });
  }

  /// Public entry from shell / rewards → Journey instructions.
  void openJourneyInstructions({int? page}) => _openGuide(page: page);

  void _closeGuide() {
    final resumePhaseB = _coach.isWaitingForLetter;
    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
    });
    if (resumePhaseB) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _coach.resumePhaseB();
        setState(() {});
      });
    } else {
      _maybeStartJackIntro();
    }
  }

  void _onCoachOpenLetter() {
    setState(() {
      _guideExpanded = true;
      _guideOpenPage = 0;
    });
  }

  void _onCoachCompleted() {
    setState(() {
      _sessionTutorialDone = true;
      _guideExpanded = true;
      // Re-open the letter / enter CTA after Phase B.
      _guideOpenPage = 0;
    });
  }

  Future<void> _onJackIntroChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markDiamondsJackIntroSeen();
    if (!mounted) return;

    // Keep Jack locked in data for the face-down → center flip, then unlock.
    final lockedJack = _snapshot
        .worldOf(JourneyWorld.diamonds)
        .cardOf(JourneyRank.jack);
    if (lockedJack == null) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideShowUnlockCta = false;
      _activeWorld = JourneyWorld.diamonds;
      _selectStartsFaceDown = true;
    });

    await _selectCard(
      lockedJack,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    if (!repo.journeyProgress.diamondsJackUnlocked) {
      await repo.unlockDiamondsJack();
      if (!mounted) return;
    }

    final unlocked = _snapshot
            .worldOf(JourneyWorld.diamonds)
            .cardOf(JourneyRank.jack) ??
        lockedJack;
    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selected = _snapshot
              .worldOf(JourneyWorld.diamonds)
              .cardOf(JourneyRank.jack) ??
          unlocked;
      _selectStartsFaceDown = false;
    });

    await _promptChallengeMatch(_selected ?? unlocked);
  }

  JourneyWorld get activeWorld => _activeWorld;

  /// Flip + return the selected challenger to its pile before leaving Journey.
  Future<void> dismissSelectedIfNeeded() async {
    if (_defeatedCarouselWorld != null) {
      await _closeDefeatedCarousel();
      // User chose to keep browsing — don't leave Journey mid-carousel.
      if (_defeatedCarouselWorld != null) return;
    }
    if (_selected == null && _selectAnim.value < 0.01) return;
    SoundService.instance.playLayered(GameSound.softCard);
    if (_selectAnim.value > 0.01) {
      await _selectAnim.reverse();
    }
    if (!mounted) return;
    setState(() => _selected = null);
  }

  /// Rebuild piles from persisted progress (after match return / XP unlock).
  Future<void> reloadFromProgress() async {
    if (!mounted) return;
    final repo = context.read<AppRepo>();
    await repo.maybeRestoreMistakenJackDefeat();
    if (!mounted) return;
    _lastLevel = repo.experienceProgress.level;
    final win = repo.journeyProgress.pendingWinCelebration;
    final praise = repo.journeyProgress.pendingReplayPraise;
    final clubsAceOffer = repo.journeyProgress.pendingClubsAceOffer;
    final heartsQueenEscort = repo.journeyProgress.pendingHeartsQueenEscort;
    final heartsAceOffer = repo.journeyProgress.pendingHeartsAceOffer;
    final spadesCampDenied = repo.journeyProgress.pendingSpadesJackCampDenied;
    final spadesKingEscort = repo.journeyProgress.pendingSpadesKingEscort;
    // Legacy saves may still have pendingSpadesKingRetry — fold into loss taunt.
    if (repo.journeyProgress.pendingSpadesKingRetry &&
        repo.journeyProgress.pendingLossTaunt == null) {
      repo.journeyProgress.pendingLossTaunt = const JourneyChallengeRef(
        world: JourneyWorld.spades,
        rank: JourneyRank.king,
      );
      await repo.clearPendingSpadesKingRetry();
      if (!mounted) return;
    }
    final loss = repo.journeyProgress.pendingLossTaunt;
    final spadesRuins = repo.journeyProgress.pendingSpadesRuins;
    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _selected = null;
      _selectAnim.value = 0;
      _defeatFlying = null;
      _revealCard = null;
      _defeatedCarouselWorld = null;
    });
    // Shell was recreated on leave — keep the challenger's kingdom / trail /
    // replay card in focus (theme stays equipped from before the match).
    final focus = win ??
        praise ??
        loss ??
        (clubsAceOffer
            ? const JourneyChallengeRef(
                world: JourneyWorld.clubs,
                rank: JourneyRank.king,
              )
            : null) ??
        (heartsQueenEscort
            ? const JourneyChallengeRef(
                world: JourneyWorld.hearts,
                rank: JourneyRank.jack,
              )
            : null) ??
        (heartsAceOffer
            ? const JourneyChallengeRef(
                world: JourneyWorld.hearts,
                rank: JourneyRank.king,
              )
            : null) ??
        (spadesCampDenied || spadesKingEscort
            ? const JourneyChallengeRef(
                world: JourneyWorld.spades,
                rank: JourneyRank.jack,
              )
            : null) ??
        (spadesRuins
            ? const JourneyChallengeRef(
                world: JourneyWorld.spades,
                rank: JourneyRank.king,
              )
            : null);
    if (focus != null) {
      _restorePostMatchChallenger(
        focus,
        openCarousel: win == null &&
            !clubsAceOffer &&
            !heartsQueenEscort &&
            !heartsAceOffer &&
            !spadesCampDenied &&
            !spadesKingEscort &&
            !spadesRuins,
      );
    }
    if (clubsAceOffer) {
      await _awaitHomeRewardsThen(() async {
        _startClubsAceOffer();
      });
      return;
    }
    if (heartsQueenEscort) {
      await _awaitHomeRewardsThen(() async {
        _startHeartsQueenEscort();
      });
      return;
    }
    if (heartsAceOffer) {
      await _awaitHomeRewardsThen(() async {
        _startHeartsAceOffer();
      });
      return;
    }
    if (spadesCampDenied) {
      await _awaitHomeRewardsThen(() async {
        await _maybeShowSpadesJackCampDenied();
      });
      return;
    }
    if (spadesKingEscort) {
      await _awaitHomeRewardsThen(() async {
        _startSpadesKingEscort();
      });
      return;
    }
    if (spadesRuins) {
      await _awaitHomeRewardsThen(() async {
        _startSpadesCamp();
      });
      return;
    }
    if (win != null) {
      // Win celebration owns kingdom focus until Unlock next challenger.
      await _awaitHomeRewardsThen(() => _beginWinCelebration(win));
      return;
    }
    if (praise != null) {
      await _awaitHomeRewardsThen(() async {
        await _maybeShowReplayPraise();
        await _offerReturnToProgressKingdom();
      });
      return;
    }
    if (loss != null) {
      await _awaitHomeRewardsThen(() async {
        await _maybeShowPendingLossTaunt();
        await _offerReturnToProgressKingdom();
      });
      return;
    }
    // Plain open / XP refresh — never prompt return-to-kingdom.
  }

  /// Rebind board focus to the challenger just played (trail + optional carousel).
  void _restorePostMatchChallenger(
    JourneyChallengeRef ref, {
    required bool openCarousel,
  }) {
    final progress = context.read<AppRepo>().journeyProgress;
    final card = _snapshot.worldOf(ref.world).cardOf(ref.rank);
    final defeated = card?.state == JourneyCardState.defeated ||
        progress.isDefeated(ref.world, ref.rank);
    setState(() {
      _activeWorld = ref.world;
      _selected = null;
      _selectAnim.value = 0;
      _selectFromOverride = null;
      if (openCarousel && defeated) {
        _defeatedCarouselWorld = ref.world;
        _defeatedCarouselRank = ref.rank;
        _selectedFromDefeated = true;
      } else {
        _defeatedCarouselWorld = null;
      }
    });
  }

  /// After a match off the progress kingdom, ask to return (or keep browsing).
  Future<void> _offerReturnToProgressKingdom() async {
    if (!mounted) return;
    final progressWorld = _progressKingdom();
    final repo = context.read<AppRepo>();
    final themeWorld = journeyWorldForTheme(repo.appTheme);
    // Still on Base (Sage) — kingdom entry is a separate confirm flow.
    if (themeWorld == null) return;
    if (_activeWorld == progressWorld && themeWorld == progressWorld) {
      return;
    }

    final go = await confirmReturnToProgressKingdom(
      context,
      world: progressWorld,
    );
    if (!mounted) return;
    if (!go) return;

    await repo.unlockAndEquipPack(progressWorld.themeId);
    if (!mounted) return;
    widget.onWorldThemeEquipped?.call(progressWorld);
    setState(() {
      _activeWorld = progressWorld;
      _defeatedCarouselWorld = null;
      _selected = null;
      _selectAnim.value = 0;
    });
  }

  Future<void> _awaitHomeRewardsThen(Future<void> Function() next) async {
    final repo = context.read<AppRepo>();
    if (!repo.hasPendingHomeRewardSequence) {
      await next();
      return;
    }

    void listener() {
      if (!mounted) {
        repo.removeListener(listener);
        return;
      }
      if (repo.hasPendingHomeRewardSequence) return;
      repo.removeListener(listener);
      next();
    }

    repo.addListener(listener);
  }

  Future<void> _beginWinCelebration(JourneyChallengeRef defeated) async {
    if (!mounted) return;
    final repo = context.read<AppRepo>();
    final level = repo.experienceProgress.level;
    final next = journeyNextAfterDefeat(
      progress: repo.journeyProgress,
      playerLevel: level,
      defeated: defeated,
    );
    // Instruction unlock is derived from defeats (already recorded).
    final fullSnap = hydrateJourneyBoard(
      progress: repo.journeyProgress,
      playerLevel: level,
      deferPendingWin: false,
    );
    final afterUnlock = journeyUnlockedThrough(
      snapshot: fullSnap,
      tutorialDone: _tutorialDoneForUnlocks,
      diamondsEntered: repo.journeyProgress.diamondsEntered,
      diamondsAceEscapeSeen: repo.journeyProgress.diamondsAceEscapeSeen,
      clubsAceGiftSeen: repo.journeyProgress.clubsAceGiftSeen,
      heartsAceGiftSeen: repo.journeyProgress.heartsAceGiftSeen,
      spadesEntered: repo.journeyProgress.hasEntered(JourneyWorld.spades),
      spadesFinaleSeen: repo.journeyProgress.spadesFinaleSeen,
    );
    final beforeUnlock = (afterUnlock - 1).clamp(1, afterUnlock);

    final aceEscapeStory = defeated.world == JourneyWorld.diamonds &&
        defeated.rank == JourneyRank.ace &&
        !repo.journeyProgress.diamondsAceEscapeSeen;

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _pendingUnlockCard = next;
      _selected = null;
      _selectAnim.value = 0;
      _revealCard = null;
      _activeWorld = defeated.world;
      _defeatedCarouselWorld = null;
    });

    // Ace claim rewards finished — escape conversation starts immediately.
    if (aceEscapeStory) {
      _startAceEscape();
      return;
    }

    await _runInstructionUnlockCeremony(
      beforeUnlock: beforeUnlock,
      afterUnlock: afterUnlock,
      showUnlockCtaAfter: true,
    );
  }

  Future<void> _onQueenIntroChallenge() async {
    final repo = context.read<AppRepo>();
    await repo.markDiamondsQueenIntroSeen();
    if (!mounted) return;

    final next = _pendingUnlockCard ??
        _snapshot.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.queen);
    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
    });

    final queen = next == null
        ? null
        : (_snapshot.worldOf(next.world).cardOf(next.rank) ?? next);
    final unlocked = queen ??
        _snapshot.worldOf(JourneyWorld.diamonds).cardOf(JourneyRank.queen);
    if (unlocked == null) return;

    setState(() {
      _revealCard = unlocked;
      _revealAnim.value = 0;
      _activeWorld = JourneyWorld.diamonds;
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(unlocked, fromDefeated: false, skipEquip: true);
    if (!mounted) return;
    await _promptChallengeMatch(unlocked);
  }

  Future<void> _onUnlockNextChallenger() async {
    final repo = context.read<AppRepo>();

    // Page-2 Continue: start Jack conversation (card stays locked until Challenge).
    if (_pendingUnlockCard == null && _showJackContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startJackIntro();
      return;
    }

    // Queen win → Continue on instructions → King conversation.
    if (_showKingContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startKingIntro();
      return;
    }

    // Jack win → Continue on instructions → Queen conversation.
    if (_showQueenContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startQueenIntro();
      return;
    }

    // Clubs Jack win → Continue → court conversation.
    if (_showClubsCourtContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startClubsCourt();
      return;
    }

    // Hearts Jack win → Continue → Queen escort.
    if (_showHeartsQueenContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startHeartsQueenEscort();
      return;
    }

    // Hearts Queen win → Continue → King intro.
    if (_showHeartsKingContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startHeartsKingIntro();
      return;
    }

    // Spades briefing → Continue → Jack intro.
    if (_showSpadesJackContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startSpadesJackIntro();
      return;
    }

    // Camp letter → Continue → ruins approach.
    if (_showSpadesRuinsApproachContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
        _pendingSpadesRuinsApproachContinue = false;
      });
      _startSpadesRuinsApproach();
      return;
    }

    // Ruins approach letter → Continue → climax.
    if (_showSpadesRuinsClimaxContinueCta) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
        _pendingSpadesRuinsClimaxContinue = false;
      });
      _startSpadesRuinsClimax();
      return;
    }

    // Finale letter → Continue (dismiss CTA; keep guide open to read).
    if (_showSpadesFinaleLetterContinueCta) {
      setState(() {
        _guideShowUnlockCta = false;
        _pendingSpadesFinaleLetterContinue = false;
      });
      return;
    }

    // First-time Diamonds Jack unlock without intro (already seen).
    if (_pendingUnlockCard == null && _needsFirstJackUnlock) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
        _activeWorld = JourneyWorld.diamonds;
        _selectStartsFaceDown = true;
      });
      final locked = _snapshot
          .worldOf(JourneyWorld.diamonds)
          .cardOf(JourneyRank.jack);
      if (locked != null) {
        await _selectCard(
          locked,
          fromDefeated: false,
          skipEquip: true,
          allowLocked: true,
        );
        if (!mounted) return;
      }
      await repo.unlockDiamondsJack();
      if (!mounted) return;
      setState(() {
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
        _selected = _snapshot
            .worldOf(JourneyWorld.diamonds)
            .cardOf(JourneyRank.jack);
        _selectStartsFaceDown = false;
      });
      return;
    }

    final next = _pendingUnlockCard;
    // Jack win → Queen: story conversation owns the reveal + challenge.
    if (next != null &&
        next.world == JourneyWorld.diamonds &&
        next.rank == JourneyRank.queen &&
        !repo.journeyProgress.diamondsQueenIntroSeen) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startQueenIntro();
      return;
    }
    // Queen win → King intro.
    if (next != null &&
        next.world == JourneyWorld.diamonds &&
        next.rank == JourneyRank.king &&
        !repo.journeyProgress.diamondsKingIntroSeen) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      _startKingIntro();
      return;
    }
    // King win → Ace claim story.
    if (next != null &&
        next.world == JourneyWorld.diamonds &&
        next.rank == JourneyRank.ace &&
        !repo.journeyProgress.diamondsAceEscapeSeen) {
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
      });
      await _offerDiamondsAceClaim();
      return;
    }

    if (next == null) {
      await repo.clearPendingWinCelebration();
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideDisplayedUnlock = null;
        _guideShowUnlockCta = false;
        _pendingUnlockCard = null;
      });
      return;
    }

    final locked = _snapshot.worldOf(next.world).cardOf(next.rank) ?? next;
    final equipped = await _equipWorld(next.world);
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _selectStartsFaceDown = true;
      if (equipped && next.world != _activeWorld) {
        _activeWorld = next.world;
      }
    });

    await _selectCard(
      locked,
      fromDefeated: false,
      skipEquip: true,
      allowLocked: true,
    );
    if (!mounted) return;

    await repo.clearPendingWinCelebration();
    if (!mounted) return;

    setState(() {
      _pendingUnlockCard = null;
      _worlds = _copyWorlds(
        hydrateJourneyBoard(
          progress: repo.journeyProgress,
          playerLevel: repo.experienceProgress.level,
          deferPendingWin: false,
        ),
      );
      _selected = _snapshot.worldOf(next.world).cardOf(next.rank) ?? locked;
      _selectStartsFaceDown = false;
    });
  }

  JourneyDisplaySnapshot get _snapshot =>
      JourneyDisplaySnapshot(worlds: _worlds);

  /// Challengers first, defeated last (enter fill order).
  List<JourneyDealSlot> get dealPlan => JourneyBoard.dealPlanFor(_snapshot);

  Future<void> equipActiveWorldTheme() async {
    await _equipWorld(_activeWorld);
  }

  /// Equips [world]'s theme after confirmation when the app theme would change.
  ///
  /// Returns false if the player chose to stay on the current theme.
  Future<bool> _equipWorld(JourneyWorld world) async {
    final repo = context.read<AppRepo>();
    final firstUnlock = !repo.ownsPack(world.themeId) ||
        !repo.journeyProgress.hasEntered(world);
    if (firstUnlock && !repo.canEnterKingdom(world)) {
      return false;
    }
    final currentWorld = journeyWorldForTheme(repo.appTheme);
    if (currentWorld != world) {
      final go = await confirmEnterKingdom(context, world: world);
      if (!go || !mounted) return false;
    }
    if (firstUnlock) {
      return _runThemeUnlockCeremony(world);
    }
    await repo.unlockAndEquipPack(world.themeId);
    if (!mounted) return false;
    widget.onWorldThemeEquipped?.call(world);
    return true;
  }

  Future<void> _enterKingdomFromGuide(JourneyWorld world) async {
    if (world == JourneyWorld.clubs) {
      await _enterClubsFromGuide();
      return;
    }
    if (world == JourneyWorld.hearts) {
      await _enterHeartsFromGuide();
      return;
    }
    if (world == JourneyWorld.spades) {
      await _enterSpadesFromGuide();
      return;
    }
    if (world != JourneyWorld.diamonds) {
      final ok = await _equipWorld(world);
      if (!ok || !mounted) return;
      setState(() => _activeWorld = world);
      return;
    }

    final repo = context.read<AppRepo>();
    final currentWorld = journeyWorldForTheme(repo.appTheme);
    if (currentWorld != JourneyWorld.diamonds) {
      final go = await confirmEnterKingdom(
        context,
        world: JourneyWorld.diamonds,
      );
      if (!go || !mounted) return;
    }
    if (!mounted) return;

    // Entering from the letter can skip Phase B — still mark the coach done.
    if (_coach.isWaitingForLetter ||
        _coach.phase == JourneyCoachPhase.phaseB ||
        !_sessionTutorialDone) {
      _coach.finish();
      await repo.completeJourneyTutorial();
      if (!mounted) return;
      setState(() => _sessionTutorialDone = true);
    }

    if (repo.journeyProgress.diamondsEntered &&
        repo.ownsPack(JourneyWorld.diamonds.themeId)) {
      await repo.enterDiamondsKingdom();
      if (!mounted) return;
      setState(() {
        _activeWorld = JourneyWorld.diamonds;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
        _guideExpanded = true;
        _guideOpenPage = 1;
        _guideShowUnlockCta = false;
      });
      return;
    }
    await _runThemeUnlockCeremony(JourneyWorld.diamonds);
  }

  Future<void> _enterClubsFromGuide() async {
    final repo = context.read<AppRepo>();
    if (!repo.canEnterKingdom(JourneyWorld.clubs)) return;
    final currentWorld = journeyWorldForTheme(repo.appTheme);
    if (currentWorld != JourneyWorld.clubs) {
      final go = await confirmEnterKingdom(
        context,
        world: JourneyWorld.clubs,
      );
      if (!go || !mounted) return;
    }
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
    });

    if (repo.journeyProgress.hasEntered(JourneyWorld.clubs) &&
        repo.ownsPack(JourneyWorld.clubs.themeId)) {
      await repo.enterClubsKingdom();
      if (!mounted) return;
      setState(() {
        _activeWorld = JourneyWorld.clubs;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      if (!repo.journeyProgress.clubsJackIntroSeen) {
        _startClubsJackIntro();
      }
      return;
    }

    await _runThemeUnlockCeremony(JourneyWorld.clubs);
  }

  Future<void> _enterHeartsFromGuide() async {
    final repo = context.read<AppRepo>();
    if (!repo.canEnterKingdom(JourneyWorld.hearts)) return;
    final currentWorld = journeyWorldForTheme(repo.appTheme);
    if (currentWorld != JourneyWorld.hearts) {
      final go = await confirmEnterKingdom(
        context,
        world: JourneyWorld.hearts,
      );
      if (!go || !mounted) return;
    }
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
    });

    if (repo.journeyProgress.hasEntered(JourneyWorld.hearts) &&
        repo.ownsPack(JourneyWorld.hearts.themeId)) {
      await repo.enterHeartsKingdom();
      if (!mounted) return;
      setState(() {
        _activeWorld = JourneyWorld.hearts;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      if (!repo.journeyProgress.heartsJackIntroSeen) {
        _startHeartsJackIntro();
      }
      return;
    }

    await _runThemeUnlockCeremony(JourneyWorld.hearts);
  }

  Future<void> _enterSpadesFromGuide() async {
    final repo = context.read<AppRepo>();
    if (!repo.canEnterKingdom(JourneyWorld.spades)) return;
    final currentWorld = journeyWorldForTheme(repo.appTheme);
    if (currentWorld != JourneyWorld.spades) {
      final go = await confirmEnterKingdom(
        context,
        world: JourneyWorld.spades,
      );
      if (!go || !mounted) return;
    }
    if (!mounted) return;

    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
    });

    if (repo.journeyProgress.hasEntered(JourneyWorld.spades) &&
        repo.ownsPack(JourneyWorld.spades.themeId)) {
      await repo.enterSpadesKingdom();
      if (!mounted) return;
      setState(() {
        _activeWorld = JourneyWorld.spades;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
      });
      if (!repo.journeyProgress.spadesJackIntroSeen) {
        await _runInstructionUnlockCeremony(
          beforeUnlock: 12,
          afterUnlock: 13,
          showUnlockCtaAfter: true,
        );
      }
      return;
    }

    await _runThemeUnlockCeremony(JourneyWorld.spades);
  }

  Future<void> _resolveDefeat(JourneyCardDef card) async {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.heavyImpact();
    setState(() {
      _defeatFlying = card;
      _defeatFlyTo = null;
      _selected = null;
      _selectFromOverride = null;
    });
    _selectAnim.value = 0;
    // Persist first so celebration hydrate sees the defeat; keep next locked.
    await context.read<AppRepo>().applyJourneyDefeat(
      card.world,
      card.rank,
      celebrate: true,
    );
    if (!mounted) return;
    setState(() {
      _worlds = _copyWorlds(context.read<AppRepo>().journeyBoardForLevel());
      _revealCard = null;
    });
    // Let the trail token settle on the new step before Ace flight.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (card.rank == JourneyRank.ace) {
      final tokenBox =
          _trailTokenKey.currentContext?.findRenderObject() as RenderBox?;
      final boardBox = context.findRenderObject() as RenderBox?;
      Offset? target;
      if (tokenBox != null && boardBox != null && tokenBox.hasSize) {
        final global = tokenBox.localToGlobal(
          tokenBox.size.center(Offset.zero),
        );
        target = boardBox.globalToLocal(global);
      }
      setState(() {
        _defeatFlyTo = target ??
            Offset(
              boardBox?.size.width != null
                  ? boardBox!.size.width *
                      context
                          .read<AppRepo>()
                          .journeyProgress
                          .trailProgress
                          .clamp(0.08, 0.92)
                  : 0,
              boardBox != null ? boardBox.size.height * 0.26 : 0,
            );
        _defeatFlySize = tokenBox?.size.shortestSide != null
            ? tokenBox!.size.shortestSide * 1.15
            : 34;
      });
    }
    await _defeatFlyAnim.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _defeatFlying = null;
      _defeatFlyTo = null;
      _defeatFlySize = 0;
    });
    _defeatFlyAnim.value = 0;
    await _awaitHomeRewardsThen(
      () => _beginWinCelebration(
        JourneyChallengeRef(world: card.world, rank: card.rank),
      ),
    );
  }

  Future<void> _onChallenge() async {
    final card = _selected;
    if (card == null) return;
    await _promptChallengeMatch(card);
  }

  /// Play / Test… / Cancel for a fresh challenge or defeated replay.
  Future<void> _promptChallengeMatch(JourneyCardDef card) async {
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    final isAce = card.rank == JourneyRank.ace;
    if (isAce) {
      final claim = await showCupertinoDialog<String>(
        context: context,
        builder: (ctx) {
          final j = JourneyL10n.of(ctx);
          final l10n = AppLocalizations.of(ctx);
          return CupertinoAlertDialog(
            title: Text(j.claimTitle(card)),
            content: Text(j.claimAceCollectHint),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop('defeat'),
                child: Text(j.claim),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          );
        },
      );
      if (!mounted || claim != 'defeat') return;
      await _resolveDefeat(card);
      return;
    }

    final alreadyDefeated = context.read<AppRepo>().journeyProgress.isDefeated(
      card.world,
      card.rank,
    );
    final clubsCourt = _isClubsCourtChallenge(card);
    final outcome = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) {
        final j = JourneyL10n.of(ctx);
        final l10n = AppLocalizations.of(ctx);
        return CupertinoAlertDialog(
          title: Text(
            alreadyDefeated
                ? j.replayTitle(card)
                : j.challengeTitle(card, clubsCourt: clubsCourt),
          ),
          content: Text(
            alreadyDefeated
                ? j.replayBody(card)
                : j.challengeBody(card, clubsCourt: clubsCourt),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop('play'),
              child: Text(j.play),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop('test'),
              child: Text(j.t('Test…', 'Probar…')),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );

    if (!mounted || outcome == null) return;

    if (outcome == 'test') {
      final testOutcome = await showCupertinoDialog<String>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Test outcome'),
          content: const Text(
            'Skip the match and force a result (dev only).',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop('defeat'),
              child: const Text('Defeat'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop('lose'),
              child: const Text('Lose'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (!mounted || testOutcome == null) return;
      if (testOutcome == 'defeat') {
        _pinTrailToCard(card);
        if (alreadyDefeated) {
          await _resolveReplayWin(card);
        } else if (_usesStoryChallengeFlags(card)) {
          await _simulateJourneyChallengeResult(card, won: true);
        } else {
          await _resolveDefeat(card);
        }
        return;
      }
      if (testOutcome == 'lose') {
        _pinTrailToCard(card);
        if (_usesStoryChallengeFlags(card)) {
          await _simulateJourneyChallengeResult(card, won: false);
          return;
        }
        final action = await showJourneyLossTaunt(context, card: card);
        if (!mounted) return;
        if (action == JourneyLossAction.restartKingdom) {
          await context.read<AppRepo>().restartJourneyAtKingdom(card.world);
          return;
        }
        if (action == JourneyLossAction.replay) {
          await _startJourneyMatch(card);
        }
      }
      return;
    }

    if (outcome == 'play') {
      _pinTrailToCard(card);
      await _startJourneyMatch(card);
    }
  }

  bool _isClubsCourtChallenge(JourneyCardDef card) {
    final progress = context.read<AppRepo>().journeyProgress;
    return card.world == JourneyWorld.clubs &&
        card.rank == JourneyRank.king &&
        progress.clubsCourtIntroSeen &&
        !progress.isDefeated(JourneyWorld.clubs, JourneyRank.ace);
  }

  bool _usesStoryChallengeFlags(JourneyCardDef card) {
    if (_isClubsCourtChallenge(card)) return true;
    if (card.world == JourneyWorld.hearts && card.rank == JourneyRank.king) {
      return true;
    }
    if (card.world == JourneyWorld.spades &&
        (card.rank == JourneyRank.jack || card.rank == JourneyRank.king)) {
      return true;
    }
    return false;
  }

  Future<void> _simulateJourneyChallengeResult(
    JourneyCardDef card, {
    required bool won,
  }) async {
    final repo = context.read<AppRepo>();
    final progress = repo.journeyProgress;
    final clubsCourt = card.world == JourneyWorld.clubs &&
        card.rank == JourneyRank.king &&
        progress.clubsCourtIntroSeen &&
        !progress.isDefeated(JourneyWorld.clubs, JourneyRank.ace);
    final spadesJack =
        card.world == JourneyWorld.spades && card.rank == JourneyRank.jack;
    final spadesKing =
        card.world == JourneyWorld.spades && card.rank == JourneyRank.king;
    final heartsKing =
        card.world == JourneyWorld.hearts && card.rank == JourneyRank.king;

    await repo.beginJourneyChallenge(
      world: card.world,
      rank: card.rank,
      gameId: 'test-sim',
      ignoreOutcome: clubsCourt || heartsKing,
      escortOnLoss: spadesJack,
      denyCampOnWin: spadesJack,
      retryOnLoss: spadesKing,
    );
    await repo.noteJourneyChallengeResult(won: won, gameId: 'test-sim');
    repo.takeOpenJourneyRequest();
    repo.takeShellTabRequest();
    if (!mounted) return;
    await reloadFromProgress();
  }

  /// Keep the progress-trail token on [card] after leaving defeated browse.
  void _pinTrailToCard(JourneyCardDef card) {
    setState(() {
      _defeatedCarouselWorld = null;
      _activeWorld = card.world;
      _selected = card;
      _selectedFromDefeated = true;
      _selectAnim.value = 0;
      _selectFromOverride = null;
    });
  }

  /// Dev / test path: simulate winning a rematch (praise only, no unlocks).
  Future<void> _resolveReplayWin(JourneyCardDef card) async {
    final repo = context.read<AppRepo>();
    await repo.beginJourneyChallenge(
      world: card.world,
      rank: card.rank,
      gameId: 'test-replay',
    );
    await repo.noteJourneyChallengeResult(won: true, gameId: 'test-replay');
    // In-place test — cancel home-return flags meant for leaving a real match.
    repo.takeOpenJourneyRequest();
    repo.takeShellTabRequest();
    if (!mounted) return;
    _restorePostMatchChallenger(
      JourneyChallengeRef(world: card.world, rank: card.rank),
      openCarousel: true,
    );
    await _maybeShowReplayPraise();
    if (!mounted) return;
    await _offerReturnToProgressKingdom();
  }

  /// Launch the Journey match for [card] (Challenge / Replay).
  Future<void> _startJourneyMatch(JourneyCardDef card) async {
    final repo = context.read<AppRepo>();
    final vm = context.read<GamesViewModel>();
    final progress = repo.journeyProgress;

    // Clubs court table (King + Queen + Jack) after the court intro.
    final clubsCourt = card.world == JourneyWorld.clubs &&
        card.rank == JourneyRank.king &&
        progress.clubsCourtIntroSeen &&
        !progress.isDefeated(JourneyWorld.clubs, JourneyRank.ace);
    if (clubsCourt) {
      await gameEnter(
        context,
        vm,
        GameMode.rummy,
        true,
        playerCount: 4,
        botOverrides: [
          LocalBotProfile(
            name: 'King',
            avatarId: journeyAvatarId(JourneyWorld.clubs, JourneyRank.king),
          ),
          LocalBotProfile(
            name: 'Queen',
            avatarId: journeyAvatarId(JourneyWorld.clubs, JourneyRank.queen),
          ),
          LocalBotProfile(
            name: 'Jack',
            avatarId: journeyAvatarId(JourneyWorld.clubs, JourneyRank.jack),
          ),
        ],
        onCreated: (gid) => repo.beginJourneyChallenge(
          world: JourneyWorld.clubs,
          rank: JourneyRank.king,
          gameId: gid,
          ignoreOutcome: true,
        ),
      );
      return;
    }

    final mode = card.gameMode;
    if (mode == null) return;
    final spadesJack =
        card.world == JourneyWorld.spades && card.rank == JourneyRank.jack;
    final spadesKing =
        card.world == JourneyWorld.spades && card.rank == JourneyRank.king;
    final heartsKing =
        card.world == JourneyWorld.hearts && card.rank == JourneyRank.king;
    await gameEnter(
      context,
      vm,
      mode,
      true,
      botOverride: LocalBotProfile(
        name: card.rank.label,
        avatarId: journeyAvatarId(card.world, card.rank),
      ),
      onCreated: (gid) => repo.beginJourneyChallenge(
        world: card.world,
        rank: card.rank,
        gameId: gid,
        escortOnLoss: spadesJack,
        denyCampOnWin: spadesJack,
        retryOnLoss: spadesKing,
        ignoreOutcome: heartsKing,
      ),
    );
  }

  Future<void> _playRevealIfNeeded() async {
    final card = _revealCard;
    if (card == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();
    var boomed = false;
    void onTick() {
      if (boomed || !mounted) return;
      if (JourneyThemeUnlockTimeline(_revealAnim.value).pastBoom) {
        boomed = true;
        AppHaptics.heavyImpact();
        SoundService.instance.playLayered(GameSound.softCard);
      }
    }

    _revealAnim.addListener(onTick);
    try {
      await _revealAnim.forward(from: 0);
    } finally {
      _revealAnim.removeListener(onTick);
    }
    if (!mounted) return;
    setState(() => _revealCard = null);
    _revealAnim.value = 1;
  }

  Future<void> _selectCard(
    JourneyCardDef card, {
    required bool fromDefeated,
    Offset? fromOverride,
    double startProgress = 0,
    bool skipEquip = false,
    bool allowLocked = false,
  }) async {
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || (!card.isSelectable && !allowLocked)) {
      SoundService.instance.playLayered(GameSound.softCard);
      AppHaptics.selectionClick();
      return;
    }

    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    if (_defeatedCarouselWorld != null) {
      setState(() => _defeatedCarouselWorld = null);
    }

    if (_selected?.world == card.world && _selected?.rank == card.rank) {
      await _selectAnim.reverse();
      if (!mounted) return;
      setState(() {
        _selected = null;
        _selectFromOverride = null;
      });
      return;
    }

    if (_selected != null && _selectAnim.value > 0.05) {
      await _selectAnim.reverse();
      if (!mounted) return;
      setState(() {
        _selected = null;
        _selectFromOverride = null;
      });
    }

    if (!skipEquip) {
      final ok = await _equipWorld(card.world);
      if (!ok || !mounted) return;
    }

    setState(() {
      _activeWorld = card.world;
      _selected = card;
      _selectedFromDefeated = fromDefeated;
      _selectFromOverride = fromOverride;
      _dragging = null;
      _dragPos = null;
    });
    await _selectAnim.forward(from: startProgress.clamp(0.0, 0.85));
  }

  Future<void> _openDefeatedCarousel(JourneyWorld world) async {
    final def = _snapshot.worldOf(world);
    if (!def.unlocked || def.defeatedRoyals.isEmpty) {
      AppHaptics.selectionClick();
      return;
    }
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.mediumImpact();

    if (_selected != null) {
      if (_selectAnim.value > 0.05) await _selectAnim.reverse();
      if (!mounted) return;
    }

    final ok = await _equipWorld(world);
    if (!ok || !mounted) return;

    setState(() {
      _selected = null;
      _selectFromOverride = null;
      _selectAnim.value = 0;
      _activeWorld = world;
      _defeatedCarouselWorld = world;
      _defeatedCarouselRank = JourneyDefeatedCarousel.initialFocus(def);
    });
  }

  /// Kingdom where the player's frontier challenger currently sits.
  JourneyWorld _progressKingdom() {
    for (final world in JourneyWorld.values) {
      final next = _snapshot.worldOf(world).nextSelectable;
      if (next != null && next.state == JourneyCardState.available) {
        return world;
      }
    }
    for (final world in JourneyWorld.values.reversed) {
      if (_snapshot.worldOf(world).unlocked) return world;
    }
    return JourneyWorld.diamonds;
  }

  /// Close defeated browse and return to the progress kingdom (with confirm).
  Future<void> _closeDefeatedCarousel() async {
    if (_defeatedCarouselWorld == null) return;
    final browsing = _defeatedCarouselWorld!;
    final progressWorld = _progressKingdom();
    final repo = context.read<AppRepo>();
    final themeWorld = journeyWorldForTheme(repo.appTheme);
    final needsReturn = themeWorld != null &&
        (browsing != progressWorld || themeWorld != progressWorld);

    if (needsReturn) {
      final go = await confirmReturnToProgressKingdom(
        context,
        world: progressWorld,
      );
      if (!go || !mounted) return;
      await repo.unlockAndEquipPack(progressWorld.themeId);
      if (!mounted) return;
      widget.onWorldThemeEquipped?.call(progressWorld);
    }

    if (!mounted) return;
    setState(() {
      _defeatedCarouselWorld = null;
      _activeWorld = progressWorld;
    });
  }

  /// Trail token milestone from focus, else current frontier challenger.
  int _trailTokenStep(JourneyProgress progress) {
    if (_defeatedCarouselWorld != null) {
      return journeyTrailStepIndex(
        _defeatedCarouselWorld!,
        _defeatedCarouselRank,
      );
    }
    if (_selected != null) {
      return journeyTrailStepIndex(_selected!.world, _selected!.rank);
    }
    for (final world in JourneyWorld.values) {
      final next = _snapshot.worldOf(world).nextSelectable;
      if (next != null && next.state == JourneyCardState.available) {
        return journeyTrailStepIndex(next.world, next.rank);
      }
    }
    final done = progress.trailStepsCompleted;
    if (done <= 0) return 0;
    return (done - 1).clamp(0, journeyTrailStepCount - 1);
  }

  Future<void> _onWorldTap(JourneyWorld world) async {
    final def = _snapshot.worldOf(world);
    SoundService.instance.playLayered(GameSound.softCard);
    if (!def.unlocked) {
      AppHaptics.selectionClick();
      return;
    }
    AppHaptics.lightImpact();
    final ok = await _equipWorld(world);
    if (!ok || !mounted) return;
    setState(() {
      _activeWorld = world;
      _defeatedCarouselWorld = null;
      if (_selected != null && _selected!.world != world) {
        _selected = null;
        _selectAnim.value = 0;
        _selectFromOverride = null;
      }
    });
  }

  Future<void> _onTopCardTap(JourneyCardDef card) =>
      _selectCard(card, fromDefeated: false);

  Future<void> _onDefeatedStackTap(JourneyWorld world) =>
      _openDefeatedCarousel(world);

  void _onCardDragStart(
    JourneyCardDef card, {
    required bool fromDefeated,
    required Offset localPos,
  }) {
    if (_selectAnim.isAnimating || _defeatFlying != null) return;
    if (_dragging != null) return;
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || !card.isSelectable) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.selectionClick();
    setState(() {
      _dragging = card;
      _draggingFromDefeated = fromDefeated;
      _dragPos = localPos;
      if (_selected?.world == card.world && _selected?.rank == card.rank) {
        _selected = null;
        _selectAnim.value = 0;
        _selectFromOverride = null;
      }
    });
  }

  void _onCardDragUpdate(Offset localPos) {
    if (_dragging == null) return;
    setState(() => _dragPos = localPos);
  }

  void _cancelDrag() {
    if (_dragging == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    setState(() {
      _dragging = null;
      _dragPos = null;
    });
  }

  Future<void> _onCardDragEnd({
    required Offset centerTarget,
    required double boardHeight,
    required double boardWidth,
  }) async {
    final card = _dragging;
    final pos = _dragPos;
    final fromDefeated = _draggingFromDefeated;
    if (card == null || pos == null) return;

    // Generous center-stage drop zone (not a tiny point).
    final dropRadius = math.max(150.0, boardWidth * 0.38);
    final inCenterBand =
        pos.dy > boardHeight * 0.22 && pos.dy < boardHeight * 0.78;
    final dist = (pos - centerTarget).distance;
    final accepted = inCenterBand && dist < dropRadius;

    if (accepted) {
      final start = (1.0 - (dist / dropRadius).clamp(0.0, 1.0)) * 0.5;
      setState(() {
        _dragging = null;
        _dragPos = null;
      });
      await _selectCard(
        card,
        fromDefeated: fromDefeated,
        fromOverride: pos,
        startProgress: start,
      );
      return;
    }

    _cancelDrag();
  }

  Future<void> _onDismissSelected() async {
    if (_selected == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    await _selectAnim.reverse();
    if (!mounted) return;
    setState(() {
      _selected = null;
      _selectFromOverride = null;
    });
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    _maybeStartCoach();
    _maybeStartJackIntro();
    _maybeStartQueenIntro();

    final worldDef = _snapshot.worldOf(_activeWorld);
    final hasAvailable = worldDef.nextSelectable != null;
    final open = widget.openProgress;
    final selected = _selected == null
        ? null
        : _snapshot.worldOf(_selected!.world).cards.firstWhere(
              (c) => c.rank == _selected!.rank,
              orElse: () => _selected!,
            );

    final centerReveal = journeySlotExpand(open.sectionExpand, 1, count: 3);
    final plan = dealPlan;
    final boardInteractive = !_coach.isActive &&
        !_jackIntro.isActive &&
        !_queenIntro.isActive &&
        !_kingIntro.isActive &&
        !_aceEscape.isActive &&
        !_clubsJackIntro.isActive &&
        !_clubsCourt.isActive &&
        !_clubsAceOffer.isActive &&
        !_clubsHeartsSendoff.isActive &&
        !_heartsJackIntro.isActive &&
        !_heartsQueenEscort.isActive &&
        !_heartsKingIntro.isActive &&
        !_heartsAceOffer.isActive &&
        !_spadesJackIntro.isActive &&
        !_spadesKingEscort.isActive &&
        !_spadesCamp.isActive &&
        !_spadesRuinsApproach.isActive &&
        !_spadesRuinsClimax.isActive &&
        !_spadesFinale.isActive &&
        !_guideExpanded &&
        _themeUnlockWorld == null;

    // Only hide the centered selection from piles — keep the dragging card in
    // the pile tree (ghosted) so the pan GestureDetector stays alive.
    final hideChallenger =
        !_selectedFromDefeated ? selected : null;
                // Only hide non-Ace flyers from defeated piles (Aces → trail).
    final hideDefeated = (_defeatFlying != null &&
            _defeatFlying!.rank != JourneyRank.ace)
        ? _defeatFlying
        : (_selectedFromDefeated ? selected : null);
    final ghostChallenger =
        !_draggingFromDefeated ? _dragging : null;
    final ghostDefeated =
        _draggingFromDefeated ? _dragging : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = Size(constraints.maxWidth, constraints.maxHeight);
        final w = stage.width;
        final h = stage.height;
        final pileCardSize = JourneyTableLayout.pileCardSize(w);
        final pileTargets = JourneyTableLayout.pileTargets(stage);
        final defeatedTargets = JourneyTableLayout.defeatedTargets(stage);
        final centerTarget = Offset(w * 0.5, h * 0.48);
        final centerSize = (w * 0.52).clamp(150.0, 280.0);

        final interactive = boardInteractive &&
            open.pileDeal > 0.95 &&
            open.defeatedDeal > 0.95 &&
            open.cardGather < 0.02 &&
            _defeatFlying == null;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _defeatFlyAnim,
            _selectAnim,
            _revealAnim,
            _themeUnlockAnim,
            _instructionUnlockAnim,
            _coach,
          ]),
          builder: (context, _) {
            final selectProgress = _selectAnim.value;
            final revealProgress = _revealCard == null
                ? 1.0
                : _revealAnim.value;
            final homeFrom = selected == null
                ? Offset.zero
                : (_selectFromOverride ??
                    (_selectedFromDefeated
                        ? defeatedTargets[
                            JourneyWorld.values.indexOf(selected.world)]
                        : pileTargets[
                            JourneyWorld.values.indexOf(selected.world)]));

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 20,
                        child: JourneyCoachPulse(
                          controller: _coach,
                          targetKey: _pilesKey,
                          child: KeyedSubtree(
                            key: _pilesKey,
                            child: JourneyWorldPiles(
                              snapshot: _snapshot,
                              dealPlan: plan,
                              activeWorld: _activeWorld,
                              selectedCard: hideChallenger,
                              ghostCard: ghostChallenger,
                              revealCard: _revealCard,
                              revealProgress: revealProgress,
                              sectionExpand: open.sectionExpand,
                              pileDeal:
                                  open.cardGather > 0.02 ? 0 : open.pileDeal,
                              pileKeys: _pileKeys,
                              ceremonyWorld: _themeUnlockWorld,
                              ceremonyT: _themeUnlockWorld == null
                                  ? null
                                  : _themeUnlockAnim.value,
                              ceremonyForceSealed: _themeUnlockForceSealed,
                              onWorldTap: interactive ? _onWorldTap : null,
                              onTopCardTap:
                                  interactive ? _onTopCardTap : null,
                              onTopCardPanStart: interactive
                                  ? (card, details) => _onCardDragStart(
                                        card,
                                        fromDefeated: false,
                                        localPos: _toLocal(
                                          details.globalPosition,
                                        ),
                                      )
                                  : null,
                              onTopCardPanUpdate: interactive
                                  ? (details) => _onCardDragUpdate(
                                        _toLocal(details.globalPosition),
                                      )
                                  : null,
                              onTopCardPanEnd: interactive
                                  ? (_) => _onCardDragEnd(
                                        centerTarget: centerTarget,
                                        boardHeight: h,
                                        boardWidth: w,
                                      )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      JourneyCoachPulse(
                        controller: _coach,
                        extraController: _jackIntro,
                        targetKey: _trailKey,
                        child: KeyedSubtree(
                          key: _trailKey,
                          child: AnimatedBuilder(
                            animation: _trailTokenEat,
                            builder: (context, _) {
                              return JourneyProgressTrail(
                                progress: context
                                    .watch<AppRepo>()
                                    .journeyProgress,
                                tokenStepIndex: _trailTokenStep(
                                  context.watch<AppRepo>().journeyProgress,
                                ),
                                activeWorld: _activeWorld,
                                tokenKey: _trailTokenKey,
                                tokenScale:
                                    journeyEatPulseScale(_trailTokenEat.value),
                                onAvatarTap: () {
                                  openJourneyTrophies();
                                },
                                height: 52,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 48,
                        child: Opacity(
                          opacity: centerReveal,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * centerReveal,
                            child: JourneyCoachPulse(
                              controller: _coach,
                              targetKey: _centerKey,
                              child: KeyedSubtree(
                                key: _centerKey,
                                child: JourneyActiveStage(
                                  hasAvailableChallenger: hasAvailable,
                                  visible: selected == null &&
                                      _defeatedCarouselWorld == null &&
                                      selectProgress < 0.05 &&
                                      _defeatFlying == null &&
                                      _dragging == null &&
                                      !_guideExpanded,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        flex: 18,
                        child: JourneyCoachPulse(
                          controller: _coach,
                          targetKey: _defeatedKey,
                          child: KeyedSubtree(
                            key: _defeatedKey,
                            child: JourneyDefeatedRow(
                              snapshot: _snapshot,
                              dealPlan: plan,
                              sectionExpand: open.sectionExpand,
                              defeatedDeal: open.cardGather > 0.02
                                  ? 0
                                  : open.defeatedDeal,
                              hidingCard: hideDefeated,
                              ghostCard: ghostDefeated,
                              onDefeatedStackTap: interactive
                                  ? _onDefeatedStackTap
                                  : null,
                              onDefeatedPanStart: interactive
                                  ? (card, details) => _onCardDragStart(
                                        card,
                                        fromDefeated: true,
                                        localPos: _toLocal(
                                          details.globalPosition,
                                        ),
                                      )
                                  : null,
                              onDefeatedPanUpdate: interactive
                                  ? (details) => _onCardDragUpdate(
                                        _toLocal(details.globalPosition),
                                      )
                                  : null,
                              onDefeatedPanEnd: interactive
                                  ? (_) => _onCardDragEnd(
                                        centerTarget: centerTarget,
                                        boardHeight: h,
                                        boardWidth: w,
                                      )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Left instruction deck (collapsed) + expand overlay.
                if (centerReveal > 0.5) ...[
                  Positioned(
                    left: 0,
                    top: h * 0.22,
                    bottom: h * 0.28,
                    width: 72,
                    child: IgnorePointer(
                      ignoring: _coach.isActive ||
                          _jackIntro.isActive ||
                          _queenIntro.isActive ||
                          _kingIntro.isActive ||
                          _aceEscape.isActive ||
                          _clubsJackIntro.isActive ||
                          _clubsCourt.isActive ||
                          _clubsAceOffer.isActive ||
                          _clubsHeartsSendoff.isActive ||
                          _heartsJackIntro.isActive ||
                          _heartsQueenEscort.isActive ||
                          _heartsKingIntro.isActive ||
                          _heartsAceOffer.isActive ||
                          _spadesJackIntro.isActive ||
                          _spadesKingEscort.isActive ||
                          _spadesCamp.isActive ||
                          _spadesRuinsApproach.isActive ||
                          _spadesRuinsClimax.isActive ||
                          _spadesFinale.isActive ||
                          _guideExpanded,
                      child: Opacity(
                        opacity: centerReveal,
                        child: JourneyCoachPulse(
                          controller: _coach,
                          extraController: _jackIntro,
                          targetKey: _instructionDeckKey,
                          bounce: false,
                          child: JourneyInstructionDeck(
                            unlockedThrough: _guideUnlockCount,
                            expanded: false,
                            deckKey: _instructionDeckKey,
                            world: _activeWorld,
                            onExpand: _openGuide,
                            onCollapse: _closeGuide,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_guideExpanded)
                    Positioned.fill(
                      child: JourneyInstructionDeck(
                        unlockedThrough: _guideUnlockCount,
                        expanded: true,
                        initialPage: _guideOpenPage,
                        world: _activeWorld,
                        carouselKey: _instructionCarouselKey,
                        ceremonyPageId: _instructionCeremonyPageId,
                        ceremonyT: _instructionCeremonyPageId == null
                            ? null
                            : _instructionUnlockAnim.value,
                        onExpand: _openGuide,
                        onCollapse: _instructionCeremonyPageId != null
                            ? () {}
                            : _closeGuide,
                        showUnlockChallengerCta: _instructionCeremonyPageId ==
                                null &&
                            (_guideShowUnlockCta || _showStoryContinueCta),
                        unlockChallengerLabel: _showStoryContinueCta
                            ? JourneyL10n.of(context).continueLabel
                            : JourneyL10n.of(context).unlockNextChallenger,
                        onUnlockNextChallenger: _onUnlockNextChallenger,
                        showEnterKingdomCta: () {
                          final p = context.read<AppRepo>().journeyProgress;
                          if (_coach.isWaitingForLetter) return true;
                          if ((_sessionTutorialDone || _coach.isFinished) &&
                              !p.diamondsEntered) {
                            return true;
                          }
                          if (p.diamondsAceEscapeSeen &&
                              p.isDefeated(
                                JourneyWorld.diamonds,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.clubs)) {
                            return true;
                          }
                          if (p.clubsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.clubs,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.hearts)) {
                            return true;
                          }
                          return p.heartsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.hearts,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.spades);
                        }(),
                        enterKingdomPageId: () {
                          final p = context.read<AppRepo>().journeyProgress;
                          if (p.heartsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.hearts,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.spades)) {
                            return 12;
                          }
                          if (p.clubsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.clubs,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.hearts)) {
                            return 8;
                          }
                          if (p.diamondsAceEscapeSeen &&
                              p.isDefeated(
                                JourneyWorld.diamonds,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.clubs)) {
                            return 6;
                          }
                          return 1;
                        }(),
                        enterKingdomLabel: () {
                          final j = JourneyL10n.of(context);
                          final repo = context.read<AppRepo>();
                          final p = repo.journeyProgress;
                          if (_coach.isWaitingForLetter) {
                            return j.continueLabel;
                          }
                          if (p.heartsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.hearts,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.spades)) {
                            return repo.canEnterKingdom(JourneyWorld.spades)
                                ? j.enterKingdom(JourneyWorld.spades)
                                : j.reachLevelToEnter(
                                    JourneyWorld.spades.requiredLevel,
                                    JourneyWorld.spades,
                                  );
                          }
                          if (p.clubsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.clubs,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.hearts)) {
                            return repo.canEnterKingdom(JourneyWorld.hearts)
                                ? j.enterKingdom(JourneyWorld.hearts)
                                : j.reachLevelToEnter(
                                    JourneyWorld.hearts.requiredLevel,
                                    JourneyWorld.hearts,
                                  );
                          }
                          if (p.diamondsAceEscapeSeen &&
                              p.isDefeated(
                                JourneyWorld.diamonds,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.clubs)) {
                            return repo.canEnterKingdom(JourneyWorld.clubs)
                                ? j.enterKingdom(JourneyWorld.clubs)
                                : j.reachLevelToEnter(
                                    JourneyWorld.clubs.requiredLevel,
                                    JourneyWorld.clubs,
                                  );
                          }
                          return j.enterKingdom(JourneyWorld.diamonds);
                        }(),
                        onEnterKingdom: () {
                          final repo = context.read<AppRepo>();
                          final p = repo.journeyProgress;
                          if (_coach.isWaitingForLetter) {
                            _closeGuide();
                            return;
                          }
                          if (p.heartsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.hearts,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.spades)) {
                            if (!repo.canEnterKingdom(JourneyWorld.spades)) {
                              return;
                            }
                            _enterKingdomFromGuide(JourneyWorld.spades);
                            return;
                          }
                          if (p.clubsAceGiftSeen &&
                              p.isDefeated(
                                JourneyWorld.clubs,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.hearts)) {
                            if (!repo.canEnterKingdom(JourneyWorld.hearts)) {
                              return;
                            }
                            _enterKingdomFromGuide(JourneyWorld.hearts);
                            return;
                          }
                          if (p.diamondsAceEscapeSeen &&
                              p.isDefeated(
                                JourneyWorld.diamonds,
                                JourneyRank.ace,
                              ) &&
                              !p.hasEntered(JourneyWorld.clubs)) {
                            if (!repo.canEnterKingdom(JourneyWorld.clubs)) {
                              return;
                            }
                            _enterKingdomFromGuide(JourneyWorld.clubs);
                            return;
                          }
                          _enterKingdomFromGuide(JourneyWorld.diamonds);
                        },
                      ),
                    ),
                ],

                // Dragging card under the finger.
                if (_dragging != null && _dragPos != null)
                  Positioned(
                    left: _dragPos!.dx - pileCardSize * 0.45,
                    top: _dragPos!.dy -
                        (pileCardSize * 0.9 / homeCardAspect) * 0.5,
                    width: pileCardSize * 0.9,
                    height: pileCardSize * 0.9 / homeCardAspect,
                    child: JourneyFaceUpCard(
                      assetPath: _dragging!.avatarAssetPath,
                      world: _dragging!.world,
                    ),
                  ),

                // Focus from the card's real home (challenger or defeated drag).
                if (selected != null &&
                    _defeatedCarouselWorld == null &&
                    _defeatFlying == null &&
                    selectProgress > 0.01 &&
                    !_guideExpanded)
                  JourneyChallengerFocus(
                    key: ValueKey(
                      '${selected.world.name}_${selected.rank.name}',
                    ),
                    card: selected,
                    progress: selectProgress,
                    from: homeFrom,
                    to: centerTarget,
                    fromSize: pileCardSize,
                    toSize: centerSize,
                    // First Jack unlock flips face-down → face-up into focus.
                    startsFaceUp: !_selectStartsFaceDown,
                    onChallenge: _onChallenge,
                    onDismiss: _onDismissSelected,
                  ),

                if (_defeatedCarouselWorld != null &&
                    !_guideExpanded &&
                    _defeatFlying == null)
                  Positioned.fill(
                    child: JourneyDefeatedCarousel(
                      key: ValueKey(_defeatedCarouselWorld!.name),
                      worldDef: _snapshot.worldOf(_defeatedCarouselWorld!),
                      focusRank: _defeatedCarouselRank,
                      onFocusRankChanged: (rank) {
                        setState(() => _defeatedCarouselRank = rank);
                      },
                      onDismiss: () {
                        _closeDefeatedCarousel();
                      },
                      onReplay: (card) async {
                        // Keep carousel (and trail token) on this challenger
                        // until Play / Test commits — Cancel leaves focus here.
                        if (_defeatedCarouselRank != card.rank) {
                          setState(() => _defeatedCarouselRank = card.rank);
                        }
                        await _promptChallengeMatch(card);
                      },
                    ),
                  ),

                if (_defeatFlying != null)
                  _DefeatedTransferCard(
                    card: _defeatFlying!,
                    flight: Curves.easeInOutCubic
                        .transform(_defeatFlyAnim.value),
                    from: centerTarget,
                    to: _defeatFlyTo ??
                        defeatedTargets[
                            JourneyWorld.values.indexOf(_defeatFlying!.world)],
                    startSize: centerSize * 0.85,
                    endSize: _defeatFlyTo != null && _defeatFlySize > 0
                        ? _defeatFlySize
                        : centerSize * 0.85,
                  ),

                JourneyCoachOverlay(
                  controller: _coach,
                  onOpenLetter: _onCoachOpenLetter,
                  onCompleted: _onCoachCompleted,
                ),

                JourneyJackIntroOverlay(
                  controller: _jackIntro,
                  onChallenge: _onJackIntroChallenge,
                ),

                JourneyQueenIntroOverlay(
                  controller: _queenIntro,
                  onChallenge: _onQueenIntroChallenge,
                ),

                JourneyStoryOverlay(
                  listenable: _kingIntro,
                  isActive: () => _kingIntro.isActive,
                  currentStep: () => _kingIntro.currentStep,
                  stepIndex: () => _kingIntro.stepIndex,
                  totalSteps: () => _kingIntro.steps.length,
                  onNext: _kingIntro.next,
                  onComplete: () async {
                    _kingIntro.finish();
                    await _onKingIntroChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _aceEscape,
                  isActive: () => _aceEscape.isActive,
                  currentStep: () => _aceEscape.currentStep,
                  stepIndex: () => _aceEscape.stepIndex,
                  totalSteps: () => _aceEscape.steps.length,
                  onNext: _aceEscape.next,
                  onComplete: () async {
                    _aceEscape.finish();
                    await _onAceEscapeComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).runAway,
                ),

                JourneyStoryOverlay(
                  listenable: _clubsJackIntro,
                  isActive: () => _clubsJackIntro.isActive,
                  currentStep: () => _clubsJackIntro.currentStep,
                  stepIndex: () => _clubsJackIntro.stepIndex,
                  totalSteps: () => _clubsJackIntro.steps.length,
                  onNext: _clubsJackIntro.next,
                  onComplete: () async {
                    _clubsJackIntro.finish();
                    await _onClubsJackChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _clubsCourt,
                  isActive: () => _clubsCourt.isActive,
                  currentStep: () => _clubsCourt.currentStep,
                  stepIndex: () => _clubsCourt.stepIndex,
                  totalSteps: () => _clubsCourt.steps.length,
                  onNext: _clubsCourt.next,
                  onComplete: () async {
                    _clubsCourt.finish();
                    await _onClubsCourtChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _clubsAceOffer,
                  isActive: () => _clubsAceOffer.isActive,
                  currentStep: () => _clubsAceOffer.currentStep,
                  stepIndex: () => _clubsAceOffer.stepIndex,
                  totalSteps: () => _clubsAceOffer.steps.length,
                  onNext: _clubsAceOffer.next,
                  onComplete: () async {
                    _clubsAceOffer.finish();
                    await _onClubsAceOfferComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _clubsHeartsSendoff,
                  isActive: () => _clubsHeartsSendoff.isActive,
                  currentStep: () => _clubsHeartsSendoff.currentStep,
                  stepIndex: () => _clubsHeartsSendoff.stepIndex,
                  totalSteps: () => _clubsHeartsSendoff.steps.length,
                  onNext: _clubsHeartsSendoff.next,
                  onComplete: () async {
                    _clubsHeartsSendoff.finish();
                    await _onClubsHeartsSendoffComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _heartsJackIntro,
                  isActive: () => _heartsJackIntro.isActive,
                  currentStep: () => _heartsJackIntro.currentStep,
                  stepIndex: () => _heartsJackIntro.stepIndex,
                  totalSteps: () => _heartsJackIntro.steps.length,
                  onNext: _heartsJackIntro.next,
                  onComplete: () async {
                    _heartsJackIntro.finish();
                    await _onHeartsJackChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _heartsQueenEscort,
                  isActive: () => _heartsQueenEscort.isActive,
                  currentStep: () => _heartsQueenEscort.currentStep,
                  stepIndex: () => _heartsQueenEscort.stepIndex,
                  totalSteps: () => _heartsQueenEscort.steps.length,
                  onNext: _heartsQueenEscort.next,
                  onComplete: () async {
                    _heartsQueenEscort.finish();
                    await _onHeartsQueenEscortChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _heartsKingIntro,
                  isActive: () => _heartsKingIntro.isActive,
                  currentStep: () => _heartsKingIntro.currentStep,
                  stepIndex: () => _heartsKingIntro.stepIndex,
                  totalSteps: () => _heartsKingIntro.steps.length,
                  onNext: _heartsKingIntro.next,
                  onComplete: () async {
                    _heartsKingIntro.finish();
                    await _onHeartsKingIntroChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _heartsAceOffer,
                  isActive: () => _heartsAceOffer.isActive,
                  currentStep: () => _heartsAceOffer.currentStep,
                  stepIndex: () => _heartsAceOffer.stepIndex,
                  totalSteps: () => _heartsAceOffer.steps.length,
                  onNext: _heartsAceOffer.next,
                  onComplete: () async {
                    _heartsAceOffer.finish();
                    await _onHeartsAceOfferComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesJackIntro,
                  isActive: () => _spadesJackIntro.isActive,
                  currentStep: () => _spadesJackIntro.currentStep,
                  stepIndex: () => _spadesJackIntro.stepIndex,
                  totalSteps: () => _spadesJackIntro.steps.length,
                  onNext: _spadesJackIntro.next,
                  onComplete: () async {
                    _spadesJackIntro.finish();
                    await _onSpadesJackChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesKingEscort,
                  isActive: () => _spadesKingEscort.isActive,
                  currentStep: () => _spadesKingEscort.currentStep,
                  stepIndex: () => _spadesKingEscort.stepIndex,
                  totalSteps: () => _spadesKingEscort.steps.length,
                  onNext: _spadesKingEscort.next,
                  onComplete: () async {
                    _spadesKingEscort.finish();
                    await _onSpadesKingEscortChallenge();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).challenge,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesCamp,
                  isActive: () => _spadesCamp.isActive,
                  currentStep: () => _spadesCamp.currentStep,
                  stepIndex: () => _spadesCamp.stepIndex,
                  totalSteps: () => _spadesCamp.steps.length,
                  onNext: _spadesCamp.next,
                  onComplete: () async {
                    _spadesCamp.finish();
                    await _onSpadesCampComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesRuinsApproach,
                  isActive: () => _spadesRuinsApproach.isActive,
                  currentStep: () => _spadesRuinsApproach.currentStep,
                  stepIndex: () => _spadesRuinsApproach.stepIndex,
                  totalSteps: () => _spadesRuinsApproach.steps.length,
                  onNext: _spadesRuinsApproach.next,
                  onComplete: () async {
                    _spadesRuinsApproach.finish();
                    await _onSpadesRuinsApproachComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesRuinsClimax,
                  isActive: () => _spadesRuinsClimax.isActive,
                  currentStep: () => _spadesRuinsClimax.currentStep,
                  stepIndex: () => _spadesRuinsClimax.stepIndex,
                  totalSteps: () => _spadesRuinsClimax.steps.length,
                  onNext: _spadesRuinsClimax.next,
                  onComplete: () async {
                    _spadesRuinsClimax.finish();
                    await _onSpadesRuinsClimaxComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                JourneyStoryOverlay(
                  listenable: _spadesFinale,
                  isActive: () => _spadesFinale.isActive,
                  currentStep: () => _spadesFinale.currentStep,
                  stepIndex: () => _spadesFinale.stepIndex,
                  totalSteps: () => _spadesFinale.steps.length,
                  onNext: _spadesFinale.next,
                  onComplete: () async {
                    _spadesFinale.finish();
                    await _onSpadesFinaleComplete();
                  },
                  lastPrimaryLabel: JourneyL10n.of(context).continueLabel,
                ),

                if (_themeUnlockRewardWorld != null)
                  Positioned.fill(
                    child: JourneyThemeUnlockRewardOverlay(
                      world: _themeUnlockRewardWorld!,
                      onGoToProfile: () {
                        final repo = context.read<AppRepo>();
                        repo.requestProfileGift(
                          PendingProfileGift(
                            world: _themeUnlockRewardWorld,
                            openLooks: true,
                            focusLeagueTip: true,
                          ),
                        );
                        repo.requestProfileThemeTip();
                        _onThemeUnlockRewardDismissed(goToProfile: true);
                      },
                      onContinue: () {
                        _onThemeUnlockRewardDismissed(goToProfile: false);
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Face-up card moving into a defeated pile or Ace → trail token.
class _DefeatedTransferCard extends StatelessWidget {
  const _DefeatedTransferCard({
    required this.card,
    required this.flight,
    required this.from,
    required this.to,
    required this.startSize,
    required this.endSize,
  });

  final JourneyCardDef card;
  final double flight;
  final Offset from;
  final Offset to;
  final double startSize;
  final double endSize;

  @override
  Widget build(BuildContext context) {
    if (flight >= 0.98) return const SizedBox.shrink();

    final t = Curves.easeInOutCubic.transform(flight.clamp(0.0, 1.0));
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy < to.dy ? from.dy : to.dy) - 40,
    );
    final pos = JourneyTableLayout.quad(from, mid, to, t);
    final drawSize = startSize + (endSize - startSize) * t;
    final height = drawSize / homeCardAspect;

    return Positioned(
      left: pos.dx - drawSize / 2,
      top: pos.dy - height / 2,
      width: drawSize,
      height: height,
      child: JourneyFaceUpCard(
        assetPath: card.avatarAssetPath,
        world: card.world,
      ),
    );
  }
}
