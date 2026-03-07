import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/game/decks/card_deck.dart';
import 'package:dominican_casino/ui/game/game_screen.dart';
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
    final started = g?.started ?? false;
    final isController = vm.isController;
    final canRedeal = vm.canRedeal;
    final canStart = vm.canStart;
    late final IconData actionIcon;
    late final String actionLabel;
    late  VoidCallback? onAction=()=>{};

    if (!started) {
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
        // onAction = null;
      }
    }
    final actionEnabled = vm.controlGame && onAction != null;

    final double cardWidth = vm.controlGame ? 90 : 55;

    return Container(
      padding: EdgeInsets.all(vm.controlGame ? 12 : 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CardDeck(
                cardWidth: cardWidth,
                cards: vm.g?.deck??[],
                extraPoints: 0,
                onTap: () {
                  GameScreenState.showGameStatusPopup(context, vm);
                },
              ),
              
            ],
          ),
          if (vm.controlGame) const SizedBox(width: 8),
          if (vm.controlGame)
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

                          await vm.leaveGame();
                          if (mounted) context.go('/lobby');
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
    );
  }
}
