import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GameHistorySection extends StatelessWidget {
  const GameHistorySection({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final GameMode? selectedMode;
  final ValueChanged<GameMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyle.theme.surfaceBox(),
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Game History",
            style: AppStyle.theme.title.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 6),
          Text("Review your recent matches.", style: AppStyle.theme.mutedText),
          const SizedBox(height: 16),

          _HistoryFilters(
            selectedMode: selectedMode,
            onModeChanged: onModeChanged,
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(6, (index) {
                  final won = index % 2 == 0;
                  final mode = GameMode.values[index % GameMode.values.length];
                  final opponent = "Opponent ${index + 1}";

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == 7 ? 0 : 10),
                    child: GameHistoryTile(
                      opponent: opponent,
                      mode: mode,
                      won: won,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final GameMode? selectedMode;
  final ValueChanged<GameMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: "All",
          selected: selectedMode == null,
          onTap: () => onModeChanged(null),
        ),
        ...GameMode.values.map((mode) {
          return _FilterChip(
            label: _modeLabel(mode),
            selected: selectedMode == mode,
            onTap: () => onModeChanged(mode),
          );
        }),
        // _FutureFilterChip(
        //   label: "Opponent",
        //   icon: CupertinoIcons.person_2_fill,
        // ),
      ],
    );
  }

  String _modeLabel(GameMode mode) {
    return mode.name;
  }
}

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
      //  BoxDecoration(
      //   color: AppStyle.theme.surface,
      //   borderRadius: BorderRadius.circular(AppStyle.theme.radius),
      //   border: Border.all(color: AppStyle.theme.border),
      // ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppStyle.theme.turnHighlight.withValues(alpha: 0.16)
              : AppStyle.theme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppStyle.theme.turnHighlight
                : AppStyle.theme.border,
          ),
        ),
        child: Text(
          label,
          style: AppStyle.theme.body.copyWith(
            color: selected
                ? AppStyle.theme.turnHighlight
                : AppStyle.theme.textPrimary,
          ),
        ),
      ),
    );
  }
}

// class _FutureFilterChip extends StatelessWidget {
//   const _FutureFilterChip({required this.label, required this.icon});

//   final String label;
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppStyle.theme.surface,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: AppStyle.theme.border),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: AppStyle.theme.muted),
//           const SizedBox(width: 6),
//           Text(label, style: AppStyle.theme.mutedText),
//         ],
//       ),
//     );
//   }
// }
