import 'dart:math' as math;

import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Casino player hand: tap-select plus inline actions over a centered fan.
class SimplePlayerArea extends StatefulWidget {
  const SimplePlayerArea({super.key});

  @override
  State<SimplePlayerArea> createState() => _SimplePlayerAreaState();
}

class _SimplePlayerAreaState extends State<SimplePlayerArea> {
  final GlobalKey _fanKey = GlobalKey();
  double _fanGap = 48;
  static const double _cardWidth = 110.0;
  static const double _fanHeight = 168.0;
  static const double _edgeAngle = 0.20;
  static const double _selectedLift = 12.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: _buildPlayControls(context, vm),
        ),
        const SizedBox(height: 2),
        SizedBox(
          key: vm.myHandKey,
          height: _fanHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cards = vm.myHandCards;
              if (cards.isEmpty) return const SizedBox.shrink();
              final count = cards.length;
              final cardH = _cardWidth * 1.4;
              final gap = count == 1
                  ? 0.0
                  : ((constraints.maxWidth - _cardWidth) / (count - 1))
                        .clamp(38.0, 56.0);
              _fanGap = gap;

              final totalWidth = _cardWidth + ((count - 1) * gap);
              final draggingId = vm.draggingSource?.id;
              final mid = (count - 1) / 2.0;
              final baseTop = _fanHeight - cardH;

              return ListenableBuilder(
                listenable: vm.motion,
                builder: (context, _) {
                  // Deal flights land upright; fan once every hand card has arrived.
                  final holdFlat =
                      cards.isNotEmpty &&
                      cards.every((c) => vm.motion.isInFlight(c.id));
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: _fanHeight,
                    child: Center(
                      child: SizedBox(
                        key: _fanKey,
                        width: totalWidth,
                        height: _fanHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < count; i++)
                              _fanCard(
                                vm: vm,
                                card: cards[i],
                                index: i,
                                count: count,
                                mid: mid,
                                gap: gap,
                                baseTop: baseTop,
                                draggingId: draggingId,
                                holdFlat: holdFlat,
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
    required double baseTop,
    required String? draggingId,
    required bool holdFlat,
  }) {
    final selected = vm.selectedCard == card && draggingId != card.id;
    final t = count == 1 ? 0.0 : (index - mid) / mid;
    final angle = holdFlat ? 0.0 : t * _edgeAngle;
    final arcDrop = holdFlat ? 0.0 : t.abs() * 10;
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
          feedbackWidth: _cardWidth,
          tableFeedbackWidth: 72,
          onTap: () => vm.selectCard(card),
          onHandReorder: (global) {
            if (vm.hitTestDropTarget(global) != null) return;
            final id = vm.draggingSource?.id;
            if (id == null) return;
            final live = vm.myHandCards;
            final liveFrom = live.indexWhere((c) => c.id == id);
            if (liveFrom < 0) return;
            final to = _indexForGlobalCenter(global, live.length);
            if (to != liveFrom) vm.moveHandCardTo(liveFrom, to);
          },
          child: Opacity(
            opacity: vm.isDragHidden(card.id) ? 0 : 1,
            child: FlightAwareCard(
              key: vm.keyForCard(card.id, CardSlot.myHand),
              motion: vm.motion,
              cardId: card.id,
              width: _cardWidth,
              child: PlayingCard(
                playingCardModel: card,
                width: _cardWidth,
                isSelected: selected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForGlobalCenter(Offset globalCenter, int count) {
    final box = _fanKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || count <= 0) return 0;
    final local = box.globalToLocal(globalCenter);
    if (_fanGap <= 0) return 0;
    return (local.dx / _fanGap).round().clamp(0, count - 1);
  }

  Widget _buildPlayControls(BuildContext context, GeneralGameViewModel vm) {
    final pending = vm.dropPending;
    final actions = pending != null ? pending.actions : vm.possiblePlayActions;
    final canPlay = vm.canPlayTurn;
    final liveTurn = vm.isLiveTurn;
    final showSpeedClock = vm.speedTurnRemainingSeconds > 0;

    if (!liveTurn && pending == null) {
      return const SizedBox.shrink();
    }

    return !canPlay && pending == null
        ? Center(child: _TurnHint(isMyTurn: canPlay))
        : actions.isEmpty && pending == null
        ? Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TurnHint(isMyTurn: canPlay),
                if (showSpeedClock) ...[
                  const SizedBox(width: 10),
                  _SpeedTurnClock(remainingSeconds: vm.speedTurnRemainingSeconds),
                ]
              ],
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pending != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _ActionChipButton(
                            label: 'Cancel',
                            icon: CupertinoIcons.xmark_circle_fill,
                            onTap: vm.cancelDropPending,
                          ),
                        ),
                        if (showSpeedClock)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _SpeedTurnClock(
                              remainingSeconds: vm.speedTurnRemainingSeconds,
                            ),
                          ),
                      for (var index = 0; index < actions.length; index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: KeyedSubtree(
                            key: pending == null
                                ? _widgetKeyForAction(vm, actions, index)
                                : ValueKey('pending_$index'),
                            child: _ActionChipButton(
                              label: actionLabel(actions[index]),
                              icon: _actionIcon(actions[index]),
                              primary: index == 0,
                              onTap: () {
                                if (pending != null) {
                                  vm.commitDropPending(actions[index]);
                                } else {
                                  vm.performPlayAction(actions[index]);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Key _widgetKeyForAction(
    GeneralGameViewModel vm,
    List<PlayAction> actions,
    int index,
  ) {
    final action = actions[index];
    final name = action.runtimeType.toString();

    final isFirstAddAndTake =
        name == 'AddAndTakeAction' &&
        actions.indexWhere(
              (a) => a.runtimeType.toString() == 'AddAndTakeAction',
            ) ==
            index;
    if (isFirstAddAndTake) return vm.playButtonKey;

    final isFirstAdd =
        (name == 'AddCardsAction' ||
            name == 'AddCardStackAction' ||
            name == 'AddTableCardsAction') &&
        actions.indexWhere((a) {
              final n = a.runtimeType.toString();
              return n == 'AddCardsAction' ||
                  n == 'AddCardStackAction' ||
                  n == 'AddTableCardsAction';
            }) ==
            index;
    if (isFirstAdd) return vm.addButtonKey;

    final isFirstTakeStack =
        name == 'TakeStackAction' &&
        actions.indexWhere(
              (a) => a.runtimeType.toString() == 'TakeStackAction',
            ) ==
            index;
    if (isFirstTakeStack) return vm.takeStackButtonKey;

    final isFirstPlayish =
        (name == 'PlayCardAction' ||
            name == 'TakeCardAction' ||
            name == 'PairCardsAction') &&
        actions.indexWhere((a) {
              final n = a.runtimeType.toString();
              return n == 'PlayCardAction' ||
                  n == 'TakeCardAction' ||
                  n == 'PairCardsAction';
            }) ==
            index;
    if (isFirstPlayish) return vm.playButtonKey;

    return ValueKey('action_${name}_$index');
  }

  IconData _actionIcon(PlayAction action) {
    final name = action.runtimeType.toString();
    switch (name) {
      case 'PlayCardAction':
        return CupertinoIcons.arrow_up_circle_fill;
      case 'TakeCardAction':
        return CupertinoIcons.arrow_down_circle_fill;
      case 'TakeStackAction':
        return CupertinoIcons.square_stack_3d_up_fill;
      case 'AddCardsAction':
      case 'AddCardStackAction':
      case 'AddTableCardsAction':
        return CupertinoIcons.plus_circle_fill;
      case 'PairCardsAction':
      case 'PairTableCardsAction':
        return CupertinoIcons.link;
      default:
        return CupertinoIcons.sparkles;
    }
  }
}

class _TurnHint extends StatelessWidget {
  const _TurnHint({required this.isMyTurn});

  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Text(
      isMyTurn
          ? AppLocalizations.of(context).yourTurn
          : AppLocalizations.of(context).opponentTurn,
      style: theme.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: isMyTurn
            ? theme.turnHighlight
            : theme.textPrimary.withValues(alpha: .7),
      ),
    );
  }
}

class _SpeedTurnClock extends StatelessWidget {
  const _SpeedTurnClock({required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final urgent = remainingSeconds <= 3;
    final fill = urgent
        ? CupertinoColors.systemRed.withValues(alpha: .18)
        : theme.turnHighlight.withValues(alpha: .18);
    final border = urgent
        ? CupertinoColors.systemRed.withValues(alpha: .45)
        : theme.turnHighlight.withValues(alpha: .35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.timer,
            size: 16,
            color: urgent ? CupertinoColors.systemRed : theme.turnHighlight,
          ),
          const SizedBox(width: 6),
          Text(
            '${remainingSeconds}s',
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: urgent ? CupertinoColors.systemRed : theme.turnHighlight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final gold = AppStyle.theme.turnHighlight;
    final dark = AppStyle.theme.background;
    final fg = primary ? dark : gold;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: primary ? gold : const Color(0x00000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: gold, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
