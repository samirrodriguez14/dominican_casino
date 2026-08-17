import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/profile/profile_screen.dart';
import 'package:dominican_casino/ui/app_shell/store/store_screen.dart';
import 'package:flutter/cupertino.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<StatefulWidget> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final double iconSize = 36;
    final l10n = AppLocalizations.of(context);
    return CupertinoTabScaffold(
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            if (index == 0) {
              return const StoreScreen(key: ValueKey('store-tab'));
            }
            if (index == 1) {
              return const GamesScreen(key: ValueKey('games-tab'));
            }
            if (index == 2) {
              return const ProfileScreen(key: ValueKey('profile-tab-v2'));
            }
            return const GamesScreen(key: ValueKey('games-tab'));
          },
        );
      },
      tabBar: CupertinoTabBar(
        height: 64,
        border: Border(
          top: BorderSide(
            color: AppStyle.theme.border.withValues(alpha: .5),
            width: 0.5,
          ),
        ),
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bag, size: iconSize),
            label: l10n.store,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.game_controller, size: iconSize),
            label: l10n.games,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled, size: iconSize),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
