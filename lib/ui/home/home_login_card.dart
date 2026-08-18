import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Login face: welcome, logo, and a pulsing quick-play cue.
class HomeLoginCard extends StatelessWidget {
  const HomeLoginCard({
    super.key,
    required this.onQuickPlay,
    this.busy = false,
  });

  final VoidCallback onQuickPlay;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return HomeCardFace(
      color: theme.pickerFace,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          children: [
            HomeCardEyebrow(l10n.welcome),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Image.asset(
                  theme.appLogoMark,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            _QuickPlayCue(busy: busy, onPressed: onQuickPlay),
          ],
        ),
      ),
    );
  }
}

class _QuickPlayCue extends StatefulWidget {
  const _QuickPlayCue({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  State<_QuickPlayCue> createState() => _QuickPlayCueState();
}

class _QuickPlayCueState extends State<_QuickPlayCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final cream = theme.textPrimary;

    return Semantics(
      button: true,
      label: l10n.clickToPlayQuickMatch,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(widget.busy ? null : widget.onPressed),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final opacity = 0.38 + 0.62 * _pulse.value;
            return Opacity(opacity: opacity, child: child);
          },
          child: Column(
            children: [
              Icon(CupertinoIcons.play_fill, size: 34, color: cream),
              const SizedBox(height: 6),
              Text(
                l10n.clickToPlayQuickMatch,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.caption.copyWith(
                  color: cream.withValues(alpha: .92),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeAuthPill extends StatelessWidget {
  const HomeAuthPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final cream = theme.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: SoundService.wrapTap(onPressed),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: cream.withValues(alpha: .12),
            border: Border.all(color: cream.withValues(alpha: .22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: cream),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.title.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
