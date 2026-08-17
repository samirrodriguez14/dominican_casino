import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Readable +N / −N chip over felt or other busy backgrounds.
class CurrencyDeltaLabel extends StatelessWidget {
  const CurrencyDeltaLabel({
    super.key,
    required this.delta,
    this.fontSize = 12,
  });

  final int delta;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) return const SizedBox.shrink();
    final theme = AppStyle.theme;
    final gained = delta > 0;
    final label = gained ? '+$delta' : '$delta';
    final accent = gained ? theme.warning : theme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xF216120F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .9)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.title.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          height: 1,
        ),
      ),
    );
  }
}
