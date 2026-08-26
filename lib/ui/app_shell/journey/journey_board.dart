import 'dart:math' as math;

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
  static const _revealDuration = Duration(milliseconds: 420);
  static const _themeUnlockDuration = Duration(milliseconds: 1700);
  static const _instructionUnlockDuration = Duration(milliseconds: 1700);

  late List<JourneyWorldDef> _worlds;
  JourneyWorld _activeWorld = JourneyWorld.diamonds;
  JourneyCardDef? _selected;
  /// Where the focused card lives when not centered.
  bool _selectedFromDefeated = false;
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
  final GlobalKey _trailTokenKey = GlobalKey();
  final GlobalKey _instructionDeckKey = GlobalKey();
  final GlobalKey<StackedCardCarouselState> _instructionCarouselKey =
      GlobalKey();
  final Map<JourneyWorld, GlobalKey> _pileKeys = {
    for (final w in JourneyWorld.values) w: GlobalKey(),
  };
  late final JourneyCoachController _coach;

  JourneyWorld? _themeUnlockWorld;
  bool _themeUnlockForceSealed = false;
  bool _themeUnlockApplied = false;
  Future<void>? _themeUnlockApplyFuture;
  JourneyWorld? _themeUnlockRewardWorld;
  /// After Diamonds theme reward, unlock instruction page 2 with ceremony.
  bool _pendingDiamondsInstructionReveal = false;
  int? _instructionCeremonyPageId;
  bool _instructionCeremonyUnlocked = false;
  bool _instructionCeremonyShowCta = false;

  bool _guideExpanded = false;
  int? _guideOpenPage;
  bool _coachScheduled = false;
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
    _coach = JourneyCoachController(
      pilesKey: _pilesKey,
      centerKey: _centerKey,
      defeatedKey: _defeatedKey,
      deckKey: _instructionDeckKey,
    );
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
    }
  }

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
    _coach.dispose();
    super.dispose();
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
          : repo.unlockAndEquipPack(world.themeId).then((_) {});
      widget.onWorldThemeEquipped?.call(world);
    }
    setState(() {});
  }

  /// First-time theme unlock ceremony for [world]. Returns false if cancelled.
  Future<bool> _runThemeUnlockCeremony(JourneyWorld world) async {
    if (_themeUnlockWorld != null) return false;
    final repo = context.read<AppRepo>();
    final alreadyOwned = repo.ownsPack(world.themeId) &&
        repo.journeyProgress.hasEntered(world);
    if (alreadyOwned) {
      await repo.unlockAndEquipPack(world.themeId);
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
    final wasDiamonds = _themeUnlockRewardWorld == JourneyWorld.diamonds;
    if (!mounted) return;
    setState(() => _themeUnlockRewardWorld = null);
    if (!wasDiamonds || !_pendingDiamondsInstructionReveal) return;

    // Profile path: keep pending so Games tab return can reveal later.
    if (goToProfile) return;

    _pendingDiamondsInstructionReveal = false;
    await _runInstructionUnlockCeremony(
      beforeUnlock: 1,
      afterUnlock: 2,
      showUnlockCtaAfter: false,
    );
  }

  /// Called when the Games tab is focused again (e.g. after Go to profile).
  void onShellTabVisible() {
    if (!_pendingDiamondsInstructionReveal) return;
    if (_themeUnlockRewardWorld != null) return;
    if (_instructionCeremonyPageId != null) return;
    _pendingDiamondsInstructionReveal = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runInstructionUnlockCeremony(
        beforeUnlock: 1,
        afterUnlock: 2,
        showUnlockCtaAfter: false,
      );
    });
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
    setState(() {
      _worlds = _copyWorlds(_repo!.journeyBoardForLevel());
      _activeWorld = JourneyWorld.diamonds;
      _selected = null;
      _selectedFromDefeated = false;
      _selectFromOverride = null;
      _defeatFlying = null;
      _revealCard = null;
      _dragging = null;
      _draggingFromDefeated = false;
      _dragPos = null;
      _guideExpanded = false;
      _guideOpenPage = null;
      _coachScheduled = false;
      _sessionTutorialDone = false;
      _tauntScheduled = false;
      _guideDisplayedUnlock = null;
      _guideShowUnlockCta = false;
      _pendingUnlockCard = null;
      _themeUnlockWorld = null;
      _themeUnlockRewardWorld = null;
      _pendingDiamondsInstructionReveal = false;
      _instructionCeremonyPageId = null;
      _instructionCeremonyUnlocked = false;
      _instructionCeremonyShowCta = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeStartCoach();
    });
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
    await showJourneyLossTaunt(context, card: card);
    if (!mounted) return;
    await repo.clearPendingJourneyLossTaunt();
    _tauntScheduled = false;
    if (!mounted) return;
    // Replay losses stay on the board until return-to-progress; don't re-focus.
    if (card.isSelectable && card.state != JourneyCardState.defeated) {
      await _selectCard(card, fromDefeated: false);
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
  }

  void _maybeStartCoach() {
    if (_coachScheduled || _coach.isActive || _coach.isFinished) return;
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

  bool get _tutorialDoneForUnlocks =>
      _sessionTutorialDone || _coach.isFinished;

  int get _unlockedThrough => journeyUnlockedThrough(
        snapshot: _snapshot,
        tutorialDone: _tutorialDoneForUnlocks,
        diamondsEntered: context.read<AppRepo>().journeyProgress.diamondsEntered,
      );

  bool get _needsFirstJackUnlock {
    final progress = context.read<AppRepo>().journeyProgress;
    return progress.diamondsEntered && !progress.diamondsJackUnlocked;
  }

  bool get _showProveYourselfUnlockCta =>
      _needsFirstJackUnlock && !_guideShowUnlockCta;

  /// Unlock count shown in the guide (may lag during win celebration).
  int get _guideUnlockCount => _guideDisplayedUnlock ?? _unlockedThrough;

  void _openGuide({int? page}) {
    setState(() {
      _guideExpanded = true;
      _guideOpenPage = page ?? (_guideUnlockCount - 1).clamp(0, 100);
    });
  }

  void _closeGuide() {
    setState(() {
      _guideExpanded = false;
      _guideOpenPage = null;
    });
  }

  void _onCoachCompleted() {
    setState(() {
      _sessionTutorialDone = true;
      _guideExpanded = true;
      // Always open the welcome page first after the coach.
      _guideOpenPage = 0;
    });
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
    final loss = repo.journeyProgress.pendingLossTaunt;
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
    final focus = win ?? praise ?? loss;
    if (focus != null) {
      _restorePostMatchChallenger(
        focus,
        openCarousel: win == null,
      );
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
    );
    final beforeUnlock = (afterUnlock - 1).clamp(1, afterUnlock);

    setState(() {
      _worlds = _copyWorlds(repo.journeyBoardForLevel());
      _pendingUnlockCard = next;
      _selected = null;
      _selectAnim.value = 0;
      _revealCard = null;
      _activeWorld = defeated.world;
      _defeatedCarouselWorld = null;
    });

    await _runInstructionUnlockCeremony(
      beforeUnlock: beforeUnlock,
      afterUnlock: afterUnlock,
      showUnlockCtaAfter: true,
    );
  }

  Future<void> _onUnlockNextChallenger() async {
    final repo = context.read<AppRepo>();

    // First-time Diamonds Jack reveal from Prove yourself.
    if (_pendingUnlockCard == null && _needsFirstJackUnlock) {
      await repo.unlockDiamondsJack();
      if (!mounted) return;
      setState(() {
        _guideExpanded = false;
        _guideOpenPage = null;
        _guideShowUnlockCta = false;
        _worlds = _copyWorlds(repo.journeyBoardForLevel());
        _revealCard = _snapshot
            .worldOf(JourneyWorld.diamonds)
            .cardOf(JourneyRank.jack);
        _revealAnim.value = 0;
        _activeWorld = JourneyWorld.diamonds;
      });
      await _playRevealIfNeeded();
      if (!mounted) return;
      final unlocked = _snapshot
          .worldOf(JourneyWorld.diamonds)
          .cardOf(JourneyRank.jack);
      if (unlocked != null) {
        await _selectCard(unlocked, fromDefeated: false, skipEquip: true);
      }
      return;
    }

    final next = _pendingUnlockCard;
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

    if (next == null) return;
    final unlocked = _snapshot.worldOf(next.world).cardOf(next.rank) ?? next;
    final equipped = await _equipWorld(unlocked.world);
    if (!mounted) return;
    setState(() {
      _revealCard = unlocked;
      _revealAnim.value = 0;
      if (equipped && unlocked.world != _activeWorld) {
        _activeWorld = unlocked.world;
      }
    });
    await _playRevealIfNeeded();
    if (!mounted) return;
    await _selectCard(unlocked, fromDefeated: false, skipEquip: true);
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
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Claim: ${card.title}'),
          content: const Text('Collect this Ace and unlock the next world.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop('defeat'),
              child: const Text('Claim'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (!mounted || claim != 'defeat') return;
      await _resolveDefeat(card);
      return;
    }

    final alreadyDefeated = context.read<AppRepo>().journeyProgress.isDefeated(
      card.world,
      card.rank,
    );
    final outcome = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          alreadyDefeated
              ? 'Replay: ${card.title}'
              : 'Challenge: ${card.title}',
        ),
        content: Text(
          alreadyDefeated
              ? 'Play ${card.gameLabel} again against this challenger.'
              : 'Play ${card.gameLabel} against this challenger.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop('play'),
            child: const Text('Play'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop('test'),
            child: const Text('Test…'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
        } else {
          await _resolveDefeat(card);
        }
        return;
      }
      if (testOutcome == 'lose') {
        _pinTrailToCard(card);
        await showJourneyLossTaunt(context, card: card);
      }
      return;
    }

    if (outcome == 'play') {
      _pinTrailToCard(card);
      await _startJourneyMatch(card);
    }
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
    final mode = card.gameMode;
    if (mode == null) return;
    final repo = context.read<AppRepo>();
    final vm = context.read<GamesViewModel>();
    await gameEnter(
      context,
      vm,
      mode,
      true,
      botOverride: LocalBotProfile(
        name: card.rank.label,
        avatarId: journeyAvatarId(card.world, card.rank),
        avatarAsset: card.avatarAssetPath,
      ),
      onCreated: (gid) => repo.beginJourneyChallenge(
        world: card.world,
        rank: card.rank,
        gameId: gid,
      ),
    );
  }

  Future<void> _playRevealIfNeeded() async {
    final card = _revealCard;
    if (card == null) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    await _revealAnim.forward(from: 0);
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
  }) async {
    final def = _snapshot.worldOf(card.world);
    if (!def.unlocked || !card.isSelectable) {
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
    final boardInteractive =
        !_coach.isActive && !_guideExpanded && _themeUnlockWorld == null;

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
                : Curves.easeOut.transform(_revealAnim.value);
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
                      JourneyProgressTrail(
                        progress: context.watch<AppRepo>().journeyProgress,
                        tokenStepIndex: _trailTokenStep(
                          context.watch<AppRepo>().journeyProgress,
                        ),
                        activeWorld: _activeWorld,
                        tokenKey: _trailTokenKey,
                        height: 52,
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
                      ignoring: _coach.isActive || _guideExpanded,
                      child: Opacity(
                        opacity: centerReveal,
                        child: JourneyCoachPulse(
                          controller: _coach,
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
                        showUnlockChallengerCta: _guideShowUnlockCta ||
                            _showProveYourselfUnlockCta,
                        unlockChallengerLabel: _pendingUnlockCard == null
                            ? 'Unlock next challenger'
                            : 'Unlock next challenger',
                        onUnlockNextChallenger: _onUnlockNextChallenger,
                        showEnterKingdomCta: !context
                            .read<AppRepo>()
                            .journeyProgress
                            .diamondsEntered,
                        enterKingdomLabel: 'Enter Diamonds kingdom',
                        onEnterKingdom: () =>
                            _enterKingdomFromGuide(JourneyWorld.diamonds),
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
                    // Pile available + defeated are already face-up.
                    startsFaceUp: true,
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
                  onCompleted: _onCoachCompleted,
                ),

                if (_themeUnlockRewardWorld != null)
                  Positioned.fill(
                    child: JourneyThemeUnlockRewardOverlay(
                      world: _themeUnlockRewardWorld!,
                      onGoToProfile: () {
                        final repo = context.read<AppRepo>();
                        repo.requestProfileThemeTip();
                        _onThemeUnlockRewardDismissed(goToProfile: true);
                        repo.requestShellTab(2);
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
