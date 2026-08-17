import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/home/privacy_policy_copy.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// In-app privacy policy (also linked from Settings). Host a copy on the web for App Store Connect.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      backgroundColor: AppStyle.theme.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.privacyPolicy),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: SoundService.wrapTap(() => context.pop()),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.appTitle,
              style: AppStyle.theme.title.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            const PrivacyPolicyCopy(),
          ],
        ),
      ),
    );
  }
}
