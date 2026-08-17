import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_screen.dart';
import 'package:dominican_casino/ui/app_shell/store/store_screen.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = context.read<AppRepo>().player?.id;
      if (pid != null) {
        context.read<GamesViewModel>().startListening(pid);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == currentIndex) return;
    setState(() => currentIndex = index);
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
    final yourTurnCount = context.watch<GamesViewModel>().yourTurnCount;
    context.watch<AppRepo>(); // rebuild when Sage / Walnut is selected

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _KeepAlivePage(
                  child: StoreScreen(key: ValueKey('store-tab')),
                ),
                _KeepAlivePage(
                  child: GamesScreen(key: ValueKey('games-tab')),
                ),
                _KeepAlivePage(
                  child: ProfileScreen(key: ValueKey('profile-tab-v2')),
                ),
              ],
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(theme.appLogo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const CurrencyBar(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10 + bottomInset,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _FloatingTabBar(
                    currentIndex: currentIndex,
                    onTap: _onTabTap,
                    items: [
                      _FloatingTabItem(
                        icon: CupertinoIcons.bag,
                        label: l10n.store,
                      ),
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
                Positioned(
                  right: 16,
                  child: _CurrentGamesButton(
                    badgeCount: yourTurnCount,
                    onPressed: () => showCurrentGamesPopup(context),
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

class _CurrentGamesButton extends StatelessWidget {
  const _CurrentGamesButton({
    required this.badgeCount,
    required this.onPressed,
  });

  final int badgeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: .94),
              shape: BoxShape.circle,
              border: Border.all(color: theme.border.withValues(alpha: .65)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.play_fill,
              color: theme.textPrimary,
              size: 22,
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: theme.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.border.withValues(alpha: .65)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .35),
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
              ? theme.surfaceAlt.withValues(alpha: .85)
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
