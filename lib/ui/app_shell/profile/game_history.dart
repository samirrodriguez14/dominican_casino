import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GameHistorySheet extends StatelessWidget {
  const GameHistorySheet({
    super.key,
    required this.scrollController,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final ScrollController scrollController;
  final GameMode? selectedMode;
  final ValueChanged<GameMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
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
          Text("Game History", style: AppStyle.theme.mutedText),
          const SizedBox(height: 8),

          Expanded(
            child: GameHistorySection(
              scrollController: scrollController,
              selectedMode: selectedMode,
              onModeChanged: onModeChanged,
            ),
          ),
        ],
      ),
    );
  }
}
class GameHistorySection extends StatelessWidget {
  const GameHistorySection({
    super.key,
    required this.scrollController,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final ScrollController scrollController;
  final GameMode? selectedMode;
  final ValueChanged<GameMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final games = List.generate(6, (index) {
      final won = index % 2 == 0;
      final mode = GameMode.values[index % GameMode.values.length];
      final opponent = "Opponent ${index + 1}";
      return (won: won, mode: mode, opponent: opponent);
    });

    final filteredGames = selectedMode == null
        ? games
        : games.where((g) => g.mode == selectedMode).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.theme.surfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review your recent matches.",
            style: AppStyle.theme.mutedText,
          ),
          const SizedBox(height: 16),

          _HistoryFilters(
            selectedMode: selectedMode,
            onModeChanged: onModeChanged,
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filteredGames.length,
              itemBuilder: (context, index) {
                final game = filteredGames[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredGames.length - 1 ? 0 : 10,
                  ),
                  child: GameHistoryTile(
                    opponent: game.opponent,
                    mode: game.mode,
                    won: game.won,
                  ),
                );
              },
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