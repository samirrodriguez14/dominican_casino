import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Compact coins + energy chips for the top-right of shell screens.
class CurrencyBar extends StatelessWidget {
  const CurrencyBar({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<AppRepo>().wallet;
    final theme = AppStyle.theme;
    final padH = compact ? 10.0 : 14.0;
    final padV = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 20.0;
    final fontSize = compact ? 13.0 : 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          icon: CupertinoIcons.bolt_fill,
          value: wallet.energy,
          color: theme.warning,
          padH: padH,
          padV: padV,
          iconSize: iconSize,
          fontSize: fontSize,
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: CupertinoIcons.circle_grid_3x3_fill,
          value: wallet.coins,
          color: theme.turnHighlight,
          padH: padH,
          padV: padV,
          iconSize: iconSize,
          fontSize: fontSize,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.value,
    required this.color,
    required this.padH,
    required this.padV,
    required this.iconSize,
    required this.fontSize,
  });

  final IconData icon;
  final int value;
  final Color color;
  final double padH;
  final double padV;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.border.withValues(alpha: .6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: theme.title.copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
