import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:dominican_casino/ui/settings/legal_links.dart';
import 'package:dominican_casino/ui/settings/settings_controls.dart';
import 'package:flutter/cupertino.dart';

/// Slate face for the home Settings pane (language, sound, haptics).
class HomeSettingsCard extends StatelessWidget {
  const HomeSettingsCard({super.key});

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
              CupertinoIcons.gear_alt_fill,
              size: 18,
              color: theme.textPrimary.withValues(alpha: .78),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: HomeCardEyebrow(l10n.settings.toUpperCase())),
                const SizedBox(height: 10),
                Text(
                  l10n.settings,
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
                    child: AppPreferencesSection(),
                  ),
                ),
                Center(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    onPressed: SoundService.wrapTap(
                      () => openPrivacyPolicy(context),
                    ),
                    child: Text(
                      l10n.privacyPolicy,
                      style: theme.mutedText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.muted.withValues(alpha: .45),
                      ),
                    ),
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
