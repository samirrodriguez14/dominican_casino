import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_popup.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = context.read<AppRepo>().player?.id;
      if (pid != null) {
        context.read<GamesViewModel>().startListening(pid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final vm = context.watch<GamesViewModel>();
    final l10n = AppLocalizations.of(context);
    final theme = AppStyle.theme;
    final yourTurnCount = vm.yourTurnCount;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenHeight * 0.14,
                      height: screenHeight * 0.14,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppStyle.theme.appLogo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a game to Start',
                      style: theme.mutedText.copyWith(fontSize: 16),
                    ),
                    const GameModeCarousel(),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 16,
              child: CurrencyBar(),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _CurrentGamesFab(
                label: l10n.currentGames,
                badgeCount: yourTurnCount,
                onPressed: () => showCurrentGamesPopup(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentGamesFab extends StatelessWidget {
  const _CurrentGamesFab({
    required this.label,
    required this.badgeCount,
    required this.onPressed,
  });

  final String label;
  final int badgeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.square_list,
                color: theme.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
