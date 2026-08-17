import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/sage_theme.dart';
import 'package:dominican_casino/ui/home/privacy_policy_copy.dart';
import 'package:flutter/cupertino.dart';

/// Carousel-style face for the home Privacy pane.
class HomePrivacyCard extends StatelessWidget {
  const HomePrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final face = theme is SageTheme
        ? theme.pickerFace
        : const Color(0xFF3A634F);

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.privacyPolicy,
                style: theme.title.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: PrivacyPolicyCopy(compact: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
