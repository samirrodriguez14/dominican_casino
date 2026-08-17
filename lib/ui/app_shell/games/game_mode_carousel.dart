import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

/// Casino starts on top; Tres y Dos sits stacked underneath.
const gameModeCarouselModes = <GameMode>[GameMode.casino, GameMode.tresydos];

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

class _CardPose {
  const _CardPose({
    required this.offset,
    required this.scale,
    required this.angle,
  });

  final Offset offset;
  final double scale;
  final double angle;

  static _CardPose lerp(_CardPose a, _CardPose b, double t) {
    return _CardPose(
      offset: Offset.lerp(a.offset, b.offset, t)!,
      scale: a.scale + (b.scale - a.scale) * t,
      angle: a.angle + (b.angle - a.angle) * t,
    );
  }

  /// Quadratic arc so the card sweeps out, then slides back under.
  static _CardPose arc(_CardPose a, _CardPose mid, _CardPose b, double t) {
    final u = 1 - t;
    return _CardPose(
      offset:
          a.offset * (u * u) + mid.offset * (2 * u * t) + b.offset * (t * t),
      scale: a.scale * (u * u) + mid.scale * (2 * u * t) + b.scale * (t * t),
      angle: a.angle * (u * u) + mid.angle * (2 * u * t) + b.angle * (t * t),
    );
  }
}

class _GameModeCarouselState extends State<GameModeCarousel>
    with TickerProviderStateMixin {
  late int _frontIndex;
  double _dragDx = 0;
  bool _dragging = false;
  bool _restacking = false;
  bool _dismissToLeft = true;
  bool _howToOpen = false;

  late final AnimationController _anim;
  late final AnimationController _reveal;
  final GlobalKey _frontCardKey = GlobalKey();

  static const _dismissThreshold = 110.0;
  static const _revealDuration = Duration(milliseconds: 400);

  /// Peek pose for the under-card — offset + tilt so the next game is visible.
  static const _backRest = _CardPose(
    offset: Offset(22, 16),
    scale: 0.94,
    angle: 0.12, // ~7°
  );
  static const _frontRest = _CardPose(offset: Offset.zero, scale: 1, angle: 0);

  @override
  void initState() {
    super.initState();
    _frontIndex = widget.initialIndex.clamp(
      0,
      gameModeCarouselModes.length - 1,
    );
    _anim = AnimationController.unbounded(vsync: this);
    _reveal =
        AnimationController(vsync: this, duration: _revealDuration, value: 0)
          ..addListener(() {
            if (mounted) setState(() {});
          });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onModeChanged?.call(gameModeCarouselModes[_frontIndex]);
      _revealBack();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _reveal.dispose();
    super.dispose();
  }

  _CardPose get _peekPose =>
      _CardPose.lerp(_frontRest, _backRest, _reveal.value);

  Future<void> _revealBack() async {
    if (!mounted || _reveal.value >= 0.99) return;
    SoundService.instance.playLayered(GameSound.softCard);
    await _reveal.animateTo(1, curve: Curves.easeOutCubic);
  }

  GameMode get _frontMode => gameModeCarouselModes[_frontIndex];
  GameMode get _backMode =>
      gameModeCarouselModes[(_frontIndex + 1) % gameModeCarouselModes.length];

  void _onDragStart(DragStartDetails _) {
    if (_howToOpen || _anim.isAnimating || _restacking || _reveal.isAnimating) {
      return;
    }
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _howToOpen || _anim.isAnimating || _restacking) return;
    setState(() => _dragDx += details.delta.dx);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!_dragging) return;
    _dragging = false;

    final vx = details.velocity.pixelsPerSecond.dx;
    final shouldDismissLeft = _dragDx < -_dismissThreshold || vx < -800;
    final shouldDismissRight = _dragDx > _dismissThreshold || vx > 800;

    if (shouldDismissLeft) {
      await _restackUnder(toLeft: true);
    } else if (shouldDismissRight) {
      await _restackUnder(toLeft: false);
    } else {
      await _springBack();
    }
  }

  Future<void> _springBack() async {
    final spring = SpringDescription(mass: 1, stiffness: 180, damping: 20);
    final sim = SpringSimulation(spring, _dragDx, 0, 0);
    void tick() {
      if (!mounted) return;
      setState(() => _dragDx = _anim.value);
    }

    _anim.addListener(tick);
    await _anim.animateWith(sim);
    _anim.removeListener(tick);
    if (!mounted) return;
    setState(() => _dragDx = 0);
  }

  Future<void> _restackUnder({required bool toLeft}) async {
    SoundService.instance.playLayered(GameSound.softCard);
    _dismissToLeft = toLeft;
    _restacking = true;
    _anim.value = 0;

    void tick() {
      if (!mounted) return;
      setState(() {});
    }

    _anim.addListener(tick);
    await _anim.animateTo(
      1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
    _anim.removeListener(tick);
    if (!mounted) return;

    setState(() {
      if (toLeft) {
        _frontIndex = (_frontIndex + 1) % gameModeCarouselModes.length;
      } else {
        _frontIndex =
            (_frontIndex - 1 + gameModeCarouselModes.length) %
            gameModeCarouselModes.length;
      }
      _dragDx = 0;
      _restacking = false;
      _anim.value = 0;
      _reveal.value = 1;
    });
    widget.onModeChanged?.call(gameModeCarouselModes[_frontIndex]);
  }

  _CardPose _frontPoseWhileDragging() {
    return _CardPose(
      offset: Offset(_dragDx, _dragDx.abs() * 0.03),
      scale: 1,
      angle: (_dragDx / 650).clamp(-0.24, 0.24),
    );
  }

  /// Under-card eases toward front as the user drags, but stays tilted.
  _CardPose _backPoseWhileDragging() {
    final progress = (_dragDx.abs() / _dismissThreshold).clamp(0.0, 1.0);
    return _CardPose.lerp(_peekPose, _frontRest, progress * 0.35);
  }

  (_CardPose front, _CardPose back, bool dismissedUnder) _restackPoses(
    double cardWidth,
  ) {
    final t = _anim.value.clamp(0.0, 1.0);
    final start = _frontPoseWhileDragging();
    final side = _dismissToLeft ? -1.0 : 1.0;
    final mid = _CardPose(
      offset: Offset(side * cardWidth * 0.55, -18),
      scale: 0.97,
      angle: side * -0.28,
    );
    // End pose matches the peek under the new front card.
    final end = _backRest;
    final front = _CardPose.arc(start, mid, end, t);
    final back = _CardPose.lerp(
      _backPoseWhileDragging(),
      _frontRest,
      Curves.easeOutCubic.transform(t),
    );
    // Halfway through, the sweeping card slips under the rising one.
    return (front, back, t > 0.48);
  }

  Future<void> _openHowTo(GameMode mode, double cardWidth) async {
    if (_howToOpen || _restacking || _anim.isAnimating) return;

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
      cardWidth: cardWidth,
      anchor: anchor,
    );
    if (!mounted) return;
    _reveal.value = 0;
    setState(() => _howToOpen = false);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _revealBack();
  }

  Widget _posedCard({
    required GameMode mode,
    required _CardPose pose,
    required double cardWidth,
    required bool interactive,
    GlobalKey? anchorKey,
  }) {
    return IgnorePointer(
      ignoring: !interactive || _howToOpen,
      child: Transform.translate(
        offset: pose.offset,
        child: Transform.rotate(
          angle: pose.angle,
          child: Transform.scale(
            scale: pose.scale,
            child: SizedBox(
              key: anchorKey,
              width: cardWidth,
              child: GameModeCard(
                mode: mode,
                onHowToPlay: () => _openHowTo(mode, cardWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.78).clamp(220.0, 300.0);

        late final _CardPose frontPose;
        late final _CardPose backPose;
        late final bool dismissedUnder;

        if (_restacking) {
          final poses = _restackPoses(cardWidth);
          frontPose = poses.$1;
          backPose = poses.$2;
          dismissedUnder = poses.$3;
        } else {
          frontPose = _frontPoseWhileDragging();
          backPose = _backPoseWhileDragging();
          dismissedUnder = false;
        }

        final showUnder =
            !_howToOpen &&
            (_restacking ||
                _dragging ||
                _dragDx.abs() > 0.5 ||
                _reveal.value > 0.001);

        final under = _posedCard(
          mode: dismissedUnder ? _frontMode : _backMode,
          pose: dismissedUnder ? frontPose : backPose,
          cardWidth: cardWidth,
          interactive: false,
        );
        final over = _posedCard(
          mode: dismissedUnder ? _backMode : _frontMode,
          pose: dismissedUnder ? backPose : frontPose,
          cardWidth: cardWidth,
          interactive: !_restacking && !_howToOpen,
          anchorKey: !_restacking && !dismissedUnder ? _frontCardKey : null,
        );

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: SizedBox(
              // Room for the tilted under-card peek.
              width: cardWidth + 48,
              height: cardWidth * (3.5 / 2.5) + 36,
              child: Offstage(
                offstage: _howToOpen,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [if (showUnder) under, over],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
