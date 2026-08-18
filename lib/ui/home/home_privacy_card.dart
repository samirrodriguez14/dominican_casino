import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/home/privacy_policy_copy.dart';
import 'package:flutter/cupertino.dart';

/// Slate face for the home Privacy pane.
class HomePrivacyCard extends StatelessWidget {
  const HomePrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);

    return HomeCardFace(
      color: theme.pickerFaceAlt,
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 14,
            child: Icon(
              CupertinoIcons.lock_fill,
              size: 18,
              color: theme.textPrimary.withValues(alpha: .78),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: HomeCardEyebrow(l10n.privacy.toUpperCase())),
                const SizedBox(height: 10),
                Text(
                  l10n.privacyPolicy,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                const Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: PrivacyPolicyCopy(compact: true),
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
