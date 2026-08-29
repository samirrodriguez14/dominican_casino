import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_card.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_coach.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_settings_body.dart';
import 'package:dominican_casino/ui/app_shell/profile/theme_pack_carousel.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  final GlobalKey<ThemePackCarouselState> _themesCarouselKey = GlobalKey();
  final GlobalKey _identityKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  final GlobalKey _looksKey = GlobalKey();
  final GlobalKey _leagueKey = GlobalKey();
  final GlobalKey _themesKey = GlobalKey();
  final GlobalKey _doneKey = GlobalKey();

  late final ProfileCoachController _coach;

  bool _looksMode = false;
  bool _looksGrid = false;
  int _looksIndex = 0;
  int _frontIndex = 0;
  bool _coachScheduled = false;
  AppRepo? _repo;
  int _lastStoryEpoch = -1;

  @override
  void initState() {
    super.initState();
    _coach = ProfileCoachController(leagueKey: _leagueKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<AppRepo>();
    if (!identical(_repo, repo)) {
      _repo?.removeListener(_onRepoChanged);
      _repo = repo;
      _repo!.addListener(_onRepoChanged);
      _lastStoryEpoch = repo.journeyStoryEpoch;
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onRepoChanged);
    _coach.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted || _repo == null) return;
    final epoch = _repo!.journeyStoryEpoch;
    if (epoch == _lastStoryEpoch) return;
    _lastStoryEpoch = epoch;
    _coachScheduled = false;
    _coach.reset();
  }

  /// Called by the shell when the Profile tab becomes visible.
  void onBecameVisible() {
    _maybeStartCoach();
  }

  Future<void> _ensureProfileCardFront() async {
    if (_looksMode) {
      setState(() {
        _looksMode = false;
        _looksGrid = false;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (_frontIndex != 0) {
      await _carouselKey.currentState?.goToIndex(0);
      if (!mounted) return;
      setState(() => _frontIndex = 0);
    }
  }

  void _maybeStartCoach() {
    if (_looksMode) return;
    if (_coachScheduled || _coach.isActive || _coach.isFinished) return;
    final repo = context.read<AppRepo>();
    final player = repo.player;
    if (player == null) return;
    if (player.completedProfileTutorial) {
      _coach.finish();
      return;
    }
    // Only after Journey kingdom unlock → "Go to profile".
    if (!repo.takePendingProfileThemeTip()) return;
    _coachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Same as before: leave looks mode and bring the identity card to front
      // so the league tip target is on-screen for the tooltip.
      await _ensureProfileCardFront();
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _coach.start();
    });
  }

  void toggleProfileSettings() {
    if (_looksMode) {
      closeLooks();
      return;
    }
    _carouselKey.currentState?.toggleFront();
  }

  void openLooks({Theme? focusTheme}) {
    final repo = context.read<AppRepo>();
    final current = focusTheme ?? repo.appTheme;
    final packs = visibleThemePacksForProfile(repo.ownedPacks);
    final index = packs.indexWhere((pack) => pack.id == current);
    setState(() {
      _looksIndex = index < 0 ? 0 : index;
      _looksMode = true;
      _looksGrid = false;
    });
  }

  void closeLooks() {
    if (!_looksMode) return;
    setState(() {
      _looksMode = false;
      _looksGrid = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeStartCoach();
    });
  }

  /// After a gift lands: show Looks for a theme, or identity for an avatar tip.
  Future<void> receiveProfileGift(PendingProfileGift gift) async {
    if (gift.openLooks && gift.world != null) {
      openLooks(focusTheme: gift.world!.themeId);
      // League tip waits until Looks is closed (see [closeLooks]).
      return;
    }
    await _ensureProfileCardFront();
    _maybeStartCoach();
  }

  void _toggleLooks() {
    if (_looksMode) {
      closeLooks();
    } else {
      openLooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            shellTopBarHeight(context),
            12,
            _looksMode ? 0 : 108,
          ),
          child: _looksMode
              ? KeyedSubtree(
                  key: _themesKey,
                  child: ThemePackCarousel(
                    key: _themesCarouselKey,
                    initialIndex: _looksIndex,
                    grid: _looksGrid,
                  ),
                )
              : StackedCardCarousel(
                  key: _carouselKey,
                  itemCount: 2,
                  peekStyle: CardPeekStyle.stack,
                  animateBackIn: true,
                  widthFactor: homeCardWidthFactor,
                  maxCardWidth: homeCardMaxWidth,
                  fitToHeight: true,
                  itemBuilder: (context, index) {
                    return index == 0
                        ? ProfileCard(
                            onToggleLooks: _toggleLooks,
                            identityKey: _identityKey,
                            walletKey: _walletKey,
                            looksKey: _looksKey,
                            leagueKey: _leagueKey,
                            coach: _coach,
                          )
                        : const ProfileSettingsBody();
                  },
                  onIndexChanged: (index) {
                    if (_frontIndex == index) return;
                    setState(() => _frontIndex = index);
                  },
                ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 124,
          child: Center(
            child: _looksMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                        onPressed: SoundService.wrapTap(() {
                          setState(() => _looksGrid = !_looksGrid);
                        }),
                        child: Icon(
                          _looksGrid
                              ? CupertinoIcons.rectangle_stack
                              : CupertinoIcons.square_grid_2x2,
                          size: 22,
                          color: theme.textPrimary,
                          semanticLabel: _looksGrid
                              ? 'Stacked view'
                              : 'Grid view',
                        ),
                      ),
                      const SizedBox(width: 20),
                      KeyedSubtree(
                        key: _doneKey,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          minimumSize: Size.zero,
                          onPressed: SoundService.wrapTap(closeLooks),
                          child: Icon(
                            CupertinoIcons.check_mark,
                            size: 22,
                            color: theme.textPrimary,
                            semanticLabel: l10n.done,
                          ),
                        ),
                      ),
                    ],
                  )
                : _SlideHint(
                    text: _frontIndex == 0
                        ? l10n.slideForSettings
                        : l10n.slideForProfile,
                  ),
          ),
        ),
        ProfileCoachOverlay(
          controller: _coach,
          onCompleted: () {
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

class _SlideHint extends StatefulWidget {
  const _SlideHint({required this.text});

  final String text;

  @override
  State<_SlideHint> createState() => _SlideHintState();
}

class _SlideHintState extends State<_SlideHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        style: theme.caption.copyWith(
          color: theme.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
