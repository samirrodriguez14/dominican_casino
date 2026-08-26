import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_grid.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_stage.dart';
import 'package:dominican_casino/ui/app_shell/shell_insets.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({
    super.key,
    this.gamesTabKey,
    this.onGamesNavEat,
  });

  /// Anchor for shrinking the Games deck into the shell tab.
  final GlobalKey? gamesTabKey;
  final VoidCallback? onGamesNavEat;

  @override
  State<GamesScreen> createState() => GamesScreenState();
}

class _Flight {
  const _Flight({
    required this.mode,
    required this.from,
    required this.to,
    required this.fromAngle,
    required this.toAngle,
    required this.front,
  });

  final GameMode mode;

  /// Stack / fan pose (t = 0).
  final Rect from;

  /// Grid cell pose (t = 1).
  final Rect to;
  final double fromAngle;
  final double toAngle;
  final bool front;
}

class GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<GameModeCarouselState> _carouselKey = GlobalKey();
  final GlobalKey<JourneyStageState> _journeyKey = GlobalKey();
  final GlobalKey _stageKey = GlobalKey();
  final Map<GameMode, GlobalKey> _gridKeys = {
    for (final mode in gameModeCarouselModes) mode: GlobalKey(),
  };

  late final AnimationController _gridAnim;
  List<_Flight> _flights = const [];
  GameMode? _howToMode;
  TableDeck _tableDeck = TableDeck.games;

  static const _gridDuration = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    _gridAnim = AnimationController(vsync: this, duration: _gridDuration);
  }

  @override
  void dispose() {
    _gridAnim.dispose();
    super.dispose();
  }

  bool get showingGrid => _gridAnim.value > 0.5;

  bool get _showGridToggle =>
      _tableDeck == TableDeck.games && _howToMode == null;

  /// Games tab re-tap: switch between Games and Journey decks.
  Future<void> toggleTableDeck() async {
    if (_gridAnim.isAnimating) return;
    if (_howToMode != null) return;

    // Leave grid before swapping decks.
    if (showingGrid || _gridAnim.value > 0.02) {
      await toggleGrid();
      if (!mounted) return;
      if (showingGrid) return;
    }

    await _journeyKey.currentState?.toggleTableDeck();
  }

  Future<void> toggleGrid() async {
    if (_gridAnim.isAnimating) return;
    if (_carouselKey.currentState?.isBusy == true) return;
    if (_howToMode != null) return;
    if (_journeyKey.currentState?.tableDeck == TableDeck.journey) return;

    AppHaptics.selectionClick();
    SoundService.instance.playLayered(GameSound.softCard);

    final flights = _captureFlights();
    final goingToGrid = _gridAnim.value < 0.5;
    setState(() => _flights = flights);
    if (goingToGrid) {
      await _gridAnim.forward();
    } else {
      await _gridAnim.reverse();
    }
    if (mounted) setState(() => _flights = const []);
  }

  Rect? _toStage(Rect global) {
    final box = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.globalToLocal(global.topLeft);
    final bottomRight = box.globalToLocal(global.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  List<_Flight> _captureFlights() {
    final stageBox = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (stageBox == null || !stageBox.hasSize) return const [];
    final stage = stageBox.size;
    final items = gameGridItems();
    final stack = _stackRects(stage);
    if (stack.isEmpty) return const [];

    final flights = <_Flight>[];
    for (final mode in gameModeCarouselModes) {
      final pose = stack[mode];
      if (pose == null) continue;
      final index = items.indexOf(mode);
      if (index < 0) continue;
      flights.add(
        _Flight(
          mode: mode,
          from: pose.rect,
          to: _gridRectFor(mode, index, stage),
          fromAngle: pose.angle,
          toAngle: 0,
          front: pose.front,
        ),
      );
    }
    return flights;
  }

  Map<GameMode, ({Rect rect, double angle, bool front})> _stackRects(
    Size stage,
  ) {
    final result = <GameMode, ({Rect rect, double angle, bool front})>{};
    final poses = _carouselKey.currentState?.stackPoses();
    if (poses != null) {
      for (final pose in poses) {
        final rect = _toStage(pose.rect);
        if (rect == null) continue;
        result[pose.mode] = (rect: rect, angle: pose.angle, front: pose.front);
      }
    }
    if (result.length >= gameModeCarouselModes.length) return result;
    return _geometricFan(stage);
  }

  Map<GameMode, ({Rect rect, double angle, bool front})> _geometricFan(
    Size stage,
  ) {
    var cardW = (stage.width * 0.70).clamp(180.0, 280.0);
    final maxForPeek = (stage.width / 1.38).clamp(180.0, 280.0);
    if (cardW > maxForPeek) cardW = maxForPeek;
    final cardH = cardW * (3.5 / 2.5);
    final center = Offset(stage.width / 2, stage.height / 2);
    final n = gameModeCarouselModes.length;
    final front = (_carouselKey.currentState?.frontIndex ?? 0).clamp(0, n - 1);
    final left = (front - 1 + n) % n;
    final right = (front + 1) % n;
    const peek = StackedCardCarouselState.fanPeek;
    const lift = StackedCardCarouselState.fanLift;
    const scale = StackedCardCarouselState.fanScale;
    const angle = StackedCardCarouselState.fanAngle;

    Rect at(Offset c, double s) =>
        Rect.fromCenter(center: c, width: cardW * s, height: cardH * s);

    return {
      gameModeCarouselModes[left]: (
        rect: at(center + Offset(-cardW * peek, lift), scale),
        angle: -angle,
        front: false,
      ),
      gameModeCarouselModes[front]: (
        rect: at(center, 1),
        angle: 0.0,
        front: true,
      ),
      gameModeCarouselModes[right]: (
        rect: at(center + Offset(cardW * peek, lift), scale),
        angle: angle,
        front: false,
      ),
    };
  }

  Rect _gridRectFor(GameMode mode, int index, Size stage) {
    final key = _gridKeys[mode];
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final local = _toStage(box.localToGlobal(Offset.zero) & box.size);
      if (local != null) return local;
    }
    return gameGridCellRect(stage, index);
  }

  Future<void> _openHowToFromGrid(GameMode mode, Rect globalRect) async {
    if (_howToMode != null) return;
    setState(() => _howToMode = mode);
    final stage = _stageKey.currentContext?.size;
    final largeWidth = stage == null
        ? 260.0
        : (stage.width * 0.70).clamp(220.0, 280.0);
    await showGameModeHowTo(
      context,
      mode,
      cardWidth: largeWidth,
      anchor: globalRect,
      expandFromAnchor: true,
    );
    if (mounted) setState(() => _howToMode = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final repo = context.watch<AppRepo>();
    if (repo.openJourneyRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!context.read<AppRepo>().takeOpenJourneyRequest()) return;
        _journeyKey.currentState?.restoreJourneySettled();
      });
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12, shellTopBarHeight(context), 12, 108),
      child: AnimatedBuilder(
        animation: _gridAnim,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_gridAnim.value);
          final inFlight =
              _flights.isNotEmpty &&
              (_gridAnim.isAnimating || (t > 0 && t < 1));
          final hideModes = <GameMode>{
            if (inFlight)
              for (final flight in _flights) flight.mode,
            ?_howToMode,
          };
          final gridOn = t > 0.5;

          return Stack(
            key: _stageKey,
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                ignoring: t > 0.02,
                child: Opacity(
                  opacity: t == 0 ? 1 : 0,
                  child: JourneyStage(
                    key: _journeyKey,
                    carouselKey: _carouselKey,
                    showingGrid: t > 0.02,
                    gridProgress: t,
                    gamesTabKey: widget.gamesTabKey,
                    onGamesNavEat: widget.onGamesNavEat,
                    onTableDeckChanged: (deck) {
                      if (!mounted) return;
                      setState(() => _tableDeck = deck);
                    },
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: t < 0.98,
                child: GameModeGrid(
                  progress: t,
                  hideModes: hideModes,
                  cardKeys: _gridKeys,
                  onHowToPlay: _openHowToFromGrid,
                ),
              ),
              if (inFlight) ..._flightWidgets(t),
              if (_showGridToggle)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      onPressed: SoundService.wrapTap(toggleGrid),
                      child: Icon(
                        gridOn
                            ? CupertinoIcons.rectangle_stack
                            : CupertinoIcons.square_grid_2x2,
                        size: 22,
                        color: theme.textPrimary,
                        semanticLabel: gridOn ? 'Stacked view' : 'Grid view',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _flightWidgets(double t) {
    final ordered = [..._flights]
      ..sort((a, b) => (a.front ? 1 : 0).compareTo(b.front ? 1 : 0));
    return [for (final flight in ordered) _flyingCard(flight, t)];
  }

  Widget _flyingCard(_Flight flight, double t) {
    final rect = Rect.lerp(flight.from, flight.to, t)!;
    final angle = flight.fromAngle + (flight.toAngle - flight.fromAngle) * t;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: angle,
        child: GameModeCard(
          mode: flight.mode,
          compact: rect.width < 180,
          showActions: false,
        ),
      ),
    );
  }
}
