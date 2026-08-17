import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void showJoinGameDialog(BuildContext context, String mode) {
  final TextEditingController controller = TextEditingController();
  final l10n = AppLocalizations.of(context);

  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(l10n.joinGame),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                l10n.joinCostsCoins(WalletConfig.entryCost),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: controller,
                placeholder: l10n.enterGameId,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l10n.join, style: AppStyle.theme.title),
            onPressed: SoundService.wrapTap(() {
              final gameId = controller.text.trim();
              Navigator.pop(context);
              if (gameId.isNotEmpty) {
                context.go(GameRoutes.game(gameId: gameId, gameMode: mode));
              }
            }),
          ),
        ],
      );
    },
  );
}

void showEnterGameDialog(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _EnterGamePopup(
        mode: mode,
        onFriend: () async {
          if (!await ensureGoogleForOnlinePlay(context)) return;
          if (!context.mounted) return;
          Navigator.pop(dialogContext);
          gameEnter(context, vm, mode, false);
        },
        onPuli: () {
          Navigator.pop(dialogContext);
          gameEnter(context, vm, mode, true);
        },
        onJoin: () async {
          if (!await ensureGoogleForOnlinePlay(context)) return;
          if (!context.mounted) return;
          Navigator.pop(dialogContext);
          showJoinGameDialog(context, mode.name);
        },
        gameTitle: _modeTitle(vm, mode),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

Future<bool> ensureGoogleForOnlinePlay(BuildContext context) async {
  final repo = context.read<AppRepo>();
  if (repo.isGoogleLinked) return true;
  final l10n = AppLocalizations.of(context);
  final connect = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.googleRequiredForFriendsTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.googleRequiredForFriendsBody),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.connectGoogle),
        ),
      ],
    ),
  );
  if (connect != true || !context.mounted) return false;

  final result = await repo.linkGoogleAccount();
  if (!context.mounted) return false;
  if (result.status == GoogleAuthStatus.canceled) return false;
  if (result.status == GoogleAuthStatus.failed) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.google),
        content: Text(l10n.googleSignInError(result.errorCode)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
    return false;
  }
  return repo.isGoogleLinked;
}

String _modeTitle(GamesViewModel vm, GameMode mode) {
  for (final game in vm.gamesInfo) {
    if (game.id == mode.name) return game.title;
  }
  return switch (mode) {
    GameMode.casino => 'Casino',
    GameMode.casinoSpeed => 'Casino Speed',
    GameMode.tresydos => 'Tres y Dos',
    GameMode.robaito => 'Robaito',
  };
}

class _EnterGamePopup extends StatelessWidget {
  const _EnterGamePopup({
    required this.mode,
    required this.gameTitle,
    required this.onFriend,
    required this.onPuli,
    required this.onJoin,
  });

  final GameMode mode;
  final String gameTitle;
  final VoidCallback onFriend;
  final VoidCallback onPuli;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final suitColor = switch (mode) {
      GameMode.tresydos => theme.suitRed,
      GameMode.casino ||
      GameMode.casinoSpeed ||
      GameMode.robaito => theme.textPrimary,
    };
    final suit = switch (mode) {
      GameMode.casino || GameMode.casinoSpeed => '♠',
      GameMode.tresydos => '♦',
      GameMode.robaito => '♣',
    };

    return Center(
      child: Material(
        color: CupertinoColors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suit,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.playHowPrompt,
                  textAlign: TextAlign.center,
                  style: theme.mutedText.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                _ChoiceTile(
                  icon: CupertinoIcons.person_2_fill,
                  title: l10n.playWithFriend,
                  subtitle: l10n.playWithFriendHint,
                  costLabel: '${WalletConfig.entryCost}',
                  costIcon: coinIcon,
                  emphasized: true,
                  onTap: onFriend,
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  icon: CupertinoIcons.bolt_fill,
                  title: l10n.playVsPuli,
                  subtitle: l10n.playVsPuliHint,
                  costLabel:
                      '${WalletConfig.puliloEnergyCostFor(mode.name)}',
                  costIcon: CupertinoIcons.bolt_fill,
                  onTap: onPuli,
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  icon: CupertinoIcons.number,
                  title: l10n.joinById,
                  subtitle: l10n.playJoinByIdHint,
                  costLabel: '${WalletConfig.entryCost}',
                  costIcon: coinIcon,
                  onTap: onJoin,
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 4),
                  onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: theme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
    this.costLabel,
    this.costIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;
  final String? costLabel;
  final IconData? costIcon;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    const radius = 14.0;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.72,
      onPressed: SoundService.wrapTap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasized ? theme.surfaceRaised : theme.background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: emphasized
                ? theme.turnHighlight.withValues(alpha: .5)
                : theme.border.withValues(alpha: .55),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.5,
                  color: emphasized
                      ? theme.turnHighlight
                      : CupertinoColors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emphasized
                                ? theme.turnHighlight.withValues(alpha: .22)
                                : theme.surfaceAlt.withValues(alpha: .55),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 18,
                            color: emphasized
                                ? theme.turnHighlight
                                : theme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: theme.title.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: theme.mutedText.copyWith(
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (costLabel != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                costIcon ?? coinIcon,
                                size: 14,
                                color: costIcon == CupertinoIcons.bolt_fill
                                    ? theme.warning
                                    : theme.turnHighlight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                costLabel!,
                                style: theme.title.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> gameEnter(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
  bool local,
) async {
  if (mode == GameMode.robaito) return;
  final repo = context.read<AppRepo>();
  final router = GoRouter.of(context);
  final l10n = AppLocalizations.of(context);
  if (local) {
    if (!repo.canAffordPulilo(mode)) {
      await showInsufficientFundsDialog(context, energy: true);
      return;
    }
  } else if (!repo.canAffordFriendGame) {
    await showInsufficientFundsDialog(context, energy: false);
    return;
  }
  try {
    final gid = await vm.newGame(mode, local);
    if (gid != null) {
      router.go(GameRoutes.game(gameId: gid, gameMode: mode.name));
    }
  } on InsufficientFundsException catch (e) {
    if (context.mounted) {
      await showInsufficientFundsDialog(context, energy: e.energy);
    }
  } catch (e, st) {
    developer.log('gameEnter: $e', stackTrace: st);
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.couldNotStartGame),
        content: Text(l10n.tryAgain),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}

Future<InstructionsData> loadInstructions(GameMode mode) async {
  final path = switch (mode) {
    GameMode.tresydos => 'assets/config/tresydos_instructions.json',
    GameMode.robaito => 'assets/config/robaito_instructions.json',
    GameMode.casino => 'assets/config/casino_instructions.json',
    GameMode.casinoSpeed => 'assets/config/casino_speed_instructions.json',
  };
  final raw = await rootBundle.loadString(path);
  return InstructionsData.fromJson(jsonDecode(raw));
}
