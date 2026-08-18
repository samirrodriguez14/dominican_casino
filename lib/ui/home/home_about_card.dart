import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// One-page pitch: headline on top, three open lines underneath.
class HomeAboutCard extends StatelessWidget {
  const HomeAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return HomeCardFace(
      color: theme.pickerFaceEdge,
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 14,
            child: Text(
              '♦',
              style: TextStyle(
                color: theme.suitRed,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              children: [
                HomeCardEyebrow(l10n.theApp),
                const SizedBox(height: 12),
                Text(
                  l10n.aboutHeadline,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FeatureLine(
                        icon: CupertinoIcons.rectangle_stack_fill,
                        label: l10n.aboutFeatureGames,
                      ),
                      _FeatureLine(
                        icon: CupertinoIcons.square_stack_3d_up_fill,
                        label: l10n.aboutFeatureClassics,
                      ),
                      _FeatureLine(
                        icon: CupertinoIcons.person_2_fill,
                        label: l10n.aboutFeaturePlay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final cream = theme.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: cream.withValues(alpha: .92)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.body.copyWith(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: cream.withValues(alpha: .94),
            ),
          ),
        ),
      ],
    );
  }
}
