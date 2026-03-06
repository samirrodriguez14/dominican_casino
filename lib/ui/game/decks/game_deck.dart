import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/game/game_screen.dart';
import 'package:dominican_casino/ui/game/widgets/cards/playing_card_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';

class GameControlDeck extends StatefulWidget {
  const GameControlDeck({super.key});

  @override
  State<GameControlDeck> createState() => _GameControlDeckState();
}

class _GameControlDeckState extends State<GameControlDeck> {
  RoomViewModel get vm => context.read<RoomViewModel>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomViewModel>();
    return _buildDeckArea(context, vm);
  }

  Widget _buildDeckArea(BuildContext context, RoomViewModel vm) {
    final g = vm.g;

    final remaining = g?.deck.length;
    final started = g?.started ?? false;
    final isController = vm.isController;
    final canRedeal = vm.canRedeal;
    final canStart = vm.canStart;

    final String subtitle = remaining == null ? "-" : "$remaining";

    late final IconData actionIcon;
    late final String actionLabel;
    late final VoidCallback? onAction;

    if (g == null) {
      actionIcon = CupertinoIcons.lock;
      actionLabel = "Deleted";
      onAction = null;
    } else if (!started) {
      if (canStart) {
        actionIcon = CupertinoIcons.play_arrow_solid;
        actionLabel = "Start";
        onAction = () => vm.startGame();
      } else {
        actionIcon = CupertinoIcons.lock;
        actionLabel = isController ? "Waiting…" : "Locked";
        onAction = null;
      }
    } else {
      if (canRedeal) {
        actionIcon = CupertinoIcons.refresh_thick;
        actionLabel = "Redeal";
        onAction = (vm.canStartNextRound)
            ? () => vm.startNextRound()
            : () => vm.redealSameRound();
      } else {
        actionIcon = CupertinoIcons.lock;
        actionLabel = "Waiting…";
        onAction = null;
      }
    }

    return _DeckBox(
      subtitle: subtitle,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
      isEnabled: vm.controlGame,
      hasCards: remaining != 0,
      onDeletedPressed: () async {
        await vm.leaveGame();
        if (mounted) context.go('/lobby');
      },
      showAppPopup: () async {
        GameScreenState.showGameStatusPopup(context, vm);
      },
    );
  }
}

class _DeckBox extends StatelessWidget {
  const _DeckBox({
    required this.subtitle,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
    required this.isEnabled,
    required this.hasCards,
    required this.onDeletedPressed,
    required this.showAppPopup,
  });

  final String subtitle;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool isEnabled;
  final bool hasCards;
  final Future<void> Function() onDeletedPressed;
  final void Function() showAppPopup;

  @override
  Widget build(BuildContext context) {
    final actionEnabled = isEnabled && onAction != null;

    final double cardWidth = isEnabled ? 95 : 50;

    return GestureDetector(
      onTap: isEnabled ? null : showAppPopup,
      child: Container(
        padding: EdgeInsets.all(isEnabled ? 12 : 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PlayingCardBack(width: cardWidth, empty: !hasCards),
                const SizedBox(height: 2),
               if (subtitle!='0') Text(subtitle, style: AppStyle.theme.mutedText),
              ],
            ),
            if (isEnabled) const SizedBox(width: 8),
            if (isEnabled)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    onPressed: actionEnabled
                        ? () async {
                            HapticFeedback.mediumImpact();
                            onAction?.call();
                          }
                        : (actionLabel == "Deleted")
                        ? () async {
                            HapticFeedback.mediumImpact();
                            await onDeletedPressed();
                          }
                        : () => {},

                    child: Container(
                      decoration: AppStyle.theme.raisedSurfaceBox(),
                      child: Icon(
                        actionIcon,
                        size: cardWidth,
                        color: AppStyle.theme.muted,
                      ),
                    ),
                  ),

                  Text(actionLabel, style: AppStyle.theme.title),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
