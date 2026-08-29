import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/round.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/general_game/bs_claim_rank_picker.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:dominican_casino/view_models/tutorial_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Hand-play choices: action chips, with cancel inline when a drop
/// needs a follow-up. The row always keeps its height so the board
/// does not jump when turns or animations start and stop.
class PlayActionBar extends StatelessWidget {
  const PlayActionBar({super.key, required this.vm});

  final GeneralGameViewModel vm;

  static const double height = 42;

  @override
  Widget build(BuildContext context) {
    final pending = vm.dropPending;
    final actions = pending?.actions ?? vm.possiblePlayActions;
    final choosing = pending != null;
    final outOfTurn = vm.outOfTurnActions;
    final callBluff = outOfTurn.whereType<CallBluffAction>().firstOrNull;
    final showPlayChips = choosing || (vm.canPlayTurn && actions.isNotEmpty);
    final showChips = showPlayChips || callBluff != null;
    final roundPlaying =
        vm.gameState.round.roundStatus == RoundStatus.playing;
    final idleHint = context.select<TutorialViewModel, String?>(
      (t) => t.idleHintMessage,
    );
    final turnPid = vm.gameState.currentTurnPlayerId ?? '';
    final bool? hintMine;
    if (showChips || !roundPlaying) {
      hintMine = null;
    } else if (vm.isMyTurn) {
      hintMine = true;
    } else if (turnPid.isNotEmpty) {
      hintMine = false;
    } else {
      hintMine = null;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          showChips
              ? _ActionChipRow(
                  vm: vm,
                  actions: showPlayChips ? actions : const [],
                  choosing: choosing,
                  callBluff: callBluff,
                )
              : Center(
                  child: idleHint != null
                      ? _IdleHintText(message: idleHint)
                      : hintMine == null
                          ? const SizedBox.shrink()
                          : _TurnHint(isMyTurn: hintMine),
                ),
          if (showChips && idleHint != null)
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: _IdleHintText(message: idleHint),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdleHintText extends StatelessWidget {
  const _IdleHintText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Center(
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.turnHighlight,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ActionChipRow extends StatelessWidget {
  const _ActionChipRow({
    required this.vm,
    required this.actions,
    required this.choosing,
    this.callBluff,
  });

  final GeneralGameViewModel vm;
  final List<PlayAction> actions;
  final bool choosing;
  final CallBluffAction? callBluff;

  Future<void> _onPlayTap(BuildContext context, PlayAction action) async {
    if (action is ClaimPlayAction) {
      final cards = action.cards.isNotEmpty
          ? action.cards
          : vm.selectedCards;
      if (cards.isEmpty) return;
      final rank = await showBsClaimRankPicker(
        context,
        cardCount: cards.length,
      );
      if (rank == null || !context.mounted) return;
      await vm.performClaimPlay(cards, rank);
      return;
    }
    if (choosing) {
      vm.commitDropPending(action);
    } else {
      vm.performPlayAction(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (choosing) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _DismissPlayButton(onTap: vm.cancelDropPending),
                  ),
                ],
                if (callBluff != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ActionChipButton(
                      label: 'Call BS',
                      icon: CupertinoIcons.exclamationmark_bubble_fill,
                      primary: true,
                      onTap: () => vm.performOutOfTurnAction(callBluff!),
                    ),
                  ),
                for (var index = 0; index < actions.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Builder(
                      builder: (context) {
                        final chipKey = choosing
                            ? ValueKey('pending_$index')
                            : actionBarKey(vm, actions, index);
                        return KeyedSubtree(
                          key: chipKey,
                          child: TutorialPulse(
                            bounce: false,
                            targetKey: chipKey is GlobalKey ? chipKey : null,
                            child: _ActionChipButton(
                              label: actionLabel(actions[index]),
                              icon: actionIcon(actions[index]),
                              primary: index == 0 && callBluff == null,
                              onTap: () => _onPlayTap(context, actions[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DismissPlayButton extends StatelessWidget {
  const _DismissPlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.cancel,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onTap),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.surface.withValues(alpha: .94),
            border: Border.all(color: theme.border.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.xmark,
            size: 13,
            color: theme.textPrimary.withValues(alpha: .85),
          ),
        ),
      ),
    );
  }
}

class _TurnHint extends StatelessWidget {
  const _TurnHint({required this.isMyTurn});

  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return Text(
      isMyTurn ? l10n.yourTurn : l10n.opponentTurn,
      style: theme.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: isMyTurn
            ? theme.turnHighlight
            : theme.textPrimary.withValues(alpha: .7),
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
      onPressed: SoundService.wrapTap(onTap),
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

Key actionBarKey(
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

IconData actionIcon(PlayAction action) {
  final name = action.runtimeType.toString();
  switch (name) {
    case 'PlayCardAction':
    case 'ClaimPlayAction':
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
