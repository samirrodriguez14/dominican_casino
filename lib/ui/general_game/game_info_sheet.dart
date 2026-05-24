import 'dart:convert';

import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

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
    _instructionsFuture = _loadInstructions();
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

        return Expanded(
          child: Column(
            children: [
              const SizedBox(height: 10),

              Text(
                "Game: ${vm.gameState.gameMode.name}",
                style: theme.title.copyWith(fontSize: 24),
              ),

              const SizedBox(height: 8),

              Text(
                "Rules",
                style: theme.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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

Future<InstructionsData> _loadInstructions() async {
  final raw = await rootBundle.loadString('config/instructions.json');

  return InstructionsData.fromJson(jsonDecode(raw));
}
