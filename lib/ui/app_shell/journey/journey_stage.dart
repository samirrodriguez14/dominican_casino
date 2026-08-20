import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/app_shell/journey/games_peek_deck.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_peek_deck.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum TableDeck { games, journey }

/// Swaps the Games fan and Journey board on the Games table.
class JourneyStage extends StatefulWidget {
  const JourneyStage({
    super.key,
    required this.carouselKey,
    required this.showingGrid,
    required this.gridProgress,
    this.onTableDeckChanged,
  });

  final GlobalKey<GameModeCarouselState> carouselKey;
  final bool showingGrid;
  final double gridProgress;
  final ValueChanged<TableDeck>? onTableDeckChanged;

  @override
  State<JourneyStage> createState() => JourneyStageState();
}

class JourneyStageState extends State<JourneyStage>
    with SingleTickerProviderStateMixin {
  static const _swapDuration = Duration(milliseconds: 400);

  late final AnimationController _swapAnim;
  final GlobalKey<JourneyBoardState> _boardKey = GlobalKey();
  TableDeck _tableDeck = TableDeck.games;

  @override
  void initState() {
    super.initState();
    _swapAnim = AnimationController(vsync: this, duration: _swapDuration);
  }

  @override
  void dispose() {
    _swapAnim.dispose();
    super.dispose();
  }

  TableDeck get tableDeck => _tableDeck;

  Future<void> showJourney() async {
    if (_tableDeck == TableDeck.journey || _swapAnim.isAnimating) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    setState(() => _tableDeck = TableDeck.journey);
    widget.onTableDeckChanged?.call(TableDeck.journey);
    final world =
        _boardKey.currentState?.activeWorld ?? JourneyWorld.diamonds;
    await context.read<AppRepo>().unlockAndEquipPack(world.themeId);
    if (!mounted) return;
    await _swapAnim.forward(from: 0);
  }

  Future<void> showGames() async {
    if (_tableDeck == TableDeck.games || _swapAnim.isAnimating) return;
    SoundService.instance.playLayered(GameSound.softCard);
    AppHaptics.lightImpact();
    await _swapAnim.reverse(from: 1);
    if (!mounted) return;
    setState(() => _tableDeck = TableDeck.games);
    widget.onTableDeckChanged?.call(TableDeck.games);
  }

  Future<void> toggleTableDeck() async {
    if (_tableDeck == TableDeck.games) {
      await showJourney();
    } else {
      await showGames();
    }
  }

  void _onWorldThemeEquipped(JourneyWorld world) {
    // AppRepo.notifyListeners rebuilds shell chrome via AppStyle.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _swapAnim,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_swapAnim.value);
        final gamesOnTable = 1 - t;
        final journeyOnTable = t;
        final hideGamesMain = widget.showingGrid || gamesOnTable < 0.02;
        final hideJourneyMain = journeyOnTable < 0.02;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: hideGamesMain,
              child: Opacity(
                opacity: gamesOnTable,
                child: Transform.scale(
                  scale: 0.88 + gamesOnTable * 0.12,
                  alignment: Alignment.center,
                  child: GameModeCarousel(key: widget.carouselKey),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: hideJourneyMain,
              child: Opacity(
                opacity: journeyOnTable,
                child: Transform.scale(
                  scale: 0.94 + journeyOnTable * 0.06,
                  alignment: Alignment.center,
                  child: JourneyBoard(
                    key: _boardKey,
                    onWorldThemeEquipped: _onWorldThemeEquipped,
                  ),
                ),
              ),
            ),
            if (!widget.showingGrid && gamesOnTable > 0.5)
              Positioned(
                left: 0,
                bottom: 0,
                width: 96,
                child: JourneyPeekDeck(
                  progress: journeyOnTable,
                  onTap: showJourney,
                ),
              ),
            if (journeyOnTable > 0.5)
              Positioned(
                left: 0,
                top: 0,
                width: 96,
                child: GamesPeekDeck(
                  progress: gamesOnTable,
                  onTap: showGames,
                ),
              ),
          ],
        );
      },
    );
  }
}
