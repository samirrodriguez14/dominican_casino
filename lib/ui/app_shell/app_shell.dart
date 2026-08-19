import 'dart:ui';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/account_setup_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_peek_card.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/games/welcome_tutorial_popup.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_screen.dart';
import 'package:dominican_casino/ui/app_shell/store/store_screen.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/ui/widgets/home_coin_celebration.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<StatefulWidget> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int currentIndex = 1;
  late final PageController _pageController;
  final _storeKey = GlobalKey<StoreScreenState>();
  final _gamesKey = GlobalKey<GamesScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  bool _offeredTutorial = false;
  HomeCoinClaim? _activeCelebration;
  String? _listeningPid;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
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
    if (repo.pendingHomeCoinClaim != null || _activeCelebration != null) {
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
    if (pending == null || _activeCelebration != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_activeCelebration != null) return;
      final claim = context.read<AppRepo>().pendingHomeCoinClaim;
      if (claim == null) return;
      setState(() => _activeCelebration = claim);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == currentIndex) {
      if (index == 0) {
        _storeKey.currentState?.scrollToTop();
      } else if (index == 1) {
        _gamesKey.currentState?.toggleGrid();
      } else if (index == 2) {
        _profileKey.currentState?.toggleProfileSettings();
      }
      return;
    }
    setState(() => currentIndex = index);
    AppHaptics.selectionClick();
    SoundService.instance.play(GameSound.deal);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
        if (tab != null) _onTabTap(tab);
      });
    }
    _maybeStartHomeCoinCelebration(appRepo);
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
                _KeepAlivePage(child: GamesScreen(key: _gamesKey)),
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
                      behavior: HitTestBehavior.opaque,
                      child: const CurrencyBar(),
                    ),
                    Expanded(
                      child: _ShellIdentity(
                        avatarId: player?.avatarId,
                        name: displayName,
                        onTap: () => _onTabTap(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CurrentGamesPeekCard()),
          if (_activeCelebration != null)
            Positioned.fill(
              child: HomeCoinCelebrationOverlay(
                key: ValueKey(_activeCelebration!.gameId),
                amount: _activeCelebration!.amount,
                onCollected: () =>
                    context.read<AppRepo>().completeHomeCoinClaim(),
                onDismissed: () {
                  if (!mounted) return;
                  setState(() => _activeCelebration = null);
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
          PlayerAvatarView(avatarId: avatarId, size: 36, showBorder: false),
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
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_FloatingTabItem> items;
  final AppTheme theme;

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
                  item: items[i],
                  selected: currentIndex == i,
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
    required this.item,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final _FloatingTabItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? theme.textPrimary : theme.muted;

    return CupertinoButton(
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
  }
}
