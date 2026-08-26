import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

/// How peeking cards sit relative to the front card.
enum CardPeekStyle {
  /// Front card plus one tilted card behind it (bottom-right).
  stack,

  /// Front card in the center with peeks on both sides.
  fan,
}

enum _FanPeekReveal {
  none,
  left,
  right,
  both,
}

/// Soft stack: front card plus a tilted peek of the next one, or a 3-card fan.
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
    this.startBackCollapsed = false,
    this.animateBackIn = false,
    this.peekStyle = CardPeekStyle.stack,
    this.alignment = Alignment.center,
    this.frontAnchorKey,
    this.wrap = true,
    this.onBlockedAdvance,
    this.maxFrontIndex,
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

  /// Peek card starts flush behind the front card.
  final bool startBackCollapsed;

  /// After layout, tilt the peek card into place with a soft card sound.
  final bool animateBackIn;

  final CardPeekStyle peekStyle;

  /// Where the card stage sits in leftover parent space.
  final Alignment alignment;

  /// Placed on the front card when it is on top, for overlay anchors.
  final GlobalKey? frontAnchorKey;

  /// When false, swiping past the first/last card springs back instead of wrapping.
  final bool wrap;

  /// Called when [wrap] is false and the user tries to advance past the last
  /// allowed front card ([maxFrontIndex] or end of list).
  final ValueChanged<int>? onBlockedAdvance;

  /// Highest index that may become the front card. Later items still peek
  /// (e.g. a locked next page) but cannot be brought forward.
  final int? maxFrontIndex;

  @override
  StackedCardCarouselState createState() => StackedCardCarouselState();
}

class _CardPose {
  const _CardPose({
    required this.offset,
    required this.scale,
    required this.angle,
    this.opacity = 1,
  });

  final Offset offset;
  final double scale;
  final double angle;
  final double opacity;

  static _CardPose lerp(_CardPose a, _CardPose b, double t) {
    return _CardPose(
      offset: Offset.lerp(a.offset, b.offset, t)!,
      scale: a.scale + (b.scale - a.scale) * t,
      angle: a.angle + (b.angle - a.angle) * t,
      opacity: a.opacity + (b.opacity - a.opacity) * t,
    );
  }

  static _CardPose arc(_CardPose a, _CardPose mid, _CardPose b, double t) {
    final u = 1 - t;
    return _CardPose(
      offset:
          a.offset * (u * u) + mid.offset * (2 * u * t) + b.offset * (t * t),
      scale: a.scale * (u * u) + mid.scale * (2 * u * t) + b.scale * (t * t),
      angle: a.angle * (u * u) + mid.angle * (2 * u * t) + b.angle * (t * t),
      opacity:
          a.opacity * (u * u) + mid.opacity * (2 * u * t) + b.opacity * (t * t),
    );
  }
}

class StackedCardCarouselState extends State<StackedCardCarousel>
    with TickerProviderStateMixin {
  late int _frontIndex;
  double _dragDx = 0;
  bool _dragging = false;
  bool _restacking = false;
  bool _dismissToLeft = true;
  double _cardWidth = 0;
  _FanPeekReveal _fanPeekReveal = _FanPeekReveal.none;

  late final AnimationController _anim;
  late final AnimationController _reveal;

  static const _dismissThreshold = 110.0;
  static const _revealDuration = Duration(milliseconds: 400);
  static const fanPeek = 0.18;
  static const fanScale = 0.90;
  static const fanAngle = 0.12;
  static const fanLift = 14.0;

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
    final maxFront = widget.maxFrontIndex;
    if (maxFront != null && _frontIndex > maxFront) {
      _frontIndex = maxFront.clamp(0, widget.itemCount - 1);
    }
    _anim = AnimationController.unbounded(vsync: this);
    final startCollapsed = widget.startBackCollapsed || widget.animateBackIn;
    _fanPeekReveal =
        startCollapsed ? _FanPeekReveal.both : _FanPeekReveal.none;
    _reveal =
        AnimationController(
          vsync: this,
          duration: _revealDuration,
          value: startCollapsed ? 0 : 1,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itemCount == 0) return;
      widget.onIndexChanged?.call(_frontIndex);
      if (widget.animateBackIn) {
        revealBack();
      }
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
    _reveal.dispose();
    super.dispose();
  }

  /// Last laid-out front card width, for overlays that match the carousel.
  double get cardWidth => _cardWidth;

  int get frontIndex => _frontIndex;

  bool get _canRestack => widget.itemCount > 1;

  int get _maxFront {
    final cap = widget.maxFrontIndex;
    if (cap == null) return widget.itemCount - 1;
    return cap.clamp(0, widget.itemCount - 1);
  }

  bool get _atMaxFront => _frontIndex >= _maxFront;

  bool get _usesFan =>
      widget.peekStyle == CardPeekStyle.fan && widget.itemCount >= 2;

  _CardPose get _peekPose =>
      _CardPose.lerp(_frontRest, _backRest, _reveal.value);

  _CardPose _leftRest(double cardWidth) => _CardPose(
    offset: Offset(-cardWidth * fanPeek, fanLift),
    scale: fanScale,
    angle: -fanAngle,
  );

  _CardPose _rightRest(double cardWidth) => _CardPose(
    offset: Offset(cardWidth * fanPeek, fanLift),
    scale: fanScale,
    angle: fanAngle,
  );

  _CardPose _revealedSide(_CardPose rest) =>
      _CardPose.lerp(_frontRest, rest, _reveal.value);

  /// Fan peeks: newly appearing side tilts out from under the front card.
  _CardPose _fanRevealedSide(_CardPose rest, {required bool left}) {
    final animate = switch (_fanPeekReveal) {
      _FanPeekReveal.both => true,
      _FanPeekReveal.left => left,
      _FanPeekReveal.right => !left,
      _FanPeekReveal.none => false,
    };
    if (!animate) return rest;
    return _CardPose.lerp(_frontRest, rest, _reveal.value);
  }

  Future<void> revealBack({bool playSound = true}) async {
    if (!_canRestack || _reveal.value >= 0.99) return;
    if (playSound) {
      SoundService.instance.playLayered(GameSound.softCard);
    }
    await _reveal.animateTo(1, curve: Curves.easeOutCubic);
  }

  Future<void> collapseBack({bool playSound = true, Duration? duration}) async {
    if (_reveal.value <= 0.01) return;
    if (playSound) {
      SoundService.instance.playLayered(GameSound.softCard);
    }
    _reveal.duration = duration ?? _revealDuration;
    await _reveal.animateTo(0, curve: Curves.easeInCubic);
    _reveal.duration = _revealDuration;
  }

  void snapPeek({required bool revealed}) {
    _reveal.value = revealed ? 1 : 0;
  }

  Future<void> goToIndex(int index) async {
    if (!_canRestack || widget.itemCount == 0) return;
    final target = index.clamp(0, _maxFront);
    if (target == _frontIndex) return;
    if (_anim.isAnimating || _restacking || _reveal.isAnimating) return;
    if (!widget.wrap) {
      final toLeft = target > _frontIndex;
      while (mounted && _frontIndex != target) {
        if (_anim.isAnimating || _restacking) return;
        final nextLeft = target > _frontIndex;
        if (nextLeft != toLeft && _frontIndex != target) break;
        if (nextLeft && _atMaxFront) return;
        if (!nextLeft && _frontIndex <= 0) return;
        await _restackUnder(toLeft: nextLeft);
      }
      return;
    }
    final n = widget.itemCount;
    final forward = (target - _frontIndex + n) % n;
    final backward = (_frontIndex - target + n) % n;
    await _restackUnder(toLeft: forward <= backward);
  }

  Future<void> toggleFront() async {
    if (!_canRestack) return;
    if (!widget.wrap && _atMaxFront) {
      widget.onBlockedAdvance?.call(_frontIndex);
      return;
    }
    await goToIndex((_frontIndex + 1) % widget.itemCount);
  }

  int get _front => _frontIndex;

  int get _back {
    if (widget.wrap) return (_frontIndex + 1) % widget.itemCount;
    return (_frontIndex + 1).clamp(0, widget.itemCount - 1);
  }

  int? get _leftIndex {
    if (widget.itemCount <= 0) return null;
    if (widget.wrap) {
      return (_frontIndex - 1 + widget.itemCount) % widget.itemCount;
    }
    if (_frontIndex <= 0) return null;
    return _frontIndex - 1;
  }

  int? get _rightIndex {
    if (widget.itemCount <= 0) return null;
    if (widget.wrap) {
      return (_frontIndex + 1) % widget.itemCount;
    }
    if (_frontIndex >= widget.itemCount - 1) return null;
    return _frontIndex + 1;
  }

  void _onDragStart(DragStartDetails _) {
    if (!_canRestack ||
        _anim.isAnimating ||
        _restacking ||
        _reveal.isAnimating) {
      return;
    }
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
      if (!widget.wrap && _atMaxFront) {
        widget.onBlockedAdvance?.call(_frontIndex);
        await _springBack();
        return;
      }
      await _restackUnder(toLeft: true);
    } else if (shouldDismissRight) {
      if (!widget.wrap && _frontIndex <= 0) {
        await _springBack();
        return;
      }
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
    if (!widget.wrap) {
      if (toLeft && _atMaxFront) {
        widget.onBlockedAdvance?.call(_frontIndex);
        await _springBack();
        return;
      }
      if (!toLeft && _frontIndex <= 0) {
        await _springBack();
        return;
      }
    }

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
        final next = widget.wrap
            ? (_frontIndex + 1) % widget.itemCount
            : (_frontIndex + 1).clamp(0, _maxFront);
        _frontIndex = next;
      } else {
        _frontIndex = widget.wrap
            ? (_frontIndex - 1 + widget.itemCount) % widget.itemCount
            : (_frontIndex - 1).clamp(0, widget.itemCount - 1);
      }
      _dragDx = 0;
      _restacking = false;
      _anim.value = 0;
      if (_usesFan) {
        // New far-side peek tilts in instead of popping at full angle.
        _fanPeekReveal =
            toLeft ? _FanPeekReveal.right : _FanPeekReveal.left;
        _reveal.value = 0;
      } else {
        _reveal.value = 1;
      }
    });
    widget.onIndexChanged?.call(_frontIndex);
    if (_usesFan) {
      await revealBack(playSound: false);
      if (!mounted) return;
      setState(() => _fanPeekReveal = _FanPeekReveal.none);
    }
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
    return _CardPose.lerp(_peekPose, _frontRest, progress * 0.35);
  }

  _CardPose _sideTowardFront(_CardPose rest) {
    final progress = (_dragDx.abs() / _dismissThreshold).clamp(0.0, 1.0);
    return _CardPose.lerp(_revealedSide(rest), _frontRest, progress * 0.35);
  }

  _CardPose _sideReceding(
    _CardPose rest,
    double cardWidth, {
    required bool left,
  }) {
    final progress = (_dragDx.abs() / _dismissThreshold).clamp(0.0, 1.0);
    final recede = _CardPose(
      offset: Offset(
        rest.offset.dx + (left ? -1 : 1) * cardWidth * 0.06,
        rest.offset.dy + 4,
      ),
      scale: rest.scale * 0.97,
      angle: rest.angle * 1.12,
    );
    return _CardPose.lerp(_revealedSide(rest), recede, progress * 0.5);
  }

  (_CardPose front, _CardPose back, bool dismissedUnder) _stackRestackPoses(
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

  _CardPose _exitEnd(_CardPose rest, double cardWidth, {required bool left}) {
    return _CardPose(
      offset: Offset(
        rest.offset.dx + (left ? -1 : 1) * cardWidth * 0.28,
        rest.offset.dy + 10,
      ),
      scale: rest.scale * 0.86,
      angle: rest.angle * 1.25,
      opacity: 0,
    );
  }

  _CardPose _withOpacity(_CardPose pose, double opacity) {
    return _CardPose(
      offset: pose.offset,
      scale: pose.scale,
      angle: pose.angle,
      opacity: opacity.clamp(0.0, 1.0),
    );
  }

  ({
    _CardPose left,
    _CardPose front,
    _CardPose right,
    _CardPose exit,
    bool dismissedUnder,
  })
  _fanRestackPoses(double cardWidth) {
    final t = _anim.value.clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final start = _frontPoseWhileDragging();
    final leftRest = _leftRest(cardWidth);
    final rightRest = _rightRest(cardWidth);
    // Dragging the front to the right covers the right peek — hide it fast
    // so the left card reads as the one directly behind center.
    final exitOut = Curves.easeInCubic.transform(
      (t / (_dismissToLeft ? 0.70 : 0.28)).clamp(0.0, 1.0),
    );

    if (_dismissToLeft) {
      final mid = _CardPose(
        offset: Offset(-cardWidth * 0.55, -18),
        scale: 0.97,
        angle: 0.28,
      );
      return (
        left: leftRest,
        front: _CardPose.arc(start, mid, leftRest, t),
        right: _CardPose.lerp(_sideTowardFront(rightRest), _frontRest, eased),
        exit: _CardPose.lerp(
          _sideReceding(leftRest, cardWidth, left: true),
          _exitEnd(leftRest, cardWidth, left: true),
          exitOut,
        ),
        dismissedUnder: t > 0.48,
      );
    }

    final mid = _CardPose(
      offset: Offset(cardWidth * 0.55, -18),
      scale: 0.97,
      angle: -0.28,
    );
    return (
      left: _CardPose.lerp(_sideTowardFront(leftRest), _frontRest, eased),
      front: _CardPose.arc(start, mid, rightRest, t),
      right: rightRest,
      exit: _CardPose.lerp(
        _sideReceding(rightRest, cardWidth, left: false),
        _exitEnd(rightRest, cardWidth, left: false),
        exitOut,
      ),
      dismissedUnder: t > 0.48,
    );
  }

  Widget _posedCard({
    Key? key,
    required int index,
    required _CardPose pose,
    required double cardWidth,
    required bool interactive,
    VoidCallback? onPeekTap,
    GlobalKey? anchorKey,
  }) {
    if (pose.opacity <= 0.01) return const SizedBox.shrink();
    return IgnorePointer(
      key: key,
      ignoring: !interactive && onPeekTap == null,
      child: Opacity(
        opacity: pose.opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: pose.offset,
          child: Transform.rotate(
            angle: pose.angle,
            child: Transform.scale(
              scale: pose.scale,
              child: SizedBox(
                key: anchorKey,
                width: cardWidth,
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: !interactive,
                      child: widget.itemBuilder(context, index),
                    ),
                    if (!interactive && onPeekTap != null)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onPeekTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _cardWidthFor(BoxConstraints constraints) {
    final fromWidth = (constraints.maxWidth * widget.widthFactor).clamp(
      180.0,
      widget.maxCardWidth,
    );
    var width = fromWidth;
    if (_usesFan) {
      final maxForPeek = (constraints.maxWidth / 1.38).clamp(
        180.0,
        widget.maxCardWidth,
      );
      if (width > maxForPeek) width = maxForPeek;
    }
    if (!widget.fitToHeight) return width;
    final fromHeight = (constraints.maxHeight - 36) * (2.5 / 3.5);
    if (fromHeight.isFinite && fromHeight > 0) {
      return width < fromHeight ? width : fromHeight;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _cardWidthFor(constraints);
        _cardWidth = cardWidth;
        if (widget.itemCount == 0) {
          return SizedBox(
            width: cardWidth + 48,
            height: cardWidth * (3.5 / 2.5) + 36,
          );
        }

        final children = _usesFan
            ? _fanChildren(cardWidth)
            : _stackChildren(cardWidth);

        final wantedWidth = _usesFan
            ? cardWidth * (1 + fanPeek * 2) + 24
            : cardWidth + 48;
        final stageWidth = constraints.maxWidth.isFinite
            ? wantedWidth.clamp(0.0, constraints.maxWidth)
            : wantedWidth;
        final stageHeight = cardWidth * (3.5 / 2.5) + 36;

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Align(
            alignment: widget.alignment,
            child: SizedBox(
              width: stageWidth,
              height: stageHeight,
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

  List<Widget> _stackChildren(double cardWidth) {
    late final _CardPose frontPose;
    late final _CardPose backPose;
    late final bool dismissedUnder;

    if (_restacking) {
      final poses = _stackRestackPoses(cardWidth);
      frontPose = poses.$1;
      backPose = poses.$2;
      dismissedUnder = poses.$3;
    } else {
      frontPose = _frontPoseWhileDragging();
      backPose = _backPoseWhileDragging();
      dismissedUnder = false;
    }

    final int? underIndex = widget.wrap
        ? (widget.itemCount > 1 ? _back : null)
        : _rightIndex;

    final showUnder =
        underIndex != null &&
        (_restacking ||
            _dragging ||
            _dragDx.abs() > 0.5 ||
            _reveal.value > 0.001);

    final frontOnTop = !(showUnder && dismissedUnder);
    final under = underIndex;
    return [
      if (showUnder && under != null)
        _posedCard(
          index: dismissedUnder ? _front : under,
          pose: dismissedUnder ? frontPose : backPose,
          cardWidth: cardWidth,
          interactive: false,
          onPeekTap: !_restacking
              ? () {
                  if (under > _maxFront) {
                    widget.onBlockedAdvance?.call(_frontIndex);
                  } else {
                    _restackUnder(toLeft: true);
                  }
                }
              : null,
        ),
      _posedCard(
        index: frontOnTop || under == null ? _front : under,
        pose: frontOnTop || under == null ? frontPose : backPose,
        cardWidth: cardWidth,
        interactive: !_restacking && (frontOnTop || under == null),
        anchorKey: (frontOnTop || under == null) && !_restacking
            ? widget.frontAnchorKey
            : null,
      ),
    ];
  }

  List<Widget> _fanChildren(double cardWidth) {
    final leftRest = _leftRest(cardWidth);
    final rightRest = _rightRest(cardWidth);
    final peekTap = !_restacking && _canRestack;

    if (_restacking) {
      final poses = _fanRestackPoses(cardWidth);
      final incomingIndex = _dismissToLeft ? _rightIndex : _leftIndex;
      final incomingPose = _dismissToLeft ? poses.right : poses.left;

      final movingFront = _posedCard(
        index: _front,
        pose: poses.front,
        cardWidth: cardWidth,
        interactive: false,
      );

      // Only animate front ↔ neighbor. The far-side peek tilts in after
      // restack via [_fanPeekReveal] — don't preview enter here (with 4+
      // items that used to flash the exiting wrap card as the "next" peek).
      final incoming = incomingIndex == null
          ? null
          : _posedCard(
              index: incomingIndex,
              pose: incomingPose,
              cardWidth: cardWidth,
              interactive: false,
              anchorKey:
                  poses.dismissedUnder ? widget.frontAnchorKey : null,
            );
      final fadeIdx = _dismissToLeft ? _leftIndex : _rightIndex;
      final fadeCard = fadeIdx == null
          ? null
          : _posedCard(
              key: ValueKey('fade-$fadeIdx'),
              index: fadeIdx,
              pose: poses.exit,
              cardWidth: cardWidth,
              interactive: false,
            );
      if (poses.dismissedUnder) {
        return [?fadeCard, movingFront, ?incoming];
      }
      return [?fadeCard, ?incoming, movingFront];
    }

    late final _CardPose leftPose;
    late final _CardPose frontPose;
    late final _CardPose rightPose;

    if (_dragging || _dragDx.abs() > 0.5) {
      frontPose = _frontPoseWhileDragging();
      if (_dragDx < 0) {
        rightPose = _sideTowardFront(rightRest);
        leftPose = _sideReceding(leftRest, cardWidth, left: true);
      } else {
        leftPose = _sideTowardFront(leftRest);
        final recede = _sideReceding(rightRest, cardWidth, left: false);
        final cover = (_dragDx / (cardWidth * fanPeek + 10)).clamp(0.0, 1.0);
        rightPose = _withOpacity(recede, 1.0 - Curves.easeIn.transform(cover));
      }
    } else {
      frontPose = _frontRest;
      leftPose = _fanRevealedSide(leftRest, left: true);
      rightPose = _fanRevealedSide(rightRest, left: false);
    }

    final leftIdx = _leftIndex;
    final rightIdx = _rightIndex;

    final leftCard = leftIdx == null
        ? null
        : _posedCard(
            index: leftIdx,
            pose: leftPose,
            cardWidth: cardWidth,
            interactive: false,
            onPeekTap: peekTap ? () => _restackUnder(toLeft: false) : null,
          );
    final rightCard = rightIdx == null
        ? null
        : _posedCard(
            index: rightIdx,
            pose: rightPose,
            cardWidth: cardWidth,
            interactive: false,
            onPeekTap: peekTap
                ? () {
                    if (rightIdx > _maxFront) {
                      widget.onBlockedAdvance?.call(_frontIndex);
                    } else {
                      _restackUnder(toLeft: true);
                    }
                  }
                : null,
          );
    final frontCard = _posedCard(
      index: _front,
      pose: frontPose,
      cardWidth: cardWidth,
      interactive: !_restacking,
      anchorKey: widget.frontAnchorKey,
    );

    // While dragging right, keep the left peek above the (fading) right peek.
    if (_dragDx > 0) {
      return [
        ?rightCard,
        ?leftCard,
        frontCard,
      ];
    }
    return [
      ?leftCard,
      ?rightCard,
      frontCard,
    ];
  }
}
