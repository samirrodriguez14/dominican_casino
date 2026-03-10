import 'dart:developer' as developer;

import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dominican_casino/view_models/games/game_view_model.dart';
import 'package:share_plus/share_plus.dart';

class GameControlDeck extends StatefulWidget {
  const GameControlDeck({super.key});

  @override
  State<GameControlDeck> createState() => _GameControlDeckState();
}

class _GameControlDeckState extends State<GameControlDeck> {
  GameViewModel get vm => context.read<GameViewModel>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameViewModel>();
    return _buildDeckArea(context, vm);
  }

  Widget _buildDeckArea(BuildContext context, GameViewModel vm) {
    final g = vm.g;
    final started = g?.started ?? false;
    final isController = vm.isController;
    final canRedeal = vm.canRedeal;
    final canStart = vm.canStart;
    final waitingOnOpponent = vm.waitingOnOpponent;
    late final IconData actionIcon;
    late final String actionLabel;
    late Future<void> Function()? onAction;

    if (!started) {
      if (waitingOnOpponent) {
        actionIcon = CupertinoIcons.share;
        actionLabel = "Share";
        onAction = () async => _shareAction(g?.id);
      } else if (canStart) {
        actionIcon = CupertinoIcons.play_arrow_solid;
        actionLabel = "Start";
        onAction = () async => await vm.startGame();
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
    final actionEnabled = vm.canControlGame && onAction != null;

    final double cardWidth = vm.canControlGame ? 90 : 55;

    return Container(
      padding: EdgeInsets.all(vm.canControlGame ? 12 : 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          if (vm.canControlGame)
            _buildControlArea(
              onAction,
              g?.id,
              actionEnabled,
              actionIcon,
              actionLabel,
              cardWidth,
            ),
        ],
      ),
    );
  }

  Widget _buildControlArea(
    Future<void> Function()? onAction,
    String? gid,
    bool actionEnabled,
    IconData actionIcon,
    String actionLabel,
    double cardWidth,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          onPressed: (onAction != null)
              ? () async {
                  HapticFeedback.mediumImpact();
                  onAction();
                }
              : null,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.all(8),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Icon(
              actionIcon,
              size: cardWidth,
              color: AppStyle.theme.muted,
            ),
          ),
        ),
        Text(actionLabel, style: AppStyle.theme.title),
        if (gid != null) Text("ID: $gid", style: AppStyle.theme.mutedText),
      ],
    );
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
