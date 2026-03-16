import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/legacy_game/game_view_model.dart';
import 'package:flutter/cupertino.dart';

class RoundCompletedContent extends StatelessWidget {
  const RoundCompletedContent({super.key, required this.vm});

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
    final int roundIndex = vm.roundIndex;

    final String player1Id = '';
    final String player2Id = '';

    final Map<String, dynamic> roundScores =
        (vm.roundScores as Map?)?.cast<String, dynamic>() ?? const {};

    final String player1Label = _prettyPlayer(player1Id);
    final String player2Label = _prettyPlayer(player2Id);

    final p1Total = _totalFor(roundScores, player1Id);
    final p2Total = _totalFor(roundScores, player2Id);

    final p1 = _detailsFor(roundScores, player1Id);
    final p2 = _detailsFor(roundScores, player2Id);

    Widget scoreRow(String label, int total) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      );
    }

    Widget chips(Map<String, dynamic> m) {
      final entries = m.entries
          .where(
            (e) =>
                e.key != 'total' && (e.value is num) && (e.value as num) != 0,
          )
          .toList();

      if (entries.isEmpty) {
        return Text(
          'No bonuses this round.',
          style: TextStyle(fontSize: 12, color: AppStyle.theme.textPrimary),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyle.theme.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${e.key}: ${e.value}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      );
    }

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
              Text(
                'Round $roundIndex results',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.theme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              scoreRow(player1Label, p1Total),
              const SizedBox(height: 6),
              chips(p1),
              const SizedBox(height: 12),
              scoreRow(player2Label, p2Total),
              const SizedBox(height: 6),
              chips(p2),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Tap Continue when you're ready. The controller will start the next round after both players are ready.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppStyle.theme.muted),
        ),
      ],
    );
  }
}
