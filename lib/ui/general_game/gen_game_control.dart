import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/share_invite.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GenGameControl extends StatefulWidget {
  const GenGameControl({super.key});

  @override
  State<GenGameControl> createState() => _GenGameControlState();
}

class _GenGameControlState extends State<GenGameControl> {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();

    return ListenableBuilder(
      listenable: vm.motion,
      builder: (context, _) {
        // Hide during shuffle even if the VM hasn't rebuilt yet.
        if (!vm.showInGameControl) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(minWidth: 148),
          decoration: AppStyle.theme.raisedSurfaceBox(),
          child: _buildInGameActionButton(context, vm, vm.inGameAction),
        );
      },
    );
  }

  Widget _buildInGameActionButton(
    BuildContext ctx,
    GeneralGameViewModel vm,
    InGameAction inGameAction,
  ) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(ctx);
    final enabled =
        inGameAction != InGameAction.waiting &&
        inGameAction != InGameAction.noAction;
    final gold = theme.turnHighlight;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            actionIcon(inGameAction),
            size: 34,
            color: enabled ? gold : theme.muted,
          ),
          const SizedBox(height: 10),
          Text(
            actionLabel(inGameAction, l10n),
            style: theme.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: enabled ? theme.textPrimary : theme.muted,
            ),
          ),
          if (inGameAction == InGameAction.share)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('ID: ${vm.gameState.id}', style: theme.caption),
            ),
        ],
      ),
    );

    if (!enabled) return content;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(actionAction(inGameAction, vm, ctx)),
      child: content,
    );
  }

  Function() actionAction(
    InGameAction action,
    GeneralGameViewModel vm,
    BuildContext buttonContext,
  ) {
    switch (action) {
      case InGameAction.share:
        return () => shareGameInvite(
          context: buttonContext,
          gameId: vm.gid,
          gameMode: vm.gameState.gameMode.name,
        );
      case InGameAction.exit:
        return () async {
          await vm.queueHomeCoinClaim();
          await vm.queueHomeDailyChallengeEnergyClaims();
          await vm.queueHomeXpClaim();
          if (!mounted) return;
          context.go('/landing');
        };
      case InGameAction.waiting:
        return () => {};
      default:
        return () => vm.performInGameAction(action);
    }
  }

  String actionLabel(InGameAction action, AppLocalizations l10n) {
    switch (action) {
      case InGameAction.start:
        return l10n.actionStart;
      case InGameAction.share:
        return l10n.actionShare;
      case InGameAction.deal:
        return l10n.actionDeal;
      case InGameAction.dealSame:
        return l10n.actionDealAgain;
      case InGameAction.setReady:
        return l10n.actionReady;
      case InGameAction.waiting:
        return l10n.actionWaiting;
      case InGameAction.shuffle:
        return l10n.actionShuffle;
      case InGameAction.exit:
        return l10n.actionLeave;
      case InGameAction.noAction:
        return '';
    }
  }

  IconData actionIcon(InGameAction action) {
    switch (action) {
      case InGameAction.start:
        return CupertinoIcons.play_fill;
      case InGameAction.share:
        return CupertinoIcons.share;
      case InGameAction.deal:
      case InGameAction.dealSame:
        return CupertinoIcons.square_stack_fill;
      case InGameAction.setReady:
        return CupertinoIcons.check_mark_circled;
      case InGameAction.noAction:
        return CupertinoIcons.stop;
      case InGameAction.waiting:
        return CupertinoIcons.clock;
      case InGameAction.shuffle:
        return CupertinoIcons.shuffle;
      case InGameAction.exit:
        return CupertinoIcons.square_arrow_left;
    }
  }
}
