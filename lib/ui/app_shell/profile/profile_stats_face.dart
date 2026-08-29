import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/opponent_match_stats.dart';
import 'package:dominican_casino/models/player_match_stats.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/view_models/profile_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Back face of the profile identity card: career W/L chart + mode breakdown
/// + paginated head-to-head records.
class ProfileStatsFace extends StatefulWidget {
  const ProfileStatsFace({
    super.key,
    required this.stats,
    required this.score,
    required this.onFlipBack,
  });

  final PlayerMatchStats stats;
  final AvatarScoreTheme score;
  final VoidCallback onFlipBack;

  static const _modeOrder = <GameMode>[
    GameMode.casino,
    GameMode.casinoSpeed,
    GameMode.rummy,
    GameMode.tresydos,
    GameMode.bs,
    GameMode.robaito,
  ];

  @override
  State<ProfileStatsFace> createState() => _ProfileStatsFaceState();
}

class _ProfileStatsFaceState extends State<ProfileStatsFace> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileViewModel>().ensureOpponentStatsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileVm = context.watch<ProfileViewModel>();
    final score = widget.score;
    final stats = widget.stats;
    final modesWithGames = [
      for (final mode in ProfileStatsFace._modeOrder)
        if (stats.modeStats(mode.name).gamesPlayed > 0) mode,
    ];
    final opponents = profileVm.opponentStats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stats,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: score.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              if (stats.isEmpty && opponents.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.statsEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: score.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 52),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (!stats.isEmpty) ...[
                        SizedBox(
                          height: 120,
                          child: Row(
                            children: [
                              Expanded(
                                child: _WinLossDonut(
                                  wins: stats.wins,
                                  losses: stats.losses,
                                  score: score,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _StatNumber(
                                    label: l10n.wins,
                                    value: stats.wins,
                                    color: score.foreground,
                                    ink: score.ink,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatNumber(
                                    label: l10n.losses,
                                    value: stats.losses,
                                    color: score.muted,
                                    ink: score.ink,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (modesWithGames.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          for (final mode in modesWithGames) ...[
                            _ModeBarRow(
                              label: l10n.gameModeName(mode),
                              wins: stats.modeStats(mode.name).wins,
                              losses: stats.modeStats(mode.name).losses,
                              score: score,
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ],
                      const SizedBox(height: 8),
                      Text(
                        l10n.vsPlayers,
                        style: TextStyle(
                          color: score.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (opponents.isEmpty && !profileVm.opponentStatsLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.vsPlayersEmpty,
                            style: TextStyle(
                              color: score.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        for (final row in opponents) ...[
                          _OpponentRecordRow(stats: row, score: score),
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
                              color: score.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _FlipBackButton(
              score: score,
              onPressed: widget.onFlipBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentRecordRow extends StatefulWidget {
  const _OpponentRecordRow({
    required this.stats,
    required this.score,
  });

  final OpponentMatchStats stats;
  final AvatarScoreTheme score;

  @override
  State<_OpponentRecordRow> createState() => _OpponentRecordRowState();
}

class _OpponentRecordRowState extends State<_OpponentRecordRow> {
  bool _expanded = false;

  static const _modeOrder = ProfileStatsFace._modeOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = widget.stats;
    final score = widget.score;
    final look = stats.seatLook;
    final modes = [
      for (final mode in _modeOrder)
        if (stats.modeStats(mode.name).gamesPlayed > 0) mode,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: modes.isEmpty
              ? null
              : SoundService.wrapTap(() {
                  setState(() => _expanded = !_expanded);
                }),
          child: Row(
            children: [
              PlayerAvatarView(
                avatarId: look.avatarId,
                avatarAsset: look.avatarAsset,
                size: 32,
                showBorder: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.name ?? 'Rival',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: score.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.recordShort(stats.wins, stats.losses),
                style: TextStyle(
                  color: score.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (modes.isNotEmpty) ...[
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 12,
                  color: score.muted,
                ),
              ],
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          for (final mode in modes) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _ModeBarRow(
                label: l10n.gameModeName(mode),
                wins: stats.modeStats(mode.name).wins,
                losses: stats.modeStats(mode.name).losses,
                score: score,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ],
    );
  }
}

class _StatNumber extends StatelessWidget {
  const _StatNumber({
    required this.label,
    required this.value,
    required this.color,
    required this.ink,
  });

  final String label;
  final int value;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: ink.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeBarRow extends StatelessWidget {
  const _ModeBarRow({
    required this.label,
    required this.wins,
    required this.losses,
    required this.score,
  });

  final String label;
  final int wins;
  final int losses;
  final AvatarScoreTheme score;

  @override
  Widget build(BuildContext context) {
    final total = wins + losses;
    final winFrac = total == 0 ? 0.0 : wins / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: score.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$wins–$losses',
              style: TextStyle(
                color: score.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                if (winFrac > 0)
                  Expanded(
                    flex: (winFrac * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: score.foreground),
                  ),
                if (winFrac < 1)
                  Expanded(
                    flex: ((1 - winFrac) * 1000).round().clamp(1, 1000),
                    child: ColoredBox(
                      color: score.ink.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WinLossDonut extends StatelessWidget {
  const _WinLossDonut({
    required this.wins,
    required this.losses,
    required this.score,
  });

  final int wins;
  final int losses;
  final AvatarScoreTheme score;

  @override
  Widget build(BuildContext context) {
    final total = wins + losses;
    final rate = total == 0 ? 0.0 : wins / total;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DonutPainter(
          winFraction: rate,
          winColor: score.foreground,
          lossColor: score.ink.withValues(alpha: 0.18),
          trackColor: score.panel,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(rate * 100).round()}%',
                style: TextStyle(
                  color: score.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).winRate,
                style: TextStyle(
                  color: score.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.winFraction,
    required this.winColor,
    required this.lossColor,
    required this.trackColor,
  });

  final double winFraction;
  final Color winColor;
  final Color lossColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.28;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    final bg = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    if (winFraction <= 0) {
      final loss = Paint()
        ..color = lossColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, loss);
      return;
    }

    final start = -math.pi / 2;
    if (winFraction < 1) {
      final loss = Paint()
        ..color = lossColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(
        rect,
        start + winFraction * math.pi * 2,
        (1 - winFraction) * math.pi * 2,
        false,
        loss,
      );
    }
    if (winFraction > 0) {
      final win = Paint()
        ..color = winColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        start,
        winFraction * math.pi * 2,
        false,
        win,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.winFraction != winFraction ||
        oldDelegate.winColor != winColor ||
        oldDelegate.lossColor != lossColor;
  }
}

class _FlipBackButton extends StatelessWidget {
  const _FlipBackButton({required this.score, required this.onPressed});

  final AvatarScoreTheme score;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: score.panel,
          shape: BoxShape.circle,
          border: Border.all(color: score.ink.withValues(alpha: 0.18)),
        ),
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.arrow_left_right_circle_fill,
          size: 22,
          color: score.ink,
          semanticLabel: l10n.stats,
        ),
      ),
    );
  }
}
