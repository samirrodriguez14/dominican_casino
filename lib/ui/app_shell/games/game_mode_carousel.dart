import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:dominican_casino/ui/widgets/stacked_card_carousel.dart';
import 'package:flutter/cupertino.dart';

/// Casino starts in the center; Speed and Tres y Dos fan out on the sides.
const gameModeCarouselModes = <GameMode>[
  GameMode.casino,
  GameMode.casinoSpeed,
  GameMode.tresydos,
];

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({
    super.key,
    this.onModeChanged,
    this.initialIndex = 0,
  });

  final ValueChanged<GameMode>? onModeChanged;
  final int initialIndex;

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  final GlobalKey _frontCardKey = GlobalKey();
  bool _howToOpen = false;
  late int _frontIndex;

  @override
  void initState() {
    super.initState();
    _frontIndex = widget.initialIndex.clamp(
      0,
      gameModeCarouselModes.length - 1,
    );
  }

  Future<void> _openHowTo(GameMode mode) async {
    if (_howToOpen) return;
    final carousel = _carouselKey.currentState;
    if (carousel == null) return;

    Rect? anchor;
    final box = _frontCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      anchor = offset & box.size;
    }

    setState(() => _howToOpen = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await showGameModeHowTo(
      context,
      mode,
      cardWidth: carousel.cardWidth,
      anchor: anchor,
    );
    if (!mounted) return;
    carousel.snapPeek(revealed: false);
    setState(() => _howToOpen = false);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _carouselKey.currentState?.revealBack();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: _howToOpen,
      child: StackedCardCarousel(
        key: _carouselKey,
        itemCount: gameModeCarouselModes.length,
        initialIndex: widget.initialIndex,
        peekStyle: CardPeekStyle.fan,
        animateBackIn: true,
        widthFactor: 0.70,
        maxCardWidth: 280,
        frontAnchorKey: _frontCardKey,
        onIndexChanged: (index) {
          if (_frontIndex != index) {
            setState(() => _frontIndex = index);
          }
          widget.onModeChanged?.call(gameModeCarouselModes[index]);
        },
        itemBuilder: (context, index) {
          final mode = gameModeCarouselModes[index];
          final isFront = index == _frontIndex;
          return GameModeCard(
            mode: mode,
            showActions: isFront,
            onHowToPlay: isFront ? () => _openHowTo(mode) : null,
          );
        },
      ),
    );
  }
}
