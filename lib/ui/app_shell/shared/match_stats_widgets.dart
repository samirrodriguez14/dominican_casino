import 'dart:math' as math;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/opponent_match_stats.dart';
import 'package:dominican_casino/models/player_match_stats.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Colors for career W/L / opponent rows on card faces.
class StatsPalette {
  const StatsPalette({
    required this.ink,
    required this.muted,
    required this.foreground,
    required this.panel,
  });

  final Color ink;
  final Color muted;
  final Color foreground;
  final Color panel;

  factory StatsPalette.fromAppTheme(AppTheme theme) => StatsPalette(
    ink: theme.textPrimary,
    muted: theme.muted,
    foreground: theme.success,
    panel: theme.surfaceRaised,
  );

  factory StatsPalette.fromAvatarScore(AvatarScoreTheme score) => StatsPalette(
    ink: score.ink,
    muted: score.muted,
    foreground: score.foreground,
    panel: score.panel,
  );
}

const matchStatsModeOrder = <GameMode>[
  GameMode.casino,
  GameMode.casinoSpeed,
  GameMode.rummy,
  GameMode.tresydos,
  GameMode.bs,
  GameMode.robaito,
];

/// Career donut + win/loss totals + per-mode bars.
///
/// When [collapsed], shows a compact W–L strip so tab lists get more room.
class CareerStatsSummary extends StatelessWidget {
  const CareerStatsSummary({
    super.key,
    required this.stats,
    required this.palette,
    this.collapsed = false,
  });

  final PlayerMatchStats stats;
  final StatsPalette palette;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modesWithGames = [
      for (final mode in matchStatsModeOrder)
        if (stats.modeStats(mode.name).gamesPlayed > 0) mode,
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    final total = stats.wins + stats.losses;
    final rate = total == 0 ? 0 : ((stats.wins / total) * 100).round();

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: collapsed
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.chart_pie_fill,
                    size: 16,
                    color: palette.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.recordShort(stats.wins, stats.losses),
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$rate% ${l10n.winRate}',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: WinLossDonut(
                          wins: stats.wins,
                          losses: stats.losses,
                          palette: palette,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatNumber(
                            label: l10n.wins,
                            value: stats.wins,
                            color: palette.foreground,
                            ink: palette.ink,
                          ),
                          const SizedBox(height: 12),
                          StatNumber(
                            label: l10n.losses,
                            value: stats.losses,
                            color: palette.muted,
                            ink: palette.ink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (modesWithGames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final mode in modesWithGames) ...[
                    ModeBarRow(
                      label: l10n.gameModeName(mode),
                      wins: stats.modeStats(mode.name).wins,
                      losses: stats.modeStats(mode.name).losses,
                      palette: palette,
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
    );
  }
}

class OpponentRecordRow extends StatefulWidget {
  const OpponentRecordRow({
    super.key,
    required this.stats,
    required this.palette,
    this.trailing,
    this.subtitle,
  });

  final OpponentMatchStats stats;
  final StatsPalette palette;
  final Widget? trailing;
  final String? subtitle;

  @override
  State<OpponentRecordRow> createState() => _OpponentRecordRowState();
}

class _OpponentRecordRowState extends State<OpponentRecordRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = widget.stats;
    final palette = widget.palette;
    final look = stats.seatLook;
    final modes = [
      for (final mode in matchStatsModeOrder)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.name ?? 'Rival',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              widget.trailing ??
                  Text(
                    l10n.recordShort(stats.wins, stats.losses),
                    style: TextStyle(
                      color: palette.muted,
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
                  color: palette.muted,
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
              child: ModeBarRow(
                label: l10n.gameModeName(mode),
                wins: stats.modeStats(mode.name).wins,
                losses: stats.modeStats(mode.name).losses,
                palette: palette,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ],
    );
  }
}

class StatNumber extends StatelessWidget {
  const StatNumber({
    super.key,
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

class ModeBarRow extends StatelessWidget {
  const ModeBarRow({
    super.key,
    required this.label,
    required this.wins,
    required this.losses,
    required this.palette,
  });

  final String label;
  final int wins;
  final int losses;
  final StatsPalette palette;

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
                  color: palette.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$wins–$losses',
              style: TextStyle(
                color: palette.muted,
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
                    child: ColoredBox(color: palette.foreground),
                  ),
                if (winFrac < 1)
                  Expanded(
                    flex: ((1 - winFrac) * 1000).round().clamp(1, 1000),
                    child: ColoredBox(
                      color: palette.ink.withValues(alpha: 0.18),
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

class WinLossDonut extends StatelessWidget {
  const WinLossDonut({
    super.key,
    required this.wins,
    required this.losses,
    required this.palette,
  });

  final int wins;
  final int losses;
  final StatsPalette palette;

  @override
  Widget build(BuildContext context) {
    final total = wins + losses;
    final rate = total == 0 ? 0.0 : wins / total;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DonutPainter(
          winFraction: rate,
          winColor: palette.foreground,
          lossColor: palette.ink.withValues(alpha: 0.18),
          trackColor: palette.panel,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(rate * 100).round()}%',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).winRate,
                style: TextStyle(
                  color: palette.muted,
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
