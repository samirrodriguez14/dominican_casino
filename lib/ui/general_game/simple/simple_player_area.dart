import 'dart:math' as math;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
import 'package:dominican_casino/ui/general_game/play_action_bar.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Player hand: tap-select plus inline actions over a centered fan.
///
/// Fan layout and drag-reorder behavior are shared across game modes.
/// Modes that hide cards elsewhere (e.g. Rummy boxes) filter via
/// [GeneralGameViewModel.myHandFanCards] but still reorder [myHandCards].
class SimplePlayerArea extends StatefulWidget {
  const SimplePlayerArea({super.key});

  @override
  State<SimplePlayerArea> createState() => _SimplePlayerAreaState();
}

class _SimplePlayerAreaState extends State<SimplePlayerArea> {
  HandFanLayout? _fanLayout;
  static const double _cardWidth = 110.0;
  static const double _fanHeight = 168.0;
  static const double _edgeAngle = 0.16;
  static const double _selectedLift = 12.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Column(
      children: [
        PlayActionBar(vm: vm),
        const SizedBox(height: 2),
        SizedBox(
          height: _fanHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fanCards = vm.myHandFanCards;
              if (fanCards.isEmpty) {
                if (vm.myHandCards.isEmpty) return const SizedBox.shrink();
                // Hand still holds cards rendered in another zone (Rummy boxes).
                return SizedBox(
                  width: constraints.maxWidth,
                  height: _fanHeight,
                  child: Center(
                    child: SizedBox(
                      key: vm.myHandKey,
                      width: constraints.maxWidth * 0.85,
                      height: 48,
                    ),
                  ),
                );
              }
              final celebrating = vm.isCelebratingHand(vm.me);
              final count = fanCards.length;
              final scale = HandFanLayout.visualScale(celebrating: celebrating);
              final layout = HandFanLayout.fit(
                count: count,
                maxWidth: constraints.maxWidth,
                preferredCardWidth: _cardWidth,
                maxGap: celebrating ? 48.0 : 40.0,
                visualScale: scale,
                lockCardSize: true,
                progressiveTighten: true,
              );
              _fanLayout = layout;
              final cardWidth = layout.cardWidth;
              final gap = layout.gap;

              final cardH = layout.cardHeight;

              final totalWidth = layout.totalWidth(count);
              final draggingId = vm.draggingSource?.id;
              final mid = (count - 1) / 2.0;
              final baseTop = _fanHeight - cardH;

              return ListenableBuilder(
                listenable: vm.motion,
                builder: (context, _) {
                  if (vm.motion.isShuffling) return const SizedBox.shrink();
                  final holdFlat =
                      fanCards.isNotEmpty &&
                      fanCards.every((c) => vm.motion.isInFlight(c.id));
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: _fanHeight,
                    child: Center(
                      child: SizedBox(
                        key: vm.myHandKey,
                        width: totalWidth,
                        height: _fanHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < count; i++)
                              _fanCard(
                                vm: vm,
                                card: fanCards[i],
                                index: i,
                                count: count,
                                mid: mid,
                                gap: gap,
                                cardWidth: cardWidth,
                                baseTop: baseTop,
                                draggingId: draggingId,
                                holdFlat: holdFlat,
                                celebrating: celebrating,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fanCard({
    required GeneralGameViewModel vm,
    required PlayingCardModel card,
    required int index,
    required int count,
    required double mid,
    required double gap,
    required double cardWidth,
    required double baseTop,
    required String? draggingId,
    required bool holdFlat,
    required bool celebrating,
  }) {
    final selected = (vm.gameState.gameMode == GameMode.bs
            ? vm.selectedCards.any((c) => c.id == card.id)
            : vm.selectedCard == card) &&
        draggingId != card.id;
    final t = count == 1 ? 0.0 : (index - mid) / mid;
    final angle = holdFlat || celebrating ? 0.0 : t * _edgeAngle;
    final arcDrop = holdFlat || celebrating ? 0.0 : t.abs() * 8;
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: draggingId == card.id
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: index * gap,
      top: baseTop + arcDrop - (selected ? _selectedLift : 0),
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        turns: (selected ? angle * 0.35 : angle) / (2 * math.pi),
        alignment: Alignment.bottomCenter,
        child: BoardDragHandle(
          source: BoardDragSource.hand(card),
          enabled: !vm.isAnimating && !vm.hasDropPending,
          feedbackWidth: cardWidth,
          tableFeedbackWidth: 72,
          onTap: () => vm.selectCard(card),
          onHandReorder: (global) {
            if (vm.hitTestDropTarget(
                  global,
                  source: BoardDragSource.hand(card),
                ) !=
                null) {
              return;
            }
            final id = vm.draggingSource?.id;
            if (id == null) return;
            final hand = vm.myHandCards;
            final from = hand.indexWhere((c) => c.id == id);
            if (from < 0) return;
            final fan = vm.myHandFanCards;
            if (!fan.any((c) => c.id == id)) return;
            final toFan = _indexForGlobalCenter(global, fan.length);
            if (toFan < 0 || toFan >= fan.length) return;
            final toHand = hand.indexWhere((c) => c.id == fan[toFan].id);
            if (toHand >= 0 && toHand != from) {
              vm.moveHandCardTo(from, toHand);
            }
          },
          child: AnimatedScale(
            scale: celebrating ? HandFanLayout.celebrationScale : 1.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: vm.isDragHidden(card.id) ? 0 : 1,
              child: WinningHandWave(
                active: celebrating,
                index: index,
                amplitude: 4,
                child: TutorialPulse(
                  cardId: card.id,
                  targetKey: vm.keyForCard(card.id, CardSlot.myHand),
                  child: FlightAwareCard(
                    key: vm.keyForCard(card.id, CardSlot.myHand),
                    motion: vm.motion,
                    cardId: card.id,
                    width: cardWidth,
                    child: PlayingCard(
                      playingCardModel: card,
                      width: cardWidth,
                      isSelected: selected || celebrating,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForGlobalCenter(Offset globalCenter, int count) {
    final layout = _fanLayout;
    final box = context.read<GeneralGameViewModel>().myHandKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (layout == null || box == null || !box.hasSize || count <= 0) return 0;
    final local = box.globalToLocal(globalCenter);
    return layout.indexAtLocalX(local.dx, count);
  }
}
