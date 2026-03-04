import 'package:dominican_casino/style/theme_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

class LobbyGamePill extends StatelessWidget {
  const LobbyGamePill({
    super.key,
    required this.gameId,
    required this.player1Id,
    required this.player2Id,
    required this.onEnter,
    required this.onDelete,
  });

  final String gameId;
  final String? player1Id;
  final String? player2Id;
  final VoidCallback onEnter;
  final VoidCallback onDelete;

  bool get hasOpenSlot {
    final p1 = (player1Id ?? "").trim();
    final p2 = (player2Id ?? "").trim();
    return p1.isEmpty || p2.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              gameId,
              style: AppStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Door (enter) only if there is room (p1 or p2 missing)
          // if (hasOpenSlot)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minSize: 0,
              onPressed: onEnter,
              child: const Icon(
                Icons.login,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          // else
            // tiny placeholder spacing so pills align nicely
            const SizedBox(width: 34),

          // Delete (x) always available
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            onPressed: onDelete,
            child: Icon(
              Icons.close,
              size: 18,
              color: AppColors.muted.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
