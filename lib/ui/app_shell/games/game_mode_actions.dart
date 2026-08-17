import 'dart:convert';

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:dominican_casino/ui/widgets/popup_circle_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

void showJoinGameDialog(BuildContext context, String mode) {
  final TextEditingController controller = TextEditingController();

  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Join Game'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Enter Game ID',
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Join', style: AppStyle.theme.title),
            onPressed: () {
              final gameId = controller.text.trim();
              Navigator.pop(context);
              if (gameId.isNotEmpty) {
                context.go(GameRoutes.game(gameId: gameId, gameMode: mode));
              }
            },
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
  final theme = AppStyle.theme;

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: CupertinoColors.transparent,
          child: Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 28),
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  color: theme.background,
                  child: Text(
                    'Play',
                    textAlign: TextAlign.center,
                    style: theme.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: theme.surfaceRaised,
                  child: Column(
                    children: [
                      _PlayOption(
                        label: 'Friend',
                        emphasized: true,
                        onTap: () {
                          Navigator.pop(dialogContext);
                          gameEnter(context, vm, mode, false);
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.border.withValues(alpha: .55),
                      ),
                      _PlayOption(
                        label: 'Puli (AI bot)',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          gameEnter(context, vm, mode, true);
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.border.withValues(alpha: .55),
                      ),
                      _PlayOption(
                        label: 'Join by ID',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          showJoinGameDialog(context, mode.name);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _PlayOption extends StatelessWidget {
  const _PlayOption({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      onPressed: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.title.copyWith(
            fontSize: 18,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            color: theme.textPrimary,
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
  final gid = await vm.newGame(mode, local);
  if (gid != null && context.mounted) {
    context.go(GameRoutes.game(gameId: gid, gameMode: mode.name));
  }
}

Future<InstructionsData> loadInstructions(GameMode mode) async {
  final path = switch (mode) {
    GameMode.tresydos => 'assets/config/tresydos_instructions.json',
    GameMode.robaito => 'assets/config/robaito_instructions.json',
    GameMode.casino => 'assets/config/casino_instructions.json',
  };
  final raw = await rootBundle.loadString(path);
  return InstructionsData.fromJson(jsonDecode(raw));
}

void showGameInfo(BuildContext context, GameMode mode) {
  final theme = AppStyle.theme;

  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * .78,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.muted.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How to Play',
                    style: theme.title.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder<InstructionsData>(
                      future: loadInstructions(mode),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        final data = snapshot.data!;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                          child: Column(
                            children: data.sections.map((section) {
                              return _PopupInstructionSection(
                                section: section,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mode == GameMode.casino) ...[
                      PopupCircleButton(
                        icon: CupertinoIcons.play_fill,
                        emphasized: true,
                        onPressed: () {
                          final uuid = Uuid();
                          context.go(
                            '/game/${uuid.v4().substring(0, 6)}/casino/true',
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    PopupCircleButton(
                      icon: CupertinoIcons.xmark,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PopupInstructionSection extends StatelessWidget {
  final InstructionSection section;

  const _PopupInstructionSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: theme.title.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          for (final text in section.body) ...[
            Text(text, style: theme.body.copyWith(fontSize: 17, height: 1.35)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
