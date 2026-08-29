import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/player_match_stats.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/current_games_list.dart';
import 'package:dominican_casino/ui/app_shell/shared/match_stats_widgets.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum _StatsTab { vsPlayers, history }

/// Back face of the Current Games card: career W/L + Vs players | History tabs.
class CurrentGamesStatsFace extends StatefulWidget {
  const CurrentGamesStatsFace({
    super.key,
    required this.theme,
    required this.stats,
    required this.onBeforeEnterHistoryGame,
  });

  final AppTheme theme;
  final PlayerMatchStats stats;
  final VoidCallback onBeforeEnterHistoryGame;

  @override
  State<CurrentGamesStatsFace> createState() => _CurrentGamesStatsFaceState();
}

class _CurrentGamesStatsFaceState extends State<CurrentGamesStatsFace> {
  static const _collapseAfter = 28.0;
  static const _expandBefore = 8.0;

  _StatsTab _tab = _StatsTab.vsPlayers;
  bool _summaryCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileViewModel>().ensureOpponentStatsLoaded();
    });
  }

  bool _onTabScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    final metrics = notification.metrics;
    if (!metrics.hasPixels || !metrics.hasContentDimensions) return false;
    // Nested horizontal noise — only vertical list scroll collapses.
    if (metrics.axis != Axis.vertical) return false;

    final pixels = metrics.pixels;
    if (!_summaryCollapsed && pixels > _collapseAfter) {
      setState(() => _summaryCollapsed = true);
    } else if (_summaryCollapsed && pixels <= _expandBefore) {
      setState(() => _summaryCollapsed = false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = StatsPalette.fromAppTheme(widget.theme);
    final profileVm = context.watch<ProfileViewModel>();
    final stats = widget.stats;
    final opponents = profileVm.opponentStats;
    final empty = stats.isEmpty && opponents.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!stats.isEmpty) ...[
          CareerStatsSummary(
            stats: stats,
            palette: palette,
            collapsed: _summaryCollapsed,
          ),
          const SizedBox(height: 8),
        ],
        _StatsSegmentedControl(
          theme: widget.theme,
          tab: _tab,
          onChanged: (tab) {
            setState(() {
              _tab = tab;
              _summaryCollapsed = false;
            });
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onTabScroll,
            child: switch (_tab) {
              _StatsTab.vsPlayers => empty && stats.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          opponents.isEmpty && stats.isEmpty
                              ? l10n.statsEmpty
                              : l10n.vsPlayersEmpty,
                          textAlign: TextAlign.center,
                          style: widget.theme.mutedText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (opponents.isEmpty &&
                            !profileVm.opponentStatsLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.vsPlayersEmpty,
                              style: widget.theme.mutedText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          for (final row in opponents) ...[
                            OpponentRecordRow(stats: row, palette: palette),
                            const SizedBox(height: 8),
                          ],
                        if (profileVm.opponentStatsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CupertinoActivityIndicator()),
                          )
                        else if (profileVm.opponentStatsHasMore &&
                            opponents.isNotEmpty)
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            onPressed: SoundService.wrapTap(
                              profileVm.loadMoreOpponentStats,
                            ),
                            child: Text(
                              l10n.loadMore,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
              _StatsTab.history => CurrentGamesList(
                  history: true,
                  onBeforeEnter: widget.onBeforeEnterHistoryGame,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  embeddedInCard: true,
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _StatsSegmentedControl extends StatelessWidget {
  const _StatsSegmentedControl({
    required this.theme,
    required this.tab,
    required this.onChanged,
  });

  final AppTheme theme;
  final _StatsTab tab;
  final ValueChanged<_StatsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CupertinoSlidingSegmentedControl<_StatsTab>(
      groupValue: tab,
      backgroundColor: theme.surface.withValues(alpha: 0.55),
      thumbColor: theme.surfaceRaised,
      children: {
        _StatsTab.vsPlayers: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            l10n.vsPlayers,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StatsTab.history: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            l10n.gameHistory,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      },
      onValueChanged: (value) {
        if (value == null) return;
        SoundService.instance.playLayered(GameSound.softCard);
        onChanged(value);
      },
    );
  }
}
