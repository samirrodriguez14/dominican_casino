import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameStatusSheet extends StatefulWidget {
  const GameStatusSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<GameStatusSheet> createState() => _GameStatusSheetState();
}

class _GameStatusSheetState extends State<GameStatusSheet> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    final gameState = vm.gameState;

    final playerIds = (gameState.playersInfo.keys).toList();
    final totalScores = gameState.scores;
    final roundScores = gameState.round.roundScores;

    return Container(
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, -4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppStyle.theme.muted.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Center(
                  child: Text("Game Status", style: AppStyle.theme.mutedText),
                ),
                const SizedBox(height: 16),

                /// TOTAL SCORES
                _SectionCard(
                  title: "Total Scores",
                  child: Column(
                    children: playerIds.map((pid) {
                      final score = totalScores[pid] ?? 0;
                      final isMe = pid == vm.player.id;

                      return _ScoreRow(
                        label: isMe ? "You" : pid,
                        value: "$score",
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                /// PREVIOUS ROUND
                _SectionCard(
                  title: "Previous Round",
                  child: roundScores.isEmpty
                      ? Text(
                          "No round scores yet",
                          style: AppStyle.theme.mutedText,
                        )
                      : Column(
                          children: playerIds.map((pid) {
                            final scoreMap = Map<String, dynamic>.from(
                              roundScores[pid] ?? {},
                            );
                            final isMe = pid == vm.player.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? "You" : pid,
                                    style: AppStyle.theme.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (scoreMap['A'] != 0)
                                        _MiniScoreChip(
                                          label: "A",
                                          value: "${scoreMap['A'] ?? 0}",
                                        ),
                                      if (scoreMap['2♠'] != 0)
                                        _MiniScoreChip(
                                          label: "2♠",
                                          value: "${scoreMap['2♠'] ?? 0}",
                                        ),
                                      if (scoreMap['10♦'] != 0)
                                        _MiniScoreChip(
                                          label: "10♦",
                                          value: "${scoreMap['10♦'] ?? 0}",
                                        ),
                                      if (scoreMap['pi'] != 0)
                                        _MiniScoreChip(
                                          label: "Pi",
                                          value: "${scoreMap['pi'] ?? 0}",
                                        ),
                                      if (scoreMap['carta'] != 0)
                                        _MiniScoreChip(
                                          label: "Carta",
                                          value: "${scoreMap['carta'] ?? 0}",
                                        ),
                                      if (scoreMap['virao'] != 0)
                                        _MiniScoreChip(
                                          label: "Virao",
                                          value: "${scoreMap['virao'] ?? 0}",
                                        ),
                                      _MiniScoreChip(
                                        label: "Total",
                                        value: "${scoreMap['total'] ?? 0}",
                                        highlight: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 12),

                /// CONTROLS
                _SectionCard(
                  title: "Controls",
                  child: Column(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          // await vm.leaveGame();

                          context.go('/landing');
                        },
                        child: _ActionTile(
                          title: "Go to Lobby",
                          subtitle: "Leave this screen and return to the lobby",
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          // await vm.leaveGame();
                          if (context.mounted) {
                            context.go('/landing');
                          }
                        },
                        child: _ActionTile(
                          title: "Leave Game",
                          subtitle: "Abandon this match",
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppStyle.theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyle.theme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyle.theme.body)),
          Text(
            value,
            style: AppStyle.theme.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniScoreChip extends StatelessWidget {
  const _MiniScoreChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppStyle.theme.turnHighlight.withValues(alpha: .12)
            : AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppStyle.theme.turnHighlight.withValues(alpha: .35)
              : AppStyle.theme.muted.withValues(alpha: .18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppStyle.theme.mutedText),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppStyle.theme.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppStyle.theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: danger
              ? AppStyle.theme.danger.withValues(alpha: .25)
              : AppStyle.theme.muted.withValues(alpha: .15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyle.theme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppStyle.theme.mutedText),
        ],
      ),
    );
  }
}
