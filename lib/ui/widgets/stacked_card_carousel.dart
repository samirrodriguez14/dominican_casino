import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

/// Soft stack: front card plus a tilted peek of the next one.
class StackedCardCarousel extends StatefulWidget {
  const StackedCardCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onIndexChanged,
    this.initialIndex = 0,
    this.widthFactor = 0.78,
    this.maxCardWidth = 300,
    this.fitToHeight = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onIndexChanged;
  final int initialIndex;

  /// Share of the parent width used for the front card.
  final double widthFactor;
  final double maxCardWidth;

  /// When true, also shrink to fit available height (home Privacy / How to play).
  final bool fitToHeight;

  @override
  State<StackedCardCarousel> createState() => _StackedCardCarouselState();
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

class _StackedCardCarouselState extends State<StackedCardCarousel>
    with SingleTickerProviderStateMixin {
  late int _frontIndex;
  double _dragDx = 0;
  bool _dragging = false;
  bool _restacking = false;
  bool _dismissToLeft = true;

  late final AnimationController _anim;

  static const _dismissThreshold = 110.0;

  static const _backRest = _CardPose(
    offset: Offset(22, 16),
    scale: 0.94,
    angle: 0.12,
  );
  static const _frontRest = _CardPose(offset: Offset.zero, scale: 1, angle: 0);

  @override
  void initState() {
    super.initState();
    _frontIndex = widget.itemCount == 0
        ? 0
        : widget.initialIndex.clamp(0, widget.itemCount - 1);
    _anim = AnimationController.unbounded(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itemCount == 0) return;
      widget.onIndexChanged?.call(_frontIndex);
    });
  }

  @override
  void didUpdateWidget(StackedCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount == 0) {
      _frontIndex = 0;
      return;
    }
    if (_frontIndex >= widget.itemCount) {
      _frontIndex = widget.itemCount - 1;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _canRestack => widget.itemCount > 1;

  int get _front => _frontIndex;
  int get _back => (_frontIndex + 1) % widget.itemCount;

  void _onDragStart(DragStartDetails _) {
    if (!_canRestack || _anim.isAnimating || _restacking) return;
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _anim.isAnimating || _restacking) return;
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
        _frontIndex = (_frontIndex + 1) % widget.itemCount;
      } else {
        _frontIndex = (_frontIndex - 1 + widget.itemCount) % widget.itemCount;
      }
      _dragDx = 0;
      _restacking = false;
      _anim.value = 0;
    });
    widget.onIndexChanged?.call(_frontIndex);
  }

  _CardPose _frontPoseWhileDragging() {
    return _CardPose(
      offset: Offset(_dragDx, _dragDx.abs() * 0.03),
      scale: 1,
      angle: (_dragDx / 650).clamp(-0.24, 0.24),
    );
  }

  _CardPose _backPoseWhileDragging() {
    final progress = (_dragDx.abs() / _dismissThreshold).clamp(0.0, 1.0);
    return _CardPose.lerp(_backRest, _frontRest, progress * 0.35);
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
    final front = _CardPose.arc(start, mid, _backRest, t);
    final back = _CardPose.lerp(
      _backPoseWhileDragging(),
      _frontRest,
      Curves.easeOutCubic.transform(t),
    );
    return (front, back, t > 0.48);
  }

  Widget _posedCard({
    required int index,
    required _CardPose pose,
    required double cardWidth,
    required bool interactive,
  }) {
    return IgnorePointer(
      ignoring: !interactive,
      child: Transform.translate(
        offset: pose.offset,
        child: Transform.rotate(
          angle: pose.angle,
          child: Transform.scale(
            scale: pose.scale,
            child: SizedBox(
              width: cardWidth,
              child: widget.itemBuilder(context, index),
            ),
          ),
        ),
      ),
    );
  }

  double _cardWidthFor(BoxConstraints constraints) {
    final fromWidth = (constraints.maxWidth * widget.widthFactor).clamp(
      220.0,
      widget.maxCardWidth,
    );
    if (!widget.fitToHeight) return fromWidth;
    final fromHeight = (constraints.maxHeight - 36) * (2.5 / 3.5);
    if (fromHeight.isFinite && fromHeight > 0) {
      return fromWidth < fromHeight ? fromWidth : fromHeight;
    }
    return fromWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _cardWidthFor(constraints);
        if (widget.itemCount == 0) {
          return SizedBox(
            width: cardWidth + 48,
            height: cardWidth * (3.5 / 2.5) + 36,
          );
        }

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

        final children = <Widget>[
          if (_canRestack)
            _posedCard(
              index: dismissedUnder ? _front : _back,
              pose: dismissedUnder ? frontPose : backPose,
              cardWidth: cardWidth,
              interactive: false,
            ),
          _posedCard(
            index: _canRestack && dismissedUnder ? _back : _front,
            pose: _canRestack && dismissedUnder ? backPose : frontPose,
            cardWidth: cardWidth,
            interactive: !_restacking,
          ),
        ];

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: SizedBox(
              width: cardWidth + 48,
              height: cardWidth * (3.5 / 2.5) + 36,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
