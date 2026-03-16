import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GameHistoryTile extends StatelessWidget {
  const GameHistoryTile({
    super.key,
    required this.opponent,
    required this.mode,
    required this.won,
  });

  final String opponent;
  final GameMode mode;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final statusColor = won
        ? AppStyle.theme.turnHighlight
        : CupertinoColors.systemRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppStyle.theme.raisedSurfaceBox(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppStyle.theme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppStyle.theme.border),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppStyle.theme.muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: AppStyle.theme.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  _modeLabel(mode),
                  style: AppStyle.theme.mutedText.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),

          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              won ? "W" : "L",
              style: AppStyle.theme.title.copyWith(
                fontSize: 15,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(GameMode mode) {
    return mode.name;
  }
}