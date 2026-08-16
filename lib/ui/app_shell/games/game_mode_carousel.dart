import 'dart:convert';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class GameModeCarousel extends StatefulWidget {
  const GameModeCarousel({super.key});

  @override
  State<GameModeCarousel> createState() => _GameModeCarouselState();
}

class _GameModeCarouselState extends State<GameModeCarousel> {
  final PageController controller = PageController(
    viewportFraction: 0.7,
    initialPage: 1,
  );

  double page = 1;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        page = controller.page ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final modes = GameMode.values
        .where((m) => m != GameMode.robaito)
        .toList();

    return SizedBox(
      height: screenHeight * 0.5,
      child: PageView.builder(
        controller: controller,
        itemCount: modes.length,
        itemBuilder: (context, index) {
          final diff = (page - index).abs();
          final scale = (1 - (diff * 0.3)).clamp(0.1, 1.0);
          final mode = modes[index];
          return Center(
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: AppStyle.theme.raisedSurfaceBox(),
                    child: GameModeCard(mode: mode),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 16,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        color: AppStyle.theme.border,
                        borderRadius: BorderRadius.circular(
                          AppStyle.theme.radius,
                        ),
                        onPressed: () => _showGameInfo(context, mode),
                        child: Text("How to play", style: AppStyle.theme.title),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

void _showGameInfo(BuildContext context, GameMode mode) {
  final theme = AppStyle.theme;

  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * .78,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<InstructionsData>(
            future: loadInstructions(mode),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final data = snapshot.data!;

              return Column(
                children: [
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
                    "How to Play",
                    style: theme.title.copyWith(fontSize: 28),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: data.sections.map((section) {
                          return _PopupInstructionSection(section: section);
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: .center,
                    spacing: 10,
                    children: [
                      Row(
                        children: [
                          CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 10,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.xmark, size: 18),
                                SizedBox(width: 8),
                                Text("Got it"),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (mode == .casino)
                            CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 10,
                              ),
                              onPressed: () {
                                final uuid = Uuid();
                                context.go(
                                  '/game/${uuid.v4().substring(0, 6)}/casino/true',
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.play_fill, size: 18),
                                  SizedBox(width: 8),
                                  Text("Tutorial"),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
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
