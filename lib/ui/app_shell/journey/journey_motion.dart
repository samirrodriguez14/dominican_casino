import 'dart:math' as math;

import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

// ── Progress + deal plan ────────────────────────────────────────────────────

/// Progress channels for opening / closing the Journey table.
class JourneyOpenProgress {
  const JourneyOpenProgress({
    this.deckArrive = 1,
    this.deckFan = 1,
    this.sectionExpand = 1,
    this.pileDeal = 1,
    this.defeatedDeal = 1,
    this.cardGather = 0,
  });

  /// Open: peek slides off left (0 at peek → 1 gone). Close: unused fade with shells.
  final double deckArrive;

  /// Stack spread while the peek is still visible (~0.4 tight → fan).
  final double deckFan;

  /// Top + defeated shells expand L→R as the table opens.
  final double sectionExpand;

  /// Challenger pile groups fly in from off-left onto top piles.
  final double pileDeal;

  /// Defeated pile groups fly in from off-left onto bottom piles (after challengers).
  final double defeatedDeal;

  /// Close-only: piles exit, then peek deck slides in (0 on table → 1 at peek).
  final double cardGather;

  static const settled = JourneyOpenProgress();
}

/// One card in the open-enter sequence (challengers first, defeated last).
class JourneyDealSlot {
  const JourneyDealSlot({
    required this.world,
    required this.toDefeated,
    this.card,
    this.depthInPile = 0,
  });

  final JourneyWorld world;
  final bool toDefeated;
  final JourneyCardDef? card;
  final int depthInPile;
}

/// Deal-order helpers shared by board, deck, and stage.
abstract final class JourneyDealPlan {
  static const worldCount = 4;
  static const cardsPerPile = 4;
  static const dealCardCount = worldCount * cardsPerPile;

  /// Challengers first, defeated last (enter order: top piles then bottom).
  static List<JourneyDealSlot> forSnapshot(JourneyDisplaySnapshot snap) {
    final challenger = <JourneyDealSlot>[];
    final defeated = <JourneyDealSlot>[];
    for (final world in JourneyWorld.values) {
      final def = snap.worldOf(world);
      // Sealed kingdoms stay empty pads — no cards fly into mystery slots.
      if (!def.unlocked) continue;
      final pile = def.pileCards;
      for (var d = 0; d < pile.length; d++) {
        challenger.add(
          JourneyDealSlot(
            world: world,
            toDefeated: false,
            card: pile[d],
            depthInPile: d,
          ),
        );
      }
      final fallen = def.defeatedRoyals;
      for (var d = 0; d < fallen.length; d++) {
        defeated.add(
          JourneyDealSlot(
            world: world,
            toDefeated: true,
            card: fallen[d],
            depthInPile: d,
          ),
        );
      }
    }
    return [...challenger, ...defeated];
  }

  /// Bottom-left peek always needs a visible stack — even before Journey starts.
  static List<JourneyDealSlot> ensurePeekCards(List<JourneyDealSlot> plan) {
    if (plan.isNotEmpty) return plan;
    return const [
      JourneyDealSlot(
        world: JourneyWorld.diamonds,
        toDefeated: false,
        depthInPile: 0,
      ),
      JourneyDealSlot(
        world: JourneyWorld.diamonds,
        toDefeated: false,
        depthInPile: 1,
      ),
      JourneyDealSlot(
        world: JourneyWorld.diamonds,
        toDefeated: false,
        depthInPile: 2,
      ),
    ];
  }

  static int challengerCount(List<JourneyDealSlot> plan) =>
      plan.where((s) => !s.toDefeated).length;

  static int defeatedCount(List<JourneyDealSlot> plan) =>
      plan.where((s) => s.toDefeated).length;

  /// Unique worlds in plan order (enum order), then reversed for enter LIFO.
  static List<JourneyWorld> pileEnterOrder(
    List<JourneyDealSlot> plan, {
    required bool toDefeated,
  }) {
    final seen = <JourneyWorld>{};
    final seq = <JourneyWorld>[];
    for (final slot in plan) {
      if (slot.toDefeated != toDefeated) continue;
      if (seen.add(slot.world)) seq.add(slot.world);
    }
    return seq.reversed.toList();
  }

  static int challengerPileCount(List<JourneyDealSlot> plan) =>
      pileEnterOrder(plan, toDefeated: false).length;

  static int defeatedPileCount(List<JourneyDealSlot> plan) =>
      pileEnterOrder(plan, toDefeated: true).length;

  /// Same stagger as leave gather: piles move as groups (flightLen 0.32).
  static double pileGroupFlight(double phase, int pileIndex, int pileCount) {
    if (phase <= 0) return 0;
    if (phase >= 1) return 1;
    if (pileCount <= 0) return phase;
    const flightLen = 0.32;
    final startSpan = (1.0 - flightLen).clamp(0.05, 1.0);
    final start =
        pileCount == 1 ? 0.0 : pileIndex * (startSpan / (pileCount - 1));
    final end = (start + flightLen).clamp(0.0, 1.0);
    if (phase <= start) return 0;
    if (phase >= end) return 1;
    return ((phase - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double _flightForWorld(
    List<JourneyDealSlot> plan,
    double phase, {
    required bool toDefeated,
    required JourneyWorld world,
  }) {
    final order = pileEnterOrder(plan, toDefeated: toDefeated);
    final pileIndex = order.indexOf(world);
    if (pileIndex < 0) return 1;
    return pileGroupFlight(phase, pileIndex, order.length);
  }

  static double challengerFlight(
    List<JourneyDealSlot> plan,
    double pileDeal,
    int challengerIndex,
  ) {
    var ci = 0;
    for (final slot in plan) {
      if (slot.toDefeated) continue;
      if (ci == challengerIndex) {
        return _flightForWorld(
          plan,
          pileDeal,
          toDefeated: false,
          world: slot.world,
        );
      }
      ci++;
    }
    return 1;
  }

  static double defeatedFlight(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    int defeatedIndex,
  ) {
    var di = 0;
    for (final slot in plan) {
      if (!slot.toDefeated) continue;
      if (di == defeatedIndex) {
        return _flightForWorld(
          plan,
          defeatedDeal,
          toDefeated: true,
          world: slot.world,
        );
      }
      di++;
    }
    return 1;
  }

  static int challengerLandedDepth(
    List<JourneyDealSlot> plan,
    double pileDeal,
    JourneyWorld world,
  ) {
    var n = 0;
    var ci = 0;
    for (final slot in plan) {
      if (slot.toDefeated) continue;
      if (slot.world == world &&
          challengerFlight(plan, pileDeal, ci) >= 0.98) {
        n++;
      }
      ci++;
    }
    return n;
  }

  static int defeatedLandedCount(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    JourneyWorld world,
  ) {
    var n = 0;
    var di = 0;
    for (final slot in plan) {
      if (!slot.toDefeated) continue;
      if (slot.world == world &&
          defeatedFlight(plan, defeatedDeal, di) >= 0.98) {
        n++;
      }
      di++;
    }
    return n;
  }
}

// ── Timeline (swap controller → channels) ───────────────────────────────────

/// Pure mapping from swap progress (+ peek fan) into open/close channels.
///
/// Keep interval numbers here so [JourneyStage] stays orchestration-only.
abstract final class JourneyTimeline {
  static const openDuration = Duration(milliseconds: 1600);
  static const closeDuration = Duration(milliseconds: 1450);
  static const peekFanDuration = Duration(milliseconds: 320);

  /// [t] is swap controller value (0 games → 1 journey).
  /// [peekFan] is the immediate tap-fan controller (0 tight → 1 open).
  static JourneyOpenProgress openProgress({
    required double t,
    required double peekFan,
    required bool closing,
  }) {
    final closeC = (1.0 - t).clamp(0.0, 1.0);
    return JourneyOpenProgress(
      deckArrive: _deckArrive(t: t, closeC: closeC, closing: closing),
      deckFan: _deckFan(t: t, peekFan: peekFan, closing: closing),
      sectionExpand: _sectionExpand(t: t, closeC: closeC, closing: closing),
      // Peek exits left first, then shells expand, then piles fly in.
      pileDeal: closing
          ? 1.0
          : const Interval(0.40, 0.72, curve: Curves.linear).transform(t),
      defeatedDeal: closing
          ? 1.0
          : const Interval(0.68, 1.0, curve: Curves.linear).transform(t),
      cardGather: closing
          ? const Interval(0.0, 0.9, curve: Curves.linear).transform(closeC)
          : 0.0,
    );
  }

  /// 0 = games on table, 1 = eaten into Games tab.
  static double gameEat({
    required double t,
    required bool closing,
  }) {
    if (closing) {
      final closeC = (1.0 - t).clamp(0.0, 1.0);
      return 1.0 -
          const Interval(0.48, 0.78, curve: Curves.easeInOutCubic)
              .transform(closeC);
    }
    return const Interval(0.0, 0.22, curve: Curves.easeInOutCubic).transform(t);
  }

  static double gameScale({
    required double eat,
    required bool closing,
  }) {
    if (closing) {
      final show = (1.0 - eat).clamp(0.0, 1.0);
      final little = 0.05 + 0.12 * show;
      final pop = Curves.easeInCubic.transform(show);
      return little + (1.0 - little) * pop;
    }
    return math.max(0.03, 1.0 - Curves.easeInCubic.transform(eat) * 0.97);
  }

  static double _deckFan({
    required double t,
    required double peekFan,
    required bool closing,
  }) {
    if (closing) return 0.42;
    final tapFan = Curves.easeOutCubic.transform(peekFan);
    // Fan on tap / early open; collapse as the peek exits left.
    final openFan =
        const Interval(0.0, 0.18, curve: Curves.easeOutCubic).transform(t);
    final hold = 1.0 -
        const Interval(0.12, 0.30, curve: Curves.easeInCubic).transform(t);
    return 0.38 + 1.1 * math.max(tapFan, openFan) * hold.clamp(0.0, 1.0);
  }

  static double _deckArrive({
    required double t,
    required double closeC,
    required bool closing,
  }) {
    if (closing) {
      return 1.0 -
          const Interval(0.0, 0.55, curve: Curves.easeInCubic).transform(closeC);
    }
    // Peek slides off left before shells expand (no travel to table center).
    return const Interval(0.0, 0.30, curve: Curves.easeInCubic).transform(t);
  }

  static double _sectionExpand({
    required double t,
    required double closeC,
    required bool closing,
  }) {
    if (closing) {
      return 1.0 -
          const Interval(0.0, 0.55, curve: Curves.easeInCubic).transform(closeC);
    }
    // After peek has mostly left.
    return const Interval(0.28, 0.48, curve: Curves.easeOutCubic).transform(t);
  }
}

// ── Table geometry ──────────────────────────────────────────────────────────

/// Shared board/deck coordinates for the Journey table.
abstract final class JourneyTableLayout {
  static double pileWidth(double stageWidth) => (stageWidth - 30) / 4;

  static double pileCardSize(double stageWidth) => pileWidth(stageWidth) * 0.88;

  static List<Offset> pileTargets(Size stage) {
    final pileW = pileWidth(stage.width);
    final pileH = pileW / homeCardAspect;
    return [
      for (var i = 0; i < 4; i++)
        Offset(15 + pileW * (i + 0.5), 8 + pileH * 0.42),
    ];
  }

  static List<Offset> defeatedTargets(Size stage) {
    final pileW = pileWidth(stage.width);
    final defeatedY = stage.height * 0.88;
    return [
      for (var i = 0; i < 4; i++) Offset(15 + pileW * (i + 0.5), defeatedY),
    ];
  }

  /// Quadratic bezier used by eat/spit and card flights.
  static Offset quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  /// Lift, then dive into the Games tab (and reverse on spit).
  static Offset gameCarouselDelta({
    required double eat,
    required Size stage,
    required Offset tabCenter,
  }) {
    final origin = Offset(stage.width / 2, stage.height / 2);
    final toTab = tabCenter - origin;
    final mid = Offset(toTab.dx * 0.28, -stage.height * 0.14);
    final t = Curves.easeInOutCubic.transform(eat);
    return quad(Offset.zero, mid, toTab, t);
  }

  /// Lift, then dive into [targetCenter] from stage center (popup eat/spit).
  static Offset flyToTargetDelta({
    required double eat,
    required Size stage,
    required Offset targetCenter,
  }) {
    final origin = Offset(stage.width / 2, stage.height / 2);
    final toTarget = targetCenter - origin;
    final mid = Offset(toTarget.dx * 0.28, -stage.height * 0.14);
    final t = Curves.easeInOutCubic.transform(eat);
    return quad(Offset.zero, mid, toTarget, t);
  }
}

/// Multi-phase bubble scale used by Games-tab / trail-avatar eat & spit pulses.
double journeyEatPulseScale(double t) {
  if (t <= 0) return 1;
  if (t < 0.32) {
    return 1.0 + Curves.easeOut.transform(t / 0.32) * 0.24;
  }
  if (t < 0.52) {
    return 1.24 - Curves.easeIn.transform((t - 0.32) / 0.20) * 0.34;
  }
  if (t < 0.78) {
    return 0.90 + Curves.easeOut.transform((t - 0.52) / 0.26) * 0.18;
  }
  return 1.08 - Curves.easeIn.transform((t - 0.78) / 0.22) * 0.08;
}
