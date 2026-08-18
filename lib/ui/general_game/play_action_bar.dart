import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

/// Hand-play choices: action chips, with dismiss sitting above them
/// when a drop needs a follow-up. The X does not consume row space.
class PlayActionBar extends StatelessWidget {
  const PlayActionBar({super.key, required this.vm});

  final GeneralGameViewModel vm;

  static const double height = 42;

  @override
  Widget build(BuildContext context) {
    final pending = vm.dropPending;
    final actions = pending?.actions ?? vm.possiblePlayActions;
    if (!vm.isLiveTurn && pending == null) {
      return const SizedBox.shrink();
    }

    final choosing = pending != null;
    final showHint = !choosing && (!vm.canPlayTurn || actions.isEmpty);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: showHint
              ? Center(child: _TurnHint(isMyTurn: vm.canPlayTurn))
              : _ActionChipRow(
                  vm: vm,
                  actions: actions,
                  choosing: choosing,
                ),
        ),
        if (choosing)
          Positioned(
            top: -16,
            child: _DismissPlayButton(onTap: vm.cancelDropPending),
          ),
      ],
    );
  }
}

class _ActionChipRow extends StatelessWidget {
  const _ActionChipRow({
    required this.vm,
    required this.actions,
    required this.choosing,
  });

  final GeneralGameViewModel vm;
  final List<PlayAction> actions;
  final bool choosing;

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
                for (var index = 0; index < actions.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: KeyedSubtree(
                      key: choosing
                          ? ValueKey('pending_$index')
                          : actionBarKey(vm, actions, index),
                      child: _ActionChipButton(
                        label: actionLabel(actions[index]),
                        icon: actionIcon(actions[index]),
                        primary: index == 0,
                        onTap: () {
                          if (choosing) {
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
