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
  GameMode.rummy,
];

class PickerCardPose {
  const PickerCardPose({
    required this.mode,
    required this.rect,
    required this.angle,
    this.front = false,
  });

  final GameMode mode;
  final Rect rect;
  final double angle;
  final bool front;
}

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({
    super.key,
    this.onModeChanged,
    this.initialIndex = 0,
  });

  final ValueChanged<GameMode>? onModeChanged;
  final int initialIndex;

  @override
  GameModeCarouselState createState() => GameModeCarouselState();
}

class GameModeCarouselState extends State<GameModeCarousel> {
  final GlobalKey<StackedCardCarouselState> _carouselKey = GlobalKey();
  final GlobalKey _frontCardKey = GlobalKey();
  bool _howToOpen = false;
  bool _collapsingForHowTo = false;
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
    if (_howToOpen || _collapsingForHowTo) return;
    final carousel = _carouselKey.currentState;
    if (carousel == null) return;

    setState(() => _collapsingForHowTo = true);
    await carousel.collapseBack(duration: const Duration(milliseconds: 320));
    if (!mounted) return;

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
    setState(() {
      _howToOpen = false;
      _collapsingForHowTo = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _carouselKey.currentState?.revealBack();
  }

  bool get isBusy => _howToOpen || _collapsingForHowTo;

  int get frontIndex => _frontIndex;

  Future<void> collapsePeeks() {
    return _carouselKey.currentState?.collapseBack(
          duration: const Duration(milliseconds: 280),
        ) ??
        Future.value();
  }

  Future<void> revealPeeks() {
    return _carouselKey.currentState?.revealBack() ?? Future.value();
  }

  /// Screen-space poses for the three fanned cards (left, front, right).
  List<PickerCardPose>? stackPoses() {
    final box = _frontCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final frontRect = box.localToGlobal(Offset.zero) & box.size;
    final w = frontRect.width;
    final n = gameModeCarouselModes.length;
    final left = (_frontIndex - 1 + n) % n;
    final right = (_frontIndex + 1) % n;

    Rect shifted(Offset offset, double scale) {
      final center = frontRect.center + offset;
      return Rect.fromCenter(
        center: center,
        width: frontRect.width * scale,
        height: frontRect.height * scale,
      );
    }

    return [
      PickerCardPose(
        mode: gameModeCarouselModes[left],
        rect: shifted(
          Offset(
            -w * StackedCardCarouselState.fanPeek,
            StackedCardCarouselState.fanLift,
          ),
          StackedCardCarouselState.fanScale,
        ),
        angle: -StackedCardCarouselState.fanAngle,
      ),
      PickerCardPose(
        mode: gameModeCarouselModes[_frontIndex],
        rect: frontRect,
        angle: 0,
        front: true,
      ),
      PickerCardPose(
        mode: gameModeCarouselModes[right],
        rect: shifted(
          Offset(
            w * StackedCardCarouselState.fanPeek,
            StackedCardCarouselState.fanLift,
          ),
          StackedCardCarouselState.fanScale,
        ),
        angle: StackedCardCarouselState.fanAngle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _howToOpen || _collapsingForHowTo,
      child: Offstage(
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
      ),
    );
  }
}
