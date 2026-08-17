import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

class GameInfoSheet extends StatefulWidget {
  const GameInfoSheet({super.key, required this.vm, this.scrollController});
  final GeneralGameViewModel vm;
  final ScrollController? scrollController;

  @override
  State<GameInfoSheet> createState() => _GameInfoSheetState();
}

class _GameInfoSheetState extends State<GameInfoSheet> {
  late Future<InstructionsData> _instructionsFuture;

  @override
  void initState() {
    super.initState();
    _instructionsFuture = loadInstructions(widget.vm.gameState.gameMode);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final theme = AppStyle.theme;

    return FutureBuilder<InstructionsData>(
      future: _instructionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final data = snapshot.data!;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Game: ${vm.gameState.gameMode.name}",
                style: theme.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: data.sections.length,
                  itemBuilder: (context, index) {
                    final section = data.sections[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: theme.title.copyWith(fontSize: 22),
                          ),

                          const SizedBox(height: 10),

                          for (final text in section.body) ...[
                            Text(
                              text,
                              style: theme.body.copyWith(
                                fontSize: 17,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          if (section.specialCards.isNotEmpty) ...[
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: section.specialCards.map((special) {
                                final card = PlayingCardModel(
                                  id: 'instruction-${special.rank}-${special.suit}',
                                  rank: special.rank,
                                  suit: special.suit,
                                );

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 110,
                                      child: PlayingCard(
                                        playingCardModel: card,
                                        isSelected: false,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      special.points,
                                      style: theme.body.copyWith(fontSize: 14),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
