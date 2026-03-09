import 'package:dominican_casino/ui/app_shell/games_screen.dart';
import 'package:dominican_casino/ui/app_shell/profile_screen.dart';
import 'package:dominican_casino/ui/app_shell/settings_screen.dart';
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
    final double iconSize = 50;
    return CupertinoTabScaffold(
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            if (index == 0) {
              return SettingsScreen();
            }
            if (index == 1) {
              return GamesScreen();
            }
            if (index == 2) {
              return ProfileScreen();
            }
            return GamesScreen();
          },
        );
      },

      tabBar: CupertinoTabBar(
        height: 80,
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
        },
        items: [
          BottomNavigationBarItem(
            icon: AnimatedScale(
              curve: Curves.easeOutBack,
              scale: currentIndex == 0 ? 1.3 : 1,
              duration: const Duration(milliseconds: 750),
              child: Icon(CupertinoIcons.settings, size: iconSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: AnimatedScale(
              curve: Curves.easeOutBack,

              scale: currentIndex == 1 ? 1.7 : 1.5,
              duration: const Duration(milliseconds: 750),
              child: Icon(CupertinoIcons.game_controller, size: iconSize),
            ),
          ),
          BottomNavigationBarItem(
            icon: AnimatedScale(
              curve: Curves.easeOutBack,

              scale: currentIndex == 2 ? 1.3 : 1,
              duration: const Duration(milliseconds: 750),
              child: Icon(CupertinoIcons.profile_circled, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }
}
