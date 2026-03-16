import 'dart:developer' as developer;

import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class GenGameControl extends StatefulWidget {
  const GenGameControl({super.key});

  @override
  State<GenGameControl> createState() => _GenGameControlState();
}

class _GenGameControlState extends State<GenGameControl> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();

  @override
  Widget build(BuildContext context) {
    final inGameAction = context.watch<GeneralGameViewModel>().inGameAction;
    if (inGameAction != InGameAction.noAction) {
      return Container(
        decoration: AppStyle.theme.raisedSurfaceBox(),

        child: _buildInGameActionButton(context, vm, inGameAction),
      );
    }
    return SizedBox();
  }

  Widget _buildInGameActionButton(
    BuildContext ctx,
    GeneralGameViewModel vm,
    InGameAction inGameAction,
  ) {
    double iconSize = 75;
    return CupertinoButton(
      onPressed: actionAction(inGameAction, vm),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            actionIcon(inGameAction),
            size: iconSize,
            color: AppStyle.theme.muted,
          ),
          Text(inGameAction.name),
        ],
      ),
    );
  }

  Function() actionAction(InGameAction action, GeneralGameViewModel vm) {
    switch (action) {
      case InGameAction.share:
        return () => _shareAction(vm.gid);
      case InGameAction.waiting:
        if (vm.gameState.gameStatus == GameStatus.gameOver) {
          return () {
            context.go('/landing');

            vm.leaveGame();
          };
        }
        return () => {};
      default:
        return () => vm.performInGameAction(action);
    }
  }

  IconData actionIcon(InGameAction action) {
    switch (action) {
      case InGameAction.start:
        return CupertinoIcons.play_fill;
      case InGameAction.share:
        return CupertinoIcons.share;

      case InGameAction.deal:
        return CupertinoIcons.rectangle_on_rectangle_angled;

      case InGameAction.dealSame:
        return CupertinoIcons.rectangle_on_rectangle_angled;
      case InGameAction.setReady:
        return CupertinoIcons.check_mark_circled;
      case InGameAction.noAction:
        return CupertinoIcons.stop;
      case InGameAction.waiting:
        return (vm.gameState.gameStatus == GameStatus.gameOver)
            ? CupertinoIcons.arrow_left_circle
            : CupertinoIcons.lock;
      case InGameAction.shuffle:
        return CupertinoIcons.square_on_square;
    }
  }

  static Future<void> _shareAction(String? gid) async {
    if (gid == null) return;
    developer.log("sharing");
    final link = "https://dominican-casino.web.app/join/$gid";
    final message =
        '''Join my Dominican Casino game!
               $link
                ''';

    await SharePlus.instance.share(ShareParams(text: message));
  }
}
