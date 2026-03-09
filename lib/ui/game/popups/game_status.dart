import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameStatusContent extends StatelessWidget {
  const GameStatusContent({super.key, required this.vm});

  final GameViewModel vm;

  String _prettyPlayer(String? id) {
    final me = vm.me;
    final opp = vm.opp;

    if (id == null || id.isEmpty) return "-";
    if (id == me) return "You";
    if (opp != null && id == opp) return "Opponent";
    return id;
  }

  int _totalFor(Map<String, dynamic> roundScores, String pid) {
    final m = (roundScores[pid] as Map?) ?? const {};
    final total = m['total'];
    if (total is int) return total;
    if (total is num) return total.toInt();
    return 0;
  }

  Map<String, dynamic> _detailsFor(
    Map<String, dynamic> roundScores,
    String pid,
  ) {
    final m = (roundScores[pid] as Map?) ?? const {};
    return Map<String, dynamic>.from(m);
  }

  @override
  Widget build(BuildContext context) {
    final g = vm.g;
    final me = vm.me;
    final opp = vm.opp;

    final Map<String, dynamic>? totalScore = g?.scores;
    final yourScore = totalScore?[me] ?? 0;
    final oppScore = totalScore?[opp] ?? 0;

    final roundIndex = vm.roundStatus == RoundStatus.completed
        ? vm.roundIndex + 1
        : vm.roundIndex;

    final String player1Id = g?.player1 ?? '';
    final String player2Id = g?.player2 ?? '';

    final Map<String, dynamic> roundScores =
        (vm.roundScores as Map?)?.cast<String, dynamic>() ?? const {};

    final bool hasLastRoundData =
        roundScores.isNotEmpty &&
        (player1Id.isNotEmpty || player2Id.isNotEmpty);

    final String player1Label = _prettyPlayer(player1Id);
    final String player2Label = _prettyPlayer(player2Id);

    final int p1Total = _totalFor(roundScores, player1Id);
    final int p2Total = _totalFor(roundScores, player2Id);

    final Map<String, dynamic> p1 = _detailsFor(roundScores, player1Id);
    final Map<String, dynamic> p2 = _detailsFor(roundScores, player2Id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppStyle.theme.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoLine("Turn", _prettyPlayer(g?.currentTurnPlayerId)),
              const SizedBox(height: 6),
              _infoLine("Dealer", _prettyPlayer(g?.controllerId)),
              const SizedBox(height: 6),
              _infoLine("Round", "$roundIndex"),
              const SizedBox(height: 10),
              _infoLine("Your Score", "$yourScore"),
              const SizedBox(height: 6),
              _infoLine("Opponent Score", "$oppScore"),

              if (hasLastRoundData) ...[
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: AppStyle.theme.border.withValues(alpha: .35),
                ),
                const SizedBox(height: 12),
                Text(
                  "Last Round",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppStyle.theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _scoreRow(player1Label, p1Total),
                const SizedBox(height: 6),
                _chips(p1),
                const SizedBox(height: 12),
                _scoreRow(player2Label, p2Total),
                const SizedBox(height: 6),
                _chips(p2),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppStyle.theme.muted,
            ),
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppStyle.theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _scoreRow(String label, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppStyle.theme.textPrimary,
            ),
          ),
        ),
        Text(
          '$total',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppStyle.theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _chips(Map<String, dynamic> m) {
    final entries = m.entries
        .where(
          (e) =>
              e.key != 'total' && (e.value is num) && (e.value as num) != 0,
        )
        .toList();

    if (entries.isEmpty) {
      return Text(
        'No bonuses.',
        style: TextStyle(
          fontSize: 12,
          color: AppStyle.theme.muted,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppStyle.theme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppStyle.theme.border.withValues(alpha: .35),
            ),
          ),
          child: Text(
            '${e.key}: ${e.value}',
            style: TextStyle(
              fontSize: 12,
              color: AppStyle.theme.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}