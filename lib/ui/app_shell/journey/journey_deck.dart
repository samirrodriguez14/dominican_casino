import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_motion.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Stack pose for the Journey deck (peek and enter share the same object).
class JourneyDeckLayout {
  /// [fan] ~0.4 tight peek; ~1.4 opened fan before traveling to center.
  static Offset stackOffset(int visualFromBottom, int count, {double fan = 1}) {
    final f = fan.clamp(0.2, 1.8);
    return Offset(visualFromBottom * 1.35 * f, -visualFromBottom * 1.05 * f);
  }

  static double stackAngle(int visualFromBottom, int count, {double fan = 1}) {
    if (count <= 1) return 0;
    final f = fan.clamp(0.2, 1.8);
    return (visualFromBottom - (count - 1) / 2) * 0.01 * f;
  }
}

/// Live Journey deck: peek → reverse-gather enter, and close gather (exit left → peek in).
class JourneyLiveDeck extends StatelessWidget {
  const JourneyLiveDeck({
    super.key,
    required this.dealPlan,
    required this.deckArrive,
    required this.pileDeal,
    required this.defeatedDeal,
    required this.stageSize,
    required this.pileTargets,
    required this.defeatedTargets,
    required this.pileCardSize,
    this.peekDealPlan,
    this.deckFan = 0.4,
    this.cardGather = 0,
    this.onTap,
    this.onPressStart,
    this.showLabel = true,
  });

  final List<JourneyDealSlot> dealPlan;
  /// Bottom-left peek stack; defaults to [dealPlan], may include placeholders.
  final List<JourneyDealSlot>? peekDealPlan;
  final double deckArrive;
  final double deckFan;
  final double pileDeal;
  final double defeatedDeal;
  final double cardGather;
  final Size stageSize;
  final List<Offset> pileTargets;
  final List<Offset> defeatedTargets;
  final double pileCardSize;
  final VoidCallback? onTap;
  final VoidCallback? onPressStart;
  final bool showLabel;

  List<JourneyDealSlot> get _peekPlan =>
      peekDealPlan ?? JourneyDealPlan.ensurePeekCards(dealPlan);

  static const peekWidth = 78.0;
  static const peekOverflow = 34.0;
  static const peekBottom = 6.0;

  static double peekHeight() => peekWidth / homeCardAspect;

  static Offset peekCenter(Size stage) => Offset(
        -peekOverflow + peekWidth * 0.5,
        stage.height - peekBottom - peekHeight() * 0.5,
      );

  // ── Enter / leave flight indexing ─────────────────────────────────────────

  double _dealFlightAt(int planIndex) {
    final slot = dealPlan[planIndex];
    if (slot.toDefeated) {
      return JourneyDealPlan.defeatedFlight(
        dealPlan,
        defeatedDeal,
        _countBefore(planIndex, toDefeated: true),
      );
    }
    return JourneyDealPlan.challengerFlight(
      dealPlan,
      pileDeal,
      _countBefore(planIndex, toDefeated: false),
    );
  }

  int _countBefore(int planIndex, {required bool toDefeated}) {
    var n = 0;
    for (var i = 0; i < planIndex; i++) {
      if (dealPlan[i].toDefeated == toDefeated) n++;
    }
    return n;
  }

  Offset _homeFor(JourneyDealSlot slot) {
    final wi = JourneyWorld.values.indexOf(slot.world);
    return slot.toDefeated ? defeatedTargets[wi] : pileTargets[wi];
  }

  Offset _offLeftFor(JourneyDealSlot slot) =>
      Offset(-pileCardSize * 1.35, _homeFor(slot).dy);

  // ── Gather (close): pile exit → whole peek in ─────────────────────────────

  int _pileGatherOrder(JourneyDealSlot slot) {
    final wi = JourneyWorld.values.indexOf(slot.world);
    return slot.toDefeated ? wi : (JourneyWorld.values.length + wi);
  }

  List<int> _pileGatherSequence() {
    final seen = <int>{};
    final seq = <int>[];
    for (final slot in dealPlan) {
      final id = _pileGatherOrder(slot);
      if (seen.add(id)) seq.add(id);
    }
    seq.sort();
    return seq;
  }

  double _pilePhaseFlight(int planIndex, double phase) {
    if (phase <= 0) return 0;
    if (phase >= 1) return 1;
    final seq = _pileGatherSequence();
    final pileCount = seq.length;
    if (pileCount == 0) return phase;

    final pileIndex = seq.indexOf(_pileGatherOrder(dealPlan[planIndex]));
    const flightLen = 0.32;
    final startSpan = (1.0 - flightLen).clamp(0.05, 1.0);
    final start =
        pileCount == 1 ? 0.0 : pileIndex * (startSpan / (pileCount - 1));
    final end = (start + flightLen).clamp(0.0, 1.0);
    if (phase <= start) return 0;
    if (phase >= end) return 1;
    return ((phase - start) / (end - start)).clamp(0.0, 1.0);
  }

  double get _exitPhase => (cardGather / 0.58).clamp(0.0, 1.0);

  double get _peekInPhase => cardGather < 0.62
      ? 0.0
      : ((cardGather - 0.62) / 0.38).clamp(0.0, 1.0);

  double _exitFlightAt(int planIndex) =>
      _pilePhaseFlight(planIndex, _exitPhase);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (cardGather > 0.001) return _buildGather();
    return _buildEnter();
  }

  Widget _buildGather() {
    final peek = peekCenter(stageSize);
    final n = dealPlan.length;
    final peekPlan = _peekPlan;
    final peekN = peekPlan.length;

    final waiting = <int>[
      for (var j = 0; j < n; j++)
        if (_exitFlightAt(j) <= 0.001 && _peekInPhase <= 0) j,
    ];
    final exiting = <int>[
      for (var j = 0; j < n; j++)
        if (_exitFlightAt(j) > 0.001 && _exitFlightAt(j) < 0.98) j,
    ];

    final peekIn = Curves.easeOutCubic.transform(_peekInPhase);
    final offLeft = Offset(-peekWidth * 1.5, peek.dy);
    final deckOrigin = Offset.lerp(offLeft, peek, peekIn)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final i in waiting) _waitingAtHome(i),
        for (final i in exiting)
          _FlightCard(
            slot: dealPlan[i],
            flight: _exitFlightAt(i),
            from: _homeFor(dealPlan[i]),
            to: Offset(-pileCardSize * 1.35, _homeFor(dealPlan[i]).dy),
            fromSize: pileCardSize * (1.0 - 0.03 * dealPlan[i].depthInPile),
            toSize: pileCardSize * 0.72,
            angleSeed: i,
            arcLift: 18,
            easeOut: false,
          ),
        if (peekIn > 0.01 && peekN > 0)
          Opacity(
            opacity: peekIn.clamp(0.0, 1.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = peekN - 1; i >= 0; i--)
                  _restingPeekCard(
                    slot: peekPlan[i],
                    visualFromBottom: peekN - 1 - i,
                    count: peekN,
                    deckOrigin: deckOrigin,
                    deckCardSize: peekWidth,
                    topMost: i == 0,
                    fan: 0.42,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _waitingAtHome(int planIndex) {
    final slot = dealPlan[planIndex];
    final home = _homeFor(slot);
    final size = pileCardSize * (1.0 - 0.03 * slot.depthInPile);
    final height = size / homeCardAspect;
    return Positioned(
      left: home.dx - size / 2 + slot.depthInPile * 2.2,
      top: home.dy - height / 2 + slot.depthInPile * 1.8,
      width: size,
      height: height,
      child: _faceFor(slot, radius: 12, showSuit: false, shadow: false),
    );
  }

  /// Open: peek slides off left, then pile groups fly in from off-left (leave reverse).
  Widget _buildEnter() {
    final peek = peekCenter(stageSize);
    final n = dealPlan.length;
    final peekPlan = _peekPlan;
    final peekN = peekPlan.length;
    final peekOut = Curves.easeInCubic.transform(deckArrive.clamp(0.0, 1.0));
    final offLeftPeek = Offset(-peekWidth * 1.5, peek.dy);
    // Keep the stack anchored at bottom-left until it exits left.
    final deckOrigin = Offset.lerp(peek, offLeftPeek, peekOut)!;

    final inFlight = <int>[
      for (var j = 0; j < n; j++)
        if (_dealFlightAt(j) > 0.001 && _dealFlightAt(j) < 0.98) j,
    ];

    final showPeek = peekN > 0 && peekOut < 0.99 && pileDeal < 0.08;
    final peekInteractive =
        onTap != null && deckArrive < 0.08 && pileDeal < 0.02;
    final peekH = peekHeight();
    final hitW = peekWidth + 20;
    final hitH = peekH + 20;

    final resting = <Widget>[
      for (var i = peekN - 1; i >= 0; i--)
        _restingPeekCard(
          slot: peekPlan[i],
          visualFromBottom: peekN - 1 - i,
          count: peekN,
          deckOrigin: Offset(hitW / 2, hitH / 2),
          deckCardSize: peekWidth,
          topMost: i == 0,
          fan: deckFan,
        ),
    ];

    // Positioned must stay a direct Stack child (Opacity cannot wrap it).
    final peekStack = Stack(clipBehavior: Clip.none, children: resting);
    final peekChild = peekInteractive
        ? _PeekTapTarget(
            width: hitW,
            height: hitH,
            onPressStart: onPressStart,
            onTap: onTap!,
            child: peekStack,
          )
        : SizedBox(width: hitW, height: hitH, child: peekStack);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showPeek)
          Positioned(
            left: deckOrigin.dx - hitW / 2,
            top: deckOrigin.dy - hitH / 2,
            child: Opacity(
              opacity: (1.0 - peekOut * 0.35).clamp(0.0, 1.0),
              child: peekChild,
            ),
          ),
        if (showLabel && peekInteractive)
          Positioned(
            left: peek.dx - peekWidth / 2,
            top: peek.dy - peekHeight() / 2,
            width: peekWidth,
            height: peekHeight(),
            child: const IgnorePointer(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 2, bottom: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xCC000000),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Journey',
                        style: TextStyle(
                          color: Color(0xF0FFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        for (final i in inFlight)
          _FlightCard(
            slot: dealPlan[i],
            flight: _dealFlightAt(i),
            from: _offLeftFor(dealPlan[i]),
            to: _homeFor(dealPlan[i]),
            fromSize: pileCardSize * 0.72,
            toSize: pileCardSize * (1.0 - 0.03 * dealPlan[i].depthInPile),
            angleSeed: i,
            arcLift: 18,
            easeOut: true,
          ),
      ],
    );
  }

  Widget _restingPeekCard({
    required JourneyDealSlot slot,
    required int visualFromBottom,
    required int count,
    required Offset deckOrigin,
    required double deckCardSize,
    required bool topMost,
    required double fan,
  }) {
    final offset = JourneyDeckLayout.stackOffset(
      visualFromBottom,
      count,
      fan: fan,
    );
    final angle = JourneyDeckLayout.stackAngle(
      visualFromBottom,
      count,
      fan: fan,
    );
    final pos = deckOrigin + offset;
    final height = deckCardSize / homeCardAspect;

    return Positioned(
      left: pos.dx - deckCardSize / 2,
      top: pos.dy - height / 2,
      width: deckCardSize,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: _faceFor(
          slot,
          radius: 12,
          showSuit: topMost,
          shadow: topMost,
        ),
      ),
    );
  }

  Widget _faceFor(
    JourneyDealSlot slot, {
    required double radius,
    required bool showSuit,
    required bool shadow,
  }) {
    if (slot.toDefeated && slot.card != null) {
      return JourneyFaceUpCard(
        assetPath: slot.card!.avatarAssetPath,
        world: slot.world,
        radius: radius,
      );
    }
    return JourneyFaceDownCard(
      world: slot.world,
      radius: radius,
      showSuit: showSuit,
      shadow: shadow,
    );
  }
}

/// Subtle press-in + haptic; sized hit target so the peek feels tappable.
class _PeekTapTarget extends StatefulWidget {
  const _PeekTapTarget({
    required this.width,
    required this.height,
    required this.onTap,
    required this.child,
    this.onPressStart,
  });

  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onPressStart;
  final Widget child;

  @override
  State<_PeekTapTarget> createState() => _PeekTapTargetState();
}

class _PeekTapTargetState extends State<_PeekTapTarget> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        AppHaptics.selectionClick();
        _setPressed(true);
        widget.onPressStart?.call();
      },
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedScale(
          scale: _pressed ? 0.968 : 1.0,
          duration: Duration(milliseconds: _pressed ? 70 : 180),
          curve: _pressed ? Curves.easeOut : Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, 0.02) : Offset.zero,
            duration: Duration(milliseconds: _pressed ? 70 : 180),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Shared bezier flight used by reverse-gather enter and gather-exit.
class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.slot,
    required this.flight,
    required this.from,
    required this.to,
    required this.fromSize,
    required this.toSize,
    required this.angleSeed,
    required this.arcLift,
    required this.easeOut,
  });

  final JourneyDealSlot slot;
  final double flight;
  final Offset from;
  final Offset to;
  final double fromSize;
  final double toSize;
  final int angleSeed;
  final double arcLift;
  final bool easeOut;

  @override
  Widget build(BuildContext context) {
    final t = (easeOut ? Curves.easeOutCubic : Curves.easeInOutCubic)
        .transform(flight);
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy < to.dy ? from.dy : to.dy) - arcLift,
    );
    final pos = JourneyTableLayout.quad(from, mid, to, t);
    final size = fromSize + (toSize - fromSize) * t;
    final height = size / homeCardAspect;
    final angle = easeOut
        ? (-0.08 + (angleSeed % 4) * 0.03) * (1 - t)
        : (0.06 - (angleSeed % 4) * 0.02) * (1 - t);

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - height / 2,
      width: size,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: slot.toDefeated && slot.card != null
            ? JourneyFaceUpCard(
                assetPath: slot.card!.avatarAssetPath,
                world: slot.world,
                radius: 12,
              )
            : JourneyFaceDownCard(world: slot.world, radius: 12),
      ),
    );
  }
}
