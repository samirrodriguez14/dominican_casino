import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/animations/profile_gift_flight.dart';
import 'package:dominican_casino/ui/app_shell/games/account_setup_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_peek_card.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/games/welcome_tutorial_popup.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:dominican_casino/ui/app_shell/profile/level_rewards_popup.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_screen.dart';
import 'package:dominican_casino/ui/app_shell/store/store_screen.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/models/daily_challenge.dart';
import 'package:dominican_casino/ui/widgets/home_coin_celebration.dart';
import 'package:dominican_casino/ui/widgets/home_energy_celebration.dart';
import 'package:dominican_casino/ui/widgets/journey_unlock_celebration.dart';
import 'package:dominican_casino/ui/widgets/level_unlock_dialog.dart';
import 'package:dominican_casino/ui/widgets/profile_gift_sprites.dart';
import 'package:dominican_casino/ui/widgets/xp_player_avatar.dart';
import 'package:dominican_casino/ui/widgets/exp_icon.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<StatefulWidget> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int currentIndex = 1;
  late final PageController _pageController;
  final _storeKey = GlobalKey<StoreScreenState>();
  final _gamesKey = GlobalKey<GamesScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  final _gamesTabKey = GlobalKey(debugLabel: 'gamesTab');
  final _profileTabKey = GlobalKey(debugLabel: 'profileTab');
  late final AnimationController _gamesTabEat;
  late final AnimationController _profileTabEat;
  bool _offeredTutorial = false;
  HomeCoinClaim? _activeCoinCelebration;
  List<DailyChallengeId>? _activeEnergyCelebrationChallengeIds;
  int? _activeEnergyAmount;
  bool _xpBurstRunning = false;
  bool _journeyUnlockShowing = false;
  bool _levelCelebrationShowing = false;
  bool _profileGiftRunning = false;
  String? _listeningPid;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _gamesTabEat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _profileTabEat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<AppRepo>().ensurePlayableUid();
      } catch (_) {}
      if (!mounted) return;
      _syncGameListener();
      _maybeOfferFirstRun();
    });
  }

  void _syncGameListener() {
    final repo = context.read<AppRepo>();
    final pid = repo.player?.id;
    if (pid == null || pid == _listeningPid) return;
    _listeningPid = pid;
    context.read<GamesViewModel>().startListening(pid);
  }

  void _maybeOfferFirstRun() {
    if (_offeredTutorial || !mounted) return;
    final repo = context.read<AppRepo>();
    if (repo.pendingHomeCoinClaim != null ||
        repo.pendingHomeDailyChallengeEnergy.isNotEmpty ||
        repo.pendingHomeXpClaim != null ||
        repo.journeyProgress.pendingUnlockReward != null ||
        repo.pendingLevelCelebration != null ||
        repo.pendingProfileGift != null ||
        _activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _journeyUnlockShowing ||
        _levelCelebrationShowing ||
        _profileGiftRunning) {
      return;
    }
    final player = repo.player;
    if (player == null) return;
    _offeredTutorial = true;
    if (!player.completedTutorial) {
      showWelcomeTutorialPopup(context);
      return;
    }
    if (player.needsAccountSetup) {
      showAccountSetupPopup(context);
    }
  }

  void _maybeStartHomeCoinCelebration(AppRepo repo) {
    final pending = repo.pendingHomeCoinClaim;
    if (pending == null ||
        _activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _journeyUnlockShowing ||
        _levelCelebrationShowing) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_activeCoinCelebration != null ||
          _activeEnergyAmount != null ||
          _xpBurstRunning ||
          _journeyUnlockShowing ||
          _levelCelebrationShowing) {
        return;
      }
      final claim = context.read<AppRepo>().pendingHomeCoinClaim;
      if (claim == null) return;
      setState(() => _activeCoinCelebration = claim);
    });
  }

  void _maybeStartHomeEnergyCelebration(AppRepo repo) {
    final pending = repo.pendingHomeDailyChallengeEnergy;
    if (pending.isEmpty) return;
    if (repo.pendingHomeCoinClaim != null) return; // coin overlay has priority
    if (_activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _journeyUnlockShowing ||
        _levelCelebrationShowing) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (repo.pendingHomeCoinClaim != null) return;
      if (context.read<AppRepo>().pendingHomeDailyChallengeEnergy.isEmpty) {
        return;
      }
      if (_levelCelebrationShowing || _journeyUnlockShowing) return;
      final ids = context
          .read<AppRepo>()
          .pendingHomeDailyChallengeEnergy
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _activeEnergyCelebrationChallengeIds = ids;
        _activeEnergyAmount =
            context.read<AppRepo>().pendingHomeDailyChallengeEnergyAmount;
      });
    });
  }

  void _maybeStartHomeXpBurst(AppRepo repo) {
    final pending = repo.pendingHomeXpClaim;
    if (pending == null || _xpBurstRunning) return;
    if (repo.pendingHomeCoinClaim != null ||
        repo.pendingHomeDailyChallengeEnergy.isNotEmpty ||
        _activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _journeyUnlockShowing ||
        _levelCelebrationShowing) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _xpBurstRunning || _journeyUnlockShowing) return;
      if (_levelCelebrationShowing) return;
      final claim = context.read<AppRepo>().pendingHomeXpClaim;
      if (claim == null) return;
      if (context.read<AppRepo>().pendingHomeCoinClaim != null) return;
      if (context.read<AppRepo>().pendingHomeDailyChallengeEnergy.isNotEmpty) {
        return;
      }
      _playHomeXpBurst(claim);
    });
  }

  Future<void> _playHomeXpBurst(HomeXpClaim claim) async {
    if (!mounted || _xpBurstRunning) return;
    setState(() => _xpBurstRunning = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final size = MediaQuery.sizeOf(context);
    final from = Offset(size.width * 0.5, size.height * 0.42);
    final to = XpPlayerAvatar.center;
    if (to != null) {
      await CurrencyBurst.play(
        context: context,
        from: from,
        to: to,
        icon: expIcon,
        color: AppStyle.theme.xp,
        count: claim.amount.clamp(4, 10),
        jump: true,
      );
    }
    if (!mounted) return;
    await context.read<AppRepo>().completeHomeXpClaim();
    if (!mounted) return;
    setState(() => _xpBurstRunning = false);
    _offeredTutorial = false;
    _maybeShowLevelCelebration(context.read<AppRepo>());
    _maybeOfferFirstRun();
    _maybeStartJourneyUnlockCelebration(context.read<AppRepo>());
  }

  void _maybeShowLevelCelebration(AppRepo repo) {
    final level = repo.pendingLevelCelebration;
    if (level == null || _levelCelebrationShowing) return;
    if (repo.pendingHomeCoinClaim != null ||
        repo.pendingHomeDailyChallengeEnergy.isNotEmpty ||
        repo.pendingHomeXpClaim != null ||
        _activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _journeyUnlockShowing) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _levelCelebrationShowing) return;
      final r = context.read<AppRepo>();
      final pending = r.pendingLevelCelebration;
      if (pending == null) return;
      if (r.pendingHomeCoinClaim != null ||
          r.pendingHomeXpClaim != null ||
          r.pendingHomeDailyChallengeEnergy.isNotEmpty ||
          _journeyUnlockShowing) {
        return;
      }
      _levelCelebrationShowing = true;
      final unlockedWorld = journeyWorldUnlockedAtLevel(pending);
      final journeyWorld = unlockedWorld == JourneyWorld.diamonds
          ? null
          : unlockedWorld;
      // Journey CTA when this level opens a kingdom gate, or any kingdom
      // is already ready to enter at the new level.
      var showJourney = journeyWorld != null;
      if (!showJourney) {
        for (final world in JourneyWorld.values) {
          if (r.journeyProgress.hasEntered(world)) continue;
          if (r.journeyProgress.canUnlockThemeFor(
            world,
            playerLevel: pending,
          )) {
            showJourney = true;
            break;
          }
        }
      }
      final action = await showLevelUnlockDialog(
        context,
        level: pending,
        journeyWorld: journeyWorld,
        showJourneyCta: showJourney,
      );
      if (!mounted) return;
      r.clearPendingLevelCelebration();
      _levelCelebrationShowing = false;
      switch (action) {
        case LevelUnlockAction.rewards:
          await showLevelRewardsPopup(context);
        case LevelUnlockAction.journey:
          r.requestShellTab(1);
          r.requestOpenJourney();
        case LevelUnlockAction.exit:
          break;
      }
      if (!mounted) return;
      _offeredTutorial = false;
      _maybeOfferFirstRun();
      _maybeStartJourneyUnlockCelebration(context.read<AppRepo>());
    });
  }

  void _maybeStartJourneyUnlockCelebration(AppRepo repo) {
    final reward = repo.journeyProgress.pendingUnlockReward;
    if (reward == null || _journeyUnlockShowing) return;
    if (repo.pendingHomeCoinClaim != null ||
        repo.pendingHomeDailyChallengeEnergy.isNotEmpty ||
        repo.pendingHomeXpClaim != null ||
        repo.pendingLevelCelebration != null ||
        _activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _levelCelebrationShowing) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _journeyUnlockShowing || _levelCelebrationShowing) return;
      final r = context.read<AppRepo>();
      if (r.journeyProgress.pendingUnlockReward == null) return;
      if (r.pendingLevelCelebration != null) return;
      if (r.pendingHomeCoinClaim != null ||
          r.pendingHomeXpClaim != null ||
          r.pendingHomeDailyChallengeEnergy.isNotEmpty) {
        return;
      }
      setState(() => _journeyUnlockShowing = true);
    });
  }

  @override
  void dispose() {
    _gamesTabEat.dispose();
    _profileTabEat.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void pulseGamesTabEat() {
    _gamesTabEat.forward(from: 0);
  }

  void pulseProfileTabEat() {
    _profileTabEat.forward(from: 0);
  }

  Offset? _globalCenterOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Widget _spriteForGift(PendingProfileGift gift) {
    if (gift.world != null && gift.avatarId != null) {
      return SizedBox(
        width: 140,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: ProfileGiftSprites.themeAndLeague(gift.world!),
            ),
            Positioned(
              right: 0,
              child: ProfileGiftSprites.avatar(gift.avatarId!, size: 56),
            ),
          ],
        ),
      );
    }
    if (gift.world != null) {
      return ProfileGiftSprites.themeAndLeague(gift.world!);
    }
    if (gift.avatarId != null) {
      return ProfileGiftSprites.avatar(gift.avatarId!);
    }
    return ProfileGiftSprites.themeBadge(JourneyWorld.diamonds);
  }

  Future<void> _deliverPendingProfileGift(AppRepo repo) async {
    if (_profileGiftRunning) return;
    final peek = repo.pendingProfileGift;
    if (peek == null || !peek.hasContent) return;
    if (_activeCoinCelebration != null ||
        _activeEnergyAmount != null ||
        _xpBurstRunning ||
        _journeyUnlockShowing ||
        _levelCelebrationShowing) {
      return;
    }

    _profileGiftRunning = true;
    final gift = repo.takePendingProfileGift();
    if (gift == null || !gift.hasContent) {
      _profileGiftRunning = false;
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final from = Offset(size.width * 0.5, size.height * 0.42);
    final to = _globalCenterOf(_profileTabKey) ??
        Offset(size.width * 0.78, size.height - 36);

    await ProfileGiftFlight.play(
      context: context,
      from: from,
      to: to,
      child: _spriteForGift(gift),
      onNearLanding: pulseProfileTabEat,
    );
    if (!mounted) return;

    if (gift.switchToProfile) {
      _selectShellTab(2);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await _profileKey.currentState?.receiveProfileGift(gift);
      if (!mounted) return;
    }

    _profileGiftRunning = false;
    _offeredTutorial = false;
    _maybeOfferFirstRun();
  }

  void _maybeDeliverProfileGift(AppRepo repo) {
    if (repo.pendingProfileGift == null || _profileGiftRunning) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deliverPendingProfileGift(context.read<AppRepo>());
    });
  }

  void _onTabTap(int index) {
    if (index == currentIndex) {
      if (index == 0) {
        _storeKey.currentState?.scrollToTop();
      } else if (index == 1) {
        _gamesKey.currentState?.toggleTableDeck();
      } else if (index == 2) {
        _profileKey.currentState?.toggleProfileSettings();
      }
      return;
    }
    _selectShellTab(index);
  }

  /// Switch shell tabs without treating a same-index request as a re-tap.
  ///
  /// Used when returning from a Journey match (`shellTabRequest`) so we do not
  /// call [GamesScreenState.toggleTableDeck] and flip back to the Games table.
  void _selectShellTab(int index) {
    if (index == currentIndex) return;
    setState(() => currentIndex = index);
    AppHaptics.selectionClick();
    SoundService.instance.play(GameSound.deal);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profileKey.currentState?.onBecameVisible();
      });
    } else if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gamesKey.currentState?.onShellTabVisible();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final appRepo = context.watch<AppRepo>();
    final player = appRepo.player;
    final displayName = (player == null || player.needsAccountSetup)
        ? l10n.guest
        : (player.name ?? l10n.guest);

    final requestedTab = appRepo.shellTabRequest;
    if (requestedTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tab = context.read<AppRepo>().takeShellTabRequest();
        if (tab != null) _selectShellTab(tab);
      });
    }
    _maybeStartHomeCoinCelebration(appRepo);
    _maybeStartHomeEnergyCelebration(appRepo);
    _maybeStartHomeXpBurst(appRepo);
    _maybeShowLevelCelebration(appRepo);
    _maybeStartJourneyUnlockCelebration(appRepo);
    _maybeDeliverProfileGift(appRepo);
    if (player?.id != _listeningPid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncGameListener();
      });
    }

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KeepAlivePage(child: StoreScreen(key: _storeKey)),
                _KeepAlivePage(
                  child: GamesScreen(
                    key: _gamesKey,
                    gamesTabKey: _gamesTabKey,
                    onGamesNavEat: pulseGamesTabEat,
                  ),
                ),
                _KeepAlivePage(child: ProfileScreen(key: _profileKey)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10 + bottomInset,
            child: Center(
              child: _FloatingTabBar(
                currentIndex: currentIndex,
                onTap: _onTabTap,
                gamesTabKey: _gamesTabKey,
                gamesTabEat: _gamesTabEat,
                profileTabKey: _profileTabKey,
                profileTabEat: _profileTabEat,
                items: [
                  _FloatingTabItem(icon: CupertinoIcons.bag, label: l10n.store),
                  _FloatingTabItem(
                    icon: CupertinoIcons.game_controller,
                    label: l10n.games,
                  ),
                  _FloatingTabItem(
                    icon: CupertinoIcons.profile_circled,
                    label: l10n.profile,
                  ),
                ],
                theme: theme,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (currentIndex == 0) {
                          AppHaptics.selectionClick();
                          SoundService.instance.play(GameSound.deal);
                          _storeKey.currentState?.scrollToTop();
                          return;
                        }
                        _onTabTap(0);
                      },
                      onLongPress: kDebugMode
                          ? () async {
                              AppHaptics.mediumImpact();
                              await context
                                  .read<AppRepo>()
                                  .testEnergyFullNotification();
                            }
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: const CurrencyBar(),
                    ),
                    Expanded(
                      child: _ShellIdentity(
                        avatarId: player?.avatarId,
                        name: displayName,
                        onTap: () => showLevelRewardsPopup(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CurrentGamesPeekCard()),
          if (_activeCoinCelebration != null)
            Positioned.fill(
              child: HomeCoinCelebrationOverlay(
                key: ValueKey(_activeCoinCelebration!.gameId),
                amount: _activeCoinCelebration!.amount,
                onCollected: () =>
                    context.read<AppRepo>().completeHomeCoinClaim(),
                onDismissed: () {
                  if (!mounted) return;
                  setState(() => _activeCoinCelebration = null);
                  _offeredTutorial = false;
                  _maybeOfferFirstRun();
                  _maybeStartHomeEnergyCelebration(context.read<AppRepo>());
                  _maybeStartHomeXpBurst(context.read<AppRepo>());
                  _maybeShowLevelCelebration(context.read<AppRepo>());
                  _maybeStartJourneyUnlockCelebration(context.read<AppRepo>());
                },
              ),
            ),
          if (_activeEnergyAmount != null)
            Positioned.fill(
              child: HomeEnergyCelebrationOverlay(
                key: ValueKey(
                  (_activeEnergyCelebrationChallengeIds ??
                          <DailyChallengeId>[])
                      .map((e) => e.name)
                      .join('_'),
                ),
                amount: _activeEnergyAmount!,
                onCollected: () =>
                    context
                        .read<AppRepo>()
                        .completeHomeDailyChallengeEnergyClaims(),
                onDismissed: () {
                  if (!mounted) return;
                  setState(() {
                    _activeEnergyCelebrationChallengeIds = null;
                    _activeEnergyAmount = null;
                  });
                  _offeredTutorial = false;
                  _maybeOfferFirstRun();
                  _maybeStartHomeXpBurst(context.read<AppRepo>());
                  _maybeShowLevelCelebration(context.read<AppRepo>());
                  _maybeStartJourneyUnlockCelebration(context.read<AppRepo>());
                },
              ),
            ),
          if (_journeyUnlockShowing &&
              appRepo.journeyProgress.pendingUnlockReward != null)
            Positioned.fill(
              child: JourneyUnlockCelebrationOverlay(
                key: ValueKey(
                  'unlock-${appRepo.journeyProgress.pendingUnlockReward!.world.name}-'
                  '${appRepo.journeyProgress.pendingUnlockReward!.rank.name}',
                ),
                reward: appRepo.journeyProgress.pendingUnlockReward!,
                onDismissed: () async {
                  if (!mounted) return;
                  final pending =
                      context.read<AppRepo>().journeyProgress.pendingUnlockReward;
                  final showTrophy = pending?.showTrophy ?? false;
                  final world = pending?.world;
                  final avatarId = pending?.avatarId;
                  await context
                      .read<AppRepo>()
                      .clearPendingJourneyUnlockReward();
                  if (!mounted) return;
                  setState(() => _journeyUnlockShowing = false);

                  if (avatarId != null && avatarId.isNotEmpty) {
                    context.read<AppRepo>().requestProfileGift(
                      PendingProfileGift(
                        avatarId: avatarId,
                        openLooks: false,
                        switchToProfile: false,
                      ),
                    );
                    await _deliverPendingProfileGift(context.read<AppRepo>());
                    if (!mounted) return;
                  }

                  if (showTrophy && world != null) {
                    if (currentIndex != 1) {
                      _selectShellTab(1);
                    }
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    await WidgetsBinding.instance.endOfFrame;
                    if (!mounted) return;
                    await _gamesKey.currentState?.openJourneyTrophies(
                      revealWorld: world,
                    );
                    if (!mounted) return;
                  }
                  _offeredTutorial = false;
                  _maybeOfferFirstRun();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ShellIdentity extends StatelessWidget {
  const _ShellIdentity({
    required this.avatarId,
    required this.name,
    required this.onTap,
  });

  final String? avatarId;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.title.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          XpPlayerAvatar(avatarId: avatarId, size: 36),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _FloatingTabItem {
  const _FloatingTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.theme,
    this.gamesTabKey,
    this.gamesTabEat,
    this.profileTabKey,
    this.profileTabEat,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_FloatingTabItem> items;
  final AppTheme theme;
  final GlobalKey? gamesTabKey;
  final AnimationController? gamesTabEat;
  final GlobalKey? profileTabKey;
  final AnimationController? profileTabEat;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.border.withValues(alpha: .45)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                _FloatingTabButton(
                  key: i == 1
                      ? gamesTabKey
                      : (i == 2 ? profileTabKey : null),
                  item: items[i],
                  selected: currentIndex == i,
                  eat: i == 1
                      ? gamesTabEat
                      : (i == 2 ? profileTabEat : null),
                  onTap: () => onTap(i),
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingTabButton extends StatelessWidget {
  const _FloatingTabButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.theme,
    this.eat,
  });

  final _FloatingTabItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;
  final AnimationController? eat;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? theme.textPrimary : theme.muted;
    final button = CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.surfaceAlt.withValues(alpha: .45)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: fg),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    final controller = eat;
    if (controller == null) return button;

    // Scale only this tab so eat pulses / AppRepo rebuilds don't stall taps.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: journeyEatPulseScale(controller.value),
          child: child,
        );
      },
      child: button,
    );
  }
}
