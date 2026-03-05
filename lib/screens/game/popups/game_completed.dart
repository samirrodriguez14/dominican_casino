import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';

class GameCompletedContent extends StatelessWidget {
  const GameCompletedContent({
    super.key,
    required this.vm,
    this.youLabel = 'You',
    this.opponentLabel = 'Opponent',
    this.winnerLabelOverride,
  });

  final RoomViewModel vm;

  /// Display labels
  final String youLabel;
  final String opponentLabel;

  /// Optional override (ex: "You" / "Opponent" / custom text)
  final String? winnerLabelOverride;

  int _scoreFor(Map<String, dynamic>? scores, String? pid) {
    if (scores == null || pid == null) return 0;
    final v = scores[pid];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String _winnerLabel({
    required String? winnerId,
    required String? me,
    required String? opp,
  }) {
    if (winnerLabelOverride != null) return winnerLabelOverride!;
    if (winnerId == null) return 'Winner';
    if (winnerId == me) return youLabel;
    if (winnerId == opp) return opponentLabel;
    return 'Winner';
  }

  Widget _scoreRow(String label, int total, {bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: AppStyle.theme.textPrimary,
            ),
          ),
        ),
        Text(
          '$total',
          style: TextStyle(
            fontSize: 18,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w800,
            color: AppStyle.theme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = vm.g;
    if (g == null) return const SizedBox.shrink();

    final me = vm.me;
    final opp = vm.opp;

    final scores = g.scores; // Map<String, dynamic>?
    final winnerId = g.winnerId; // String?

    final myTotal = _scoreFor(scores, me);
    final oppTotal = _scoreFor(scores, opp);

    final winnerLabel = _winnerLabel(winnerId: winnerId, me: me, opp: opp);
    final meIsWinner = winnerId != null && winnerId == me;
    final oppIsWinner = winnerId != null && winnerId == opp;

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
                'Game Over',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppStyle.theme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Winner: $winnerLabel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.theme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _scoreRow(youLabel, myTotal, highlight: meIsWinner),
              const SizedBox(height: 12),

              _scoreRow(opponentLabel, oppTotal, highlight: oppIsWinner),
            ],
          ),
        ),
        const SizedBox(height: 10),
         Text(
          'You can leave the room or start a new game.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppStyle.theme.muted),
        ),
      ],
    );
  }
}