import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
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
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.appTitle, style: AppStyle.theme.title.copyWith(fontSize: 22)),
            const SizedBox(height: 12),
            Text(l10n.noRealMoney, style: AppStyle.theme.body),
            const SizedBox(height: 16),
            Text(
              'We collect a Firebase Authentication identifier (anonymous), '
              'your display name, game match data you create or join, and — '
              'only if you allow notifications — a push token stored under '
              'your user profile (not on shared game documents).',
              style: AppStyle.theme.body,
            ),
            const SizedBox(height: 12),
            Text(
              'Data is processed with Firebase (Google) for realtime play and '
              'turn alerts. We do not sell personal data. You can clear local '
              'profile data from Settings.',
              style: AppStyle.theme.body,
            ),
            const SizedBox(height: 12),
            Text(
              'Contact: support@dominican-casino.web.app',
              style: AppStyle.theme.body,
            ),
            const SizedBox(height: 24),
            Text(
              'Public URL for App Store Connect: '
              'https://dominican-casino.web.app/privacy',
              style: AppStyle.theme.body.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
