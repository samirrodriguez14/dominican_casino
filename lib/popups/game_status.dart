import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameStatusContent extends StatelessWidget {
  const GameStatusContent({super.key, required this.vm});

  final RoomViewModel vm;

  String _prettyPlayer(String? id) {
    final me = vm.playerId;
    final opp = vm.opponentId;

    if (id == null || id.isEmpty) return "-";
    if (me != null && id == me) return "You";
    if (opp != null && id == opp) return "Opponent";
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final g = vm.currentGame;
    final me = vm.playerId;
    final opp = vm.opponentId;

    // same rule you already use
    final Map<String, dynamic>? totalScore = g?.scores;

    final yourScore = totalScore?[me] ?? 0;
    final oppScore = totalScore?[opp] ?? 0;
    final roundIndex = vm.roundStatus == RoundStatus.completed
        ? vm.roundIndex + 1
        : vm.roundIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Small info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoLine("Turn", _prettyPlayer(g?.currentTurnPlayerId)),
              const SizedBox(height: 6),
              _infoLine("Dealer", _prettyPlayer(g?.controllerId)),
              const SizedBox(height: 6),
              _infoLine("Round", "${roundIndex}"),
              const SizedBox(height: 10),
              _infoLine("Your Score", "$yourScore"),
              const SizedBox(height: 6),
              _infoLine("Opponent Score", "$oppScore"),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        Text(
          v,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
